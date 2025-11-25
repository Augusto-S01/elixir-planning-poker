defmodule ElixirPlanningPoker.Room do
  use GenServer

  alias ElixirPlanningPoker.User
  defstruct [
    :name,
    :deck_type,
    :custom_deck,
    :users,
    :stories,
    :story_counter,
    :current_story,
    :state,
    :cards,
    :room_code
  ]

  # Client API
  def start_link(%{room_code: room_code} = opts) do
    GenServer.start_link(__MODULE__, opts, name: via(room_code))
  end

  def get_state(room_code) do
    GenServer.call(via(room_code), :get_state)
  end

  def add_user(room_code, user_params) do
    GenServer.cast(via(room_code), {:add_user, user_params})
  end

  def select_card(room_code, user_token, card) do
    GenServer.cast(via(room_code), {:select_card, user_token, card})
  end

  def update_user_name(room_code, user_token, name) do
    GenServer.cast(via(room_code), {:update_user_name, user_token, name})
  end

  def alter_room_status(room_code, user_token, status) do
    GenServer.cast(via(room_code), {:alter_room_status, user_token, status})
  end

  def change_room_config(room_code, config_params) do
    GenServer.cast(via(room_code), {:change_room_config, config_params})
  end

  def change_observer_status(room_code, user_token, new_observer_status) do
    GenServer.cast(via(room_code), {:change_observer_status, user_token, new_observer_status})
  end

  def add_story(room_code, story_params) do
    GenServer.cast(via(room_code), {:add_story, story_params})
  end

  def remove_story(room_code, story_id) do
    GenServer.cast(via(room_code), {:remove_story, story_id})
  end

  def reveal_votes(room_code, force?) do
    GenServer.call(via(room_code), {:reveal_votes, force?})
  end

  def select_story(room_code, story_id) do
    GenServer.cast(via(room_code), {:select_story, story_id})
  end

  def confirm_reveal_votes(room_code, decisive_vote) do
    GenServer.cast(via(room_code), {:confirm_reveal_votes, decisive_vote})
  end

  # Server Callbacks
  @impl true
  def init(opts) do
    room = %__MODULE__{
      name: opts[:name] || "New Room",
      deck_type: opts[:deck_type] || "fibonacci",
      custom_deck: opts[:custom_deck] || "",
      users: opts[:users] || [],
      stories: [],
      current_story: nil,
      state: :waiting,
      cards: get_cards_from_deck(opts[:deck_type], opts[:custom_deck]),
      story_counter: 0,
      room_code: opts[:room_code]
    }

    {:ok, room}
  end

  @impl true
  def handle_cast({:update_user_name, user_token, name}, state) do
    updated_users =
      Enum.map(state.users, fn user ->
        if user.user == user_token, do: %{user | name: name}, else: user
      end)

    new_state = %{state | users: updated_users}

    notify_users_updated(new_state)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:alter_room_status, user_token, status}, state) do
    new_state = case User.is_host?(state.users, user_token) do
      true ->
        notify_room_status_changed(%{state | state: status})
        %{state | state: status}

      false ->
        state
    end
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:add_story, story_params}, state) do
    new_story = %{
      id: state.story_counter + 1,
      title: Map.get(story_params, :title, ""),
      description: Map.get(story_params, :description, "")
    }

    new_state = %{state | stories: state.stories ++ [new_story], story_counter: state.story_counter + 1}
    notify_room_stories_updated(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:select_story, story_id}, state) do
    new_state = %{state | current_story: story_id}
    notify_room_story_selected(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:remove_story, story_id}, state) do
    new_stories = Enum.filter(state.stories, fn story -> story.id != story_id end)
    new_state = %{state | stories: new_stories}
    notify_room_stories_updated(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:add_user, user}, state) do
    new_state = %{state | users: state.users ++ [user]}
    notify_users_updated(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:select_card, user_token, vote}, state) do
    IO.inspect(vote, label: "Vote received")

    updated_users =
      Enum.map(state.users, fn
        %{user: ^user_token, vote: ^vote} = u ->
          notify_user_voted(user_token, false, state.room_code)
          User.set_vote(u, nil)

        %{user: ^user_token} = u ->
          notify_user_voted(user_token, true, state.room_code)
          User.set_vote(u, vote)

        u ->
          u

      end)

    {:noreply, %{state | users: updated_users}}
  end

  @impl true
  def handle_cast({:change_room_config, config_params}, state) do
    new_deck_type = Map.get(config_params, :deck_type, state.deck_type)
    new_custom_deck = Map.get(config_params, :custom_deck, state.custom_deck)

    new_state = %{
      state
      | name: Map.get(config_params, :name, state.name),
        deck_type: new_deck_type,
        custom_deck: new_custom_deck,
        cards: get_cards_from_deck(new_deck_type, new_custom_deck)
    }

    notify_room_config_changed(new_state)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:change_observer_status, user_token, new_observer_status}, state) do
    updated_users =
      Enum.map(state.users, fn user ->
        if user.user == user_token do
          %{user | observer?: new_observer_status}
        else
          user
        end
      end)
    new_state = %{state | users: updated_users}
    notify_users_updated(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_call({:reveal_votes, force?}, _from, state) do
    cond do
      force?  or all_voted?(state) ->
        new_state = %{state | state: :revealed}
        notify_room_revealed(new_state, calculate_results(new_state))

        {:reply, :ok, new_state}
      true ->
        pending =
          pending_users(state)
          |> Enum.map(fn user -> user.name end)


        {:reply, {:need_confirmation, pending}, state}
    end
  end

  @impl true
  def handle_cast({:confirm_reveal_votes, decisive_vote}, state) do
    stories_ok? =
      is_list(state.stories) and
        state.stories != [] and
        not is_nil(state.current_story)
    new_stories =
      if stories_ok? do
        Enum.map(state.stories, fn story ->
          if story.id == state.current_story do
            Map.put(story, :decisive_vote, decisive_vote)
          else
            story
          end
        end)
      else
        state.stories
      end

    next_story = find_next_story(state)

    new_state =
      state
      |> Map.put(:state, :voting)
      |> Map.put(:stories, new_stories)
      |> Map.put(:current_story, next_story && next_story.id)
      |> clear_votes()

    notify_room_confirm_vote(new_state)
    {:noreply, new_state}
  end


  @impl true
  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  # Helper
  defp get_cards_from_deck(deck_type, custom_deck) do
    case deck_type do
      "fibonacci" ->
        ["0", "1/2", "1", "2", "3", "5", "8", "13", "21", "34", "55", "89", "?"]

      "tshirt" ->
        ["XS", "S", "M", "L", "XL", "?"]

      "sequential" ->
        Enum.map(1..20, &Integer.to_string/1) ++ ["?"]

      "custom" ->
        custom_deck
        |> to_string()
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))

      _ ->
        []
    end
  end

  defp clear_votes(state) do
    updated_users =
      Enum.map(state.users, fn user ->
        %{user | vote: nil, voted?: false}
      end)

    %{state | users: updated_users}
  end

  defp find_next_story(state) do
    state.stories
    |> Enum.sort_by(& &1.id)
    |> then(fn ordered ->
      Enum.find(ordered, &(&1.id > state.current_story)) ||
        Enum.find(ordered, &is_nil(&1.vote))
    end)
  end



  defp calculate_results(room) do
    vote_frequencies =
      room.users
      |> Enum.map(& &1.vote)
      |> Enum.frequencies()
    player_count = length(room.users)
    agreement =
      vote_frequencies
      |> Enum.map(fn {_vote, count} -> count / player_count end)
      |> Enum.max()
    current_story = Enum.filter(room.stories, fn story -> story.id == room.current_story end)
    room.current_story || %{}

    {:ok,
      %{
      agreement: agreement,
      vote_frequencies: vote_frequencies,
      story: current_story
      }}

  end

  defp all_voted?(room) do
    Enum.all?(room.users, & &1.vote)
  end

  defp pending_users(room) do
    Enum.filter(room.users, &is_nil(&1.vote))
  end

  # Helper notifications

  defp notify_user_voted(user_token, voted?, room_code) do
    IO.inspect(voted?, label: "User voted event")
    Phoenix.PubSub.broadcast(
      ElixirPlanningPoker.PubSub,
      "room:#{room_code}",
      {:user_voted, user_token, voted?}
    )
  end

  defp notify_users_updated(state) do
    Phoenix.PubSub.broadcast(
      ElixirPlanningPoker.PubSub,
      "room:#{state.room_code}",
      {:users_updated, state.users}
    )
  end

  defp notify_room_status_changed(state) do
    Phoenix.PubSub.broadcast(
      ElixirPlanningPoker.PubSub,
      "room:#{state.room_code}",
      {:room_status_changed, state.state}
    )
  end

  defp notify_room_config_changed(state) do
    Phoenix.PubSub.broadcast(
      ElixirPlanningPoker.PubSub,
      "room:#{state.room_code}",
      {:room_config_changed, state}
    )
  end

  defp notify_room_stories_updated(state) do
    Phoenix.PubSub.broadcast(
      ElixirPlanningPoker.PubSub,
      "room:#{state.room_code}",
      {:room_stories_updated, state.stories}
    )
  end

  defp notify_room_revealed(state, results) do
    Phoenix.PubSub.broadcast(
      ElixirPlanningPoker.PubSub,
      "room:#{state.room_code}",
      {:room_revealed, results}
    )
  end

  defp notify_room_story_selected(state) do
    Phoenix.PubSub.broadcast(
      ElixirPlanningPoker.PubSub,
      "room:#{state.room_code}",
      {:room_story_selected, state.current_story}
    )
  end

  defp notify_room_confirm_vote(new_state) do
    Phoenix.PubSub.broadcast(
      ElixirPlanningPoker.PubSub,
      "room:#{new_state.room_code}",
      {:room_confirmed_reveal_votes, new_state}
    )
  end

  defp via(room_code),
    do: {:via, Registry, {ElixirPlanningPoker.RoomRegistry, room_code}}
end
