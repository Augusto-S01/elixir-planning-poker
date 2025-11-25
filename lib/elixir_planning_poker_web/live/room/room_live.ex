defmodule ElixirPlanningPokerWeb.RoomLive do
  use ElixirPlanningPokerWeb, :live_view
  import ElixirPlanningPokerWeb.ModalComponent
  import ElixirPlanningPokerWeb.CoreComponents
  alias ElixirPlanningPoker.{RoomManager, User, NewStory}

  @close_modal_ask_name "close_modal_ask_name"
  @close_room_config "close_room_config"
  @submit_room_config "submit_room_config"
  @validate_room_config "validate_room_config"

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

  defp assign_forms(socket,state) do
    socket
    |> assign_form_ask_name(state)
    |> assign_room_config_form(state)
    |> assign_new_story_form()
  end

  defp assign_form_ask_name(socket, state) do
    form_ask_name =
      case User.find_user(state.users, socket.assigns.user_token) do
        {:ok, user} ->
          User.changeset(user)
        {:error, :not_found} ->
          User.changeset(User.new(socket.assigns.user_token))
      end
      |> to_form(as: :user)

    socket
    |> assign(:modal_ask_name_form, form_ask_name)
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
        } )
  end

  defp assign_base_assigns(socket, state, room_code, user_token) do
    socket
    |> assign(:room, state)
    |> assign(:room_code, room_code)
    |> assign(:user_token, user_token)
    |> assign(:modal_ask_name, false)
    |> assign(:modal_ask_name_form, %{"name" => ""})
    |> assign(:close_modal_ask_name, @close_modal_ask_name)
    |> assign(:close_room_config, @close_room_config)
    |> assign(:submit_room_config, @submit_room_config)
    |> assign(:validate_room_config, @validate_room_config)
    |> assign(:show_room_config_modal, false)
    |> assign(:new_user, false)
  end

  defp assign_user_and_modal(socket, user_token) do
    users = socket.assigns.room.users

    case User.find_user(users, user_token) do
      {:ok, user} ->
        modal_needed = is_nil(user.name) or String.trim(user.name) == ""

        assign(socket,
          modal_ask_name_form: %{"name" => user.name || ""},
          modal_ask_name: modal_needed
        )

      {:error, :not_found} ->
        new_user = User.new(user_token)

        assign(socket,
          modal_ask_name_form: %{"name" => new_user.name},
          modal_ask_name: true,
          new_user: true
        )
    end
  end

  # --- event handlers ---

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
  def handle_event(@submit_room_config, params,socket) do
    IO.inspect(params, label: "Room config params")
    {:noreply, socket}
  end

  @impl true
  def handle_event(@close_room_config, _params, socket) do
    IO.inspect(socket, label: "Opening room config modal")
    {:noreply, assign(socket, :show_room_config_modal, false)}
  end

  @impl true
  def handle_event("open-room-config",__params, socket) do
    IO.inspect(socket, label: "Opening room config modal")
    IO.inspect(socket.assigns.form_room_config, label: "Form data")
    {:noreply, assign(socket, :show_room_config_modal, true)}
  end

  def handle_event("submit_name", %{"user" => user_params}, socket) do
    name = user_params["name"] |> String.trim()
    case socket.assigns.new_user do
      true ->
        user =
          socket.assigns.user_token
          |> User.new(name)
        RoomManager.add_user(
          socket.assigns.room_code,
          user
        )
      false ->
        RoomManager.update_user_name(
          socket.assigns.room_code,
          socket.assigns.user_token,
          name
        )
    end
    {:noreply, assign(socket, :modal_ask_name, false)}
  end

  def handle_event("alter-status", %{"status" => status}, socket) do
    RoomManager.alter_room_status(socket.assigns.room_code, socket.assigns.user_token, String.to_atom(status))
    {:noreply, socket}
  end

  def handle_event("select-card", %{"card" => card}, socket) do
    IO.inspect(card, label: "Selected card")
    case socket.assigns.room.state do
      :voting ->
        RoomManager.select_card(
          socket.assigns.room_code,
          socket.assigns.user_token,
          card
        )
        {:noreply, socket}
      _ ->
        socket = put_flash(socket, :error, "Cannot select card in the current state.")
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
      |> put_flash(:error, "Invalid story title.")
      |> then(&{:noreply, &1})
    end
  end

  def handle_event("remove-story",%{"story-id" => story_id}, socket) do
    RoomManager.remove_story(socket.assigns.room_code, String.to_integer(story_id))
    {:noreply, socket}
  end


  def handle_event("teste", _params, socket) do
    IO.inspect(socket.assigns.room.stories, label: "Current stories")
    {:noreply, socket}
  end

  def handle_event(_, _, socket), do: {:noreply, socket}

  # --- info handlers ---
  @impl true
  def handle_info({@submit_room_config, new_state}, socket) do
    IO.inspect(new_state, label: "New room state from config modal")
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
    {:noreply, assign(socket, :room, %{socket.assigns.room | state: new_status})}
  end

  @impl true
  def handle_info({:user_voted, user_token, voted?}, socket) do
    socket = if voted? do
      put_flash(socket, :info, "User #{user_token} voted.")
    else
      put_flash(socket, :info, "User #{user_token} removed their vote.")
    end

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
    |> put_flash(:info, "Room stories updated.")
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:room_config_changed, new_config}, socket) do
    socket
    |> assign(:room, Map.merge(socket.assigns.room, new_config))
    |> assign_room_config_form(socket.assigns.room)
    |> put_flash(:info, "Room configuration updated.")
    |> then(&{:noreply, &1})
  end

end
