defmodule ElixirPlanningPoker.Room do
  use GenServer

  alias ElixirPlanningPoker.User
  defstruct [
    :name,
    :deck_type,
    :custom_deck,
    :users,
    :stories,
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

  defp via(room_code),
    do: {:via, Registry, {ElixirPlanningPoker.RoomRegistry, room_code}}
end
