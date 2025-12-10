defmodule ElixirPlanningPokerWeb.RoomLive do
  use ElixirPlanningPokerWeb, :live_view
  import ElixirPlanningPokerWeb.ModalComponent
  import ElixirPlanningPokerWeb.CoreComponents
  alias ElixirPlanningPoker.{RoomManager, User, NewStory}

  @close_modal_ask_name "close_modal_ask_name"
  @close_room_config "close_room_config"
  @submit_room_config "submit_room_config"
  @validate_room_config "validate_room_config"
  @close_confirm_reveal_votes "close_confirm_reveal_votes"

  @impl true
  def mount(%{"room_code" => room_code}, session, socket) do
    with {:ok, state} <- RoomManager.get_state(room_code),
         {:ok, socket} <- subscribe_room_pubsub(socket, room_code) do
      socket
      |> assign_base_assigns(state, room_code, session["user_token"])
      |> assign_user_and_modal(session["user_token"])
      |> assign_forms(state)
      |> then(&{:ok, &1})
    else
      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Room not found.")
         |> push_navigate(to: "/")}

      {:error, {:subscribe_failed, reason}} ->
        {:ok,
         socket
         |> put_flash(:error, "Error subscribing: #{inspect(reason)}")
         |> push_navigate(to: "/")}
    end
  end

  # --- helpers ---

  defp subscribe_room_pubsub(socket, room_code) do
    if connected?(socket) do
      case Phoenix.PubSub.subscribe(ElixirPlanningPoker.PubSub, "room:#{room_code}") do
        :ok -> {:ok, socket}
        {:error, reason} -> {:error, {:subscribe_failed, reason}}
      end
    else
      {:ok, socket}
    end
  end

  defp assign_forms(socket, state) do
    socket
    |> assign_form_ask_name(state)
    |> assign_room_config_form(state)
    |> assign_new_story_form()
  end

  defp assign_form_ask_name(socket, state) do
    user =
      case User.find_user(state.users, socket.assigns.user_token) do
        {:ok, user} -> user
        {:error, :not_found} -> User.new(socket.assigns.user_token)
      end

    changeset = User.changeset(user, %{})

    socket
    |> assign(:modal_ask_name_form, to_form(changeset, as: :user))
  end

  defp assign_new_story_form(socket) do
    changeset = NewStory.changeset(%NewStory{}, %{})

    socket
    |> assign(:new_story_form, to_form(changeset, as: :story))
  end

  defp assign_room_config_form(socket, state) do
    socket
    |> assign(:form_room_config, %{
      name: state.name,
      deck_type: state.deck_type,
      custom_deck: state.custom_deck || ""
    })
  end

  defp assign_base_assigns(socket, state, room_code, user_token) do
    socket
    |> assign(:current_url, Phoenix.LiveView.get_connect_params(socket))
    |> assign(:room, state)
    |> assign(:room_code, room_code)
    |> assign(:user_token, user_token)
    |> assign(:modal_ask_name, false)
    |> assign(:close_modal_ask_name, @close_modal_ask_name)
    |> assign(:close_room_config, @close_room_config)
    |> assign(:submit_room_config, @submit_room_config)
    |> assign(:validate_room_config, @validate_room_config)
    |> assign(:close_confirm_reveal_votes, @close_confirm_reveal_votes)
    |> assign(:modal_confirm_reveal_votes, false)
    |> assign(:pending_reveal_user, [])
    |> assign(:show_room_config_modal, false)
    |> assign(:selected_card, nil)
    |> assign(:new_user, false)
    |> assign(:mobile_sidebar_open, false)
  end

  defp assign_user_and_modal(socket, user_token) do
    users = socket.assigns.room.users

    case User.find_user(users, user_token) do
      {:ok, user} ->
        modal_needed = is_nil(user.name) or String.trim(user.name) == ""

        assign(socket,
          modal_ask_name: modal_needed,
          new_user: false
        )

      {:error, :not_found} ->
        assign(socket,
          modal_ask_name: true,
          new_user: true
        )
    end
  end

  # --- modal event handlers ---

  @impl true
  def handle_event(@close_modal_ask_name, _params, socket) do
    {:noreply, assign(socket, :modal_ask_name, false)}
  end

  @impl true
  def handle_event(@validate_room_config, %{"room" => params}, socket) do
    data = socket.assigns[:room_config_data] || socket.assigns.form_room_config.source.data

    changeset =
      ElixirPlanningPoker.RoomConfig.changeset(data, params)
      |> Map.put(:action, :validate)

    updated_data = Ecto.Changeset.apply_changes(changeset)

    form = to_form(changeset, as: :room)

    {:noreply,
     socket
     |> assign(:form_room_config, form)
     |> assign(:room_config_data, updated_data)}
  end

  @impl true
  def handle_event(@submit_room_config, _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event(@close_room_config, _params, socket) do
    {:noreply, assign(socket, :show_room_config_modal, false)}
  end

  @impl true
  def handle_event(@close_confirm_reveal_votes, _params, socket) do
    {:noreply, assign(socket, :modal_confirm_reveal_votes, false)}
  end

  @impl true
  def handle_event("open-room-config", __params, socket) do
    {:noreply, assign(socket, :show_room_config_modal, true)}
  end

  def handle_event("submit_name", %{"user" => params}, socket) do
    room_code = socket.assigns.room_code
    user_token = socket.assigns.user_token

    user_lookup = User.find_user(socket.assigns.room.users, user_token)

    base_user =
      case user_lookup do
        {:ok, user} ->
          user

        {:error, :not_found} ->
          User.new(user_token)
      end

    changeset = User.changeset(base_user, params)

    if changeset.valid? do
      %User{name: name, icon: icon} = Ecto.Changeset.apply_changes(changeset)

      case user_lookup do
        {:ok, _existing_user} ->
          RoomManager.update_user(
            room_code,
            user_token,
            %{name: name, icon: icon}
          )

        {:error, :not_found} ->
          new_user =
            user_token
            |> User.new(name)
            |> Map.put(:icon, icon)

          RoomManager.add_user(room_code, new_user)
      end

      socket =
        socket
        |> assign(:modal_ask_name, false)
        |> assign(:modal_ask_name_form, to_form(changeset, as: :user))

      {:noreply, socket}
    else
      {:noreply, assign(socket, :modal_ask_name_form, to_form(changeset, as: :user))}
    end
  end

  def handle_event("open-profile-modal", _params, socket) do
    {:noreply, assign(socket, :modal_ask_name, true)}
  end

  # --- main event handlers ---

  def handle_event("alter-status", %{"status" => status}, socket) do
    RoomManager.alter_room_status(
      socket.assigns.room_code,
      socket.assigns.user_token,
      String.to_atom(status)
    )

    {:noreply, socket}
  end

  def handle_event("select-card", %{"card" => card}, socket) do
    case socket.assigns.room.state do
      :voting ->
        RoomManager.select_card(
          socket.assigns.room_code,
          socket.assigns.user_token,
          card
        )

        if card == socket.assigns.selected_card do
          socket = assign(socket, :selected_card, nil)
          {:noreply, socket}
        else
          {:noreply, assign(socket, :selected_card, card)}
        end

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("observer-switch", _, socket) do
    RoomManager.change_observer_status(
      socket.assigns.room_code,
      socket.assigns.user_token,
      not Enum.find(
            socket.assigns.room.users,
            fn u -> u.user == socket.assigns.user_token end
          ).observer?
    )

    {:noreply, socket}
  end

  def handle_event("validate-story-form", %{"story" => story_params}, socket) do
    changeset =
      %NewStory{}
      |> NewStory.changeset(story_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:new_story_form, to_form(changeset, as: :story))}
  end

  def handle_event("add-story", %{"story" => story_params}, socket) do
    changeset = NewStory.changeset(%NewStory{}, story_params)

    if changeset.valid? do
      RoomManager.add_story(socket.assigns.room_code, changeset.changes)

      {:noreply,
       socket
       |> assign_new_story_form()}
    else
      socket
      |> assign(:new_story_form, to_form(changeset, as: :story))
      |> then(&{:noreply, &1})
    end
  end

  def handle_event("select-story", %{"story-id" => story_id}, socket) do
    RoomManager.select_story(socket.assigns.room_code, String.to_integer(story_id))
    {:noreply, socket}
  end

  def handle_event("remove-story", %{"story-id" => story_id}, socket) do
    RoomManager.remove_story(socket.assigns.room_code, String.to_integer(story_id))
    {:noreply, socket}
  end

  def handle_event("reveal-votes", %{"force" => force_str}, socket) do
    force? = force_str == "true"

    case RoomManager.reveal_votes(socket.assigns.room_code, force?) do
      :ok ->
        socket =
          socket
          |> assign(:modal_confirm_reveal_votes, false)

        {:noreply, socket}

      {:need_confirmation, pending_users} ->
        socket =
          socket
          |> assign(:modal_confirm_reveal_votes, true)
          |> assign(:pending_reveal_user, pending_users)

        {:noreply, socket}
    end
  end

  def handle_event("copy-room-code", _params, socket) do
    %URI{scheme: scheme, host: host, port: port} = socket.host_uri

    base_url =
      case port do
        80 -> "#{scheme}://#{host}"
        443 -> "#{scheme}://#{host}"
        _ -> "#{scheme}://#{host}:#{port}"
      end

    room_url = base_url <> "/room/#{socket.assigns.room_code}"
    socket = push_event(socket, "copy_to_clipboard", %{"text" => room_url})
    {:noreply, socket}
  end

  def handle_event("reopen-voting", _params, socket) do
    RoomManager.vote_again(socket.assigns.room_code)
    {:noreply, socket}
  end

  def handle_event("highlight-vote", %{"vote" => vote}, socket) do
    case User.is_host?(socket.assigns.room.users, socket.assigns.user_token) do
      true ->
        RoomManager.highlight_vote(socket.assigns.room_code, vote)
        {:noreply, socket}

      false ->
        {:noreply, socket}
    end
  end

  def handle_event("confirm-vote-and-go-next-story", _params, socket) do
    RoomManager.confirm_vote_and_go_next_story(socket.assigns.room_code)
    {:noreply, socket}
  end

  def handle_event("confirm_vote_and_continue_without_story", _params, socket) do
    RoomManager.confirm_vote_and_continue_without_story(socket.assigns.room_code)
    {:noreply, socket}
  end

  def handle_event("pass-leadership", %{"user" => new_leader_token}, socket) do
    RoomManager.pass_leadership(
      socket.assigns.room_code,
      socket.assigns.user_token,
      new_leader_token
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("poke", %{"from" => from, "to" => to}, socket) do
    RoomManager.poke(socket.assigns.room_code, from, to)
    {:noreply, socket}
  end

  def handle_event("validate_name", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("toggle-mobile-sidebar", _params, socket) do
    IO.inspect("toggling mobile sidebar")
    IO.inspect(socket.assigns.mobile_sidebar_open, label: "mobile_sidebar_open")
    {:noreply, assign(socket, :mobile_sidebar_open, !socket.assigns.mobile_sidebar_open)}
  end

  # --- info handlers ---

  @impl true
  def handle_info({@submit_room_config, new_state}, socket) do
    RoomManager.change_room_config(socket.assigns.room_code, new_state)
    socket = assign(socket, :show_room_config_modal, false)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:users_updated, users}, socket) do
    {:noreply, assign(socket, :room, %{socket.assigns.room | users: users})}
  end

  @impl true
  def handle_info({:room_status_changed, new_status}, socket) do
    socket = assign(socket, :room, %{socket.assigns.room | state: new_status})

    if new_status == :voting do
      socket = push_event(socket, "deal_cards_animation", %{})
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:user_voted, user_token, voted?}, socket) do
    updated_users =
      Enum.map(socket.assigns.room.users, fn user ->
        if user.user == user_token, do: %{user | voted?: voted?}, else: user
      end)

    {:noreply, assign(socket, :room, %{socket.assigns.room | users: updated_users})}
  end

  @impl true
  def handle_info({:room_stories_updated, stories}, socket) do
    socket
    |> assign(:room, %{socket.assigns.room | stories: stories})
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:room_config_changed, new_config}, socket) do
    socket
    |> assign(:room, Map.merge(socket.assigns.room, new_config))
    |> assign_room_config_form(socket.assigns.room)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:room_revealed, results}, socket) do
    socket
    |> assign(:room, %{socket.assigns.room | state: :revealed, results: results})
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:room_story_selected, story_id}, socket) do
    socket
    |> assign(:room, %{socket.assigns.room | current_story: story_id})
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:room_confirmed_reveal_votes, new_state}, socket) do
    decisive_vote =
      new_state.stories
      |> Enum.find(&(&1.id == new_state.current_story))
      |> case do
        nil -> "none"
        story -> story.decisive_vote
      end

    socket =
      socket
      |> assign(:room, new_state)
      |> put_flash(:info, "Decisive vote confirmed: #{decisive_vote}")

    {:noreply, socket}
  end

  @impl true
  def handle_info({:room_highlight_vote, vote}, socket) do
    room = %{socket.assigns.room | highlighted_vote: vote}
    {:noreply, assign(socket, :room, room)}
  end

  @impl true
  def handle_info({:room_new_voting_round, new_state}, socket) do
    socket =
      socket
      |> assign(:room, new_state)
      |> assign(:selected_card, nil)

    {:noreply, socket}
  end

  def handle_info({:room_poke, from, to}, socket) do
    {:noreply, push_event(socket, "poke_animation", %{from: from, to: to})}
  end

  def handle_info({:room_deleting}, socket) do
    socket =
      socket
      |> put_flash(:warning, "The room is being deleted.")
      |> push_navigate(to: "/")
    {:noreply, socket}
  end

  # --- private helpers ---

  defp current_story(room) do
    case room.current_story do
      nil -> nil
      id -> Enum.find(room.stories, &(&1.id == id))
    end
  end

  defp seat_position_style(_idx, total) when total <= 0 do
    "top: 50%; left: 50%;"
  end

  defp seat_position_style(idx, total) do
    angle = 2 * :math.pi() * idx / total
    radius = 40.0

    x = 50.0 + radius * :math.cos(angle)
    y = 50.0 + radius * :math.sin(angle)

    "top: #{Float.round(y, 2)}%; left: #{Float.round(x, 2)}%;"
  end

  defp format_agreement(nil), do: "—"

  defp format_agreement(value) when is_float(value) do
    percent = value * 100.0
    "#{Float.round(percent, 1)}% agreement"
  end

  defp get_next_story(room) do
    ordered = Enum.sort_by(room.stories, & &1.id)
    current_id = room.current_story

    Enum.find(ordered, fn story -> story.id > current_id and is_nil(story.story_points) end) ||
      Enum.find(ordered, fn story -> is_nil(story.story_points) and story.id != current_id end)
  end

  def format_icon_url(icon_name), do: "/images/profile_icons/#{icon_name}.png"

  defp pie_chart_segments(nil), do: []

  defp pie_chart_segments(vote_frequencies) do
    filtered =
      vote_frequencies
      |> Enum.reject(fn {vote, count} -> is_nil(vote) or count <= 0 end)

    total =
      filtered
      |> Enum.map(fn {_v, count} -> count end)
      |> Enum.sum()

    if total == 0 do
      []
    else
      {_, segments} =
        Enum.reduce(filtered, {0.0, []}, fn {vote, count}, {offset, acc} ->
          percent = count / total * 100.0
          seg = %{
            vote: vote,
            dash: "#{percent} #{100.0 - percent}",
            offset: -offset
          }

          {offset + percent, [seg | acc]}
        end)

      Enum.reverse(segments)
    end
  end

  defp pie_color(index) do
    colors = [
      "#6366F1",
      "#10B981",
      "#F59E0B",
      "#EF4444",
      "#3B82F6",
      "#EC4899",
      "#8B5CF6"
    ]

    Enum.at(colors, rem(index, length(colors)))
  end

  defp total_votes(room) do
    cond do
      room.results && room.results.story && is_list(room.results.story.votes) ->
        length(room.results.story.votes)

      room.results && is_map(room.results.vote_frequencies) ->
        room.results.vote_frequencies
        |> Enum.reject(fn {vote, count} -> is_nil(vote) or count <= 0 end)
        |> Enum.map(fn {_v, c} -> c end)
        |> Enum.sum()

      true ->
        0
    end
  end

  defp votes_for_display(room) do
    cond do
      room.results && room.results.story && is_list(room.results.story.votes) ->
        room.results.story.votes

      true ->
        room.users
        |> Enum.filter(&(!is_nil(&1.vote)))
        |> Enum.map(fn user ->
          %{user: user.user, name: user.name, vote: user.vote}
        end)
    end
  end

  defp icon_for_user(room, token) do
    case Enum.find(room.users, &(&1.user == token)) do
      nil -> "axolotl"
      user -> user.icon
    end
  end
end
