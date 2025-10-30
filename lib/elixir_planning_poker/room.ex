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

  def update_user_name(room_code, user_token, name) do
    GenServer.cast(via(room_code), {:update_user_name, user_token, name})
  end

  # Server Callbacks
  @impl true
  def init(opts) do
    IO.inspect(opts, label: "Initializing Room with opts")
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
    IO.inspect({user_token, name}, label: "Updating user name")
    updated_users =
      Enum.map(state.users, fn user ->
        if user.user == user_token, do: %{user | name: name}, else: user
      end)

    IO.inspect(updated_users, label: "Updated users list")
    new_state = %{state | users: updated_users}

    notify_users_updated(new_state)

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

  defp notify_users_updated(state) do
    Phoenix.PubSub.broadcast(
      ElixirPlanningPoker.PubSub,
      "room:#{state.room_code}",
      {:users_updated, state.users}
    )
  end

  defp via(room_code),
    do: {:via, Registry, {ElixirPlanningPoker.RoomRegistry, room_code}}
end
