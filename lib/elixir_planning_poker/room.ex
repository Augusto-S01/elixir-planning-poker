defmodule ElixirPlanningPoker.Room do
  use GenServer

  defstruct [:name, :deck_type, :custom_deck, :users, :stories, :current_story, :state , :cards, :room_code]

  # Client API
  def start_link(%{room_code: room_code} = opts) do
    GenServer.start_link(__MODULE__, opts, name: via(room_code))
  end

  def get_state(room_code) do
    GenServer.call(via(room_code), :get_state)
  end

  defp via(room_code),
    do: {:via, Registry, {ElixirPlanningPoker.RoomRegistry, room_code}}

  # Server Callbacks
  @impl true
  def init(opts) do
    room = %__MODULE__{
      name: opts[:name] || "New Room",
      deck_type: opts[:deck_type] || "fibonacci",
      custom_deck: opts[:custom_deck] || "",
      users: opts[:users] || %{},
      stories: [],
      current_story: nil,
      state: :waiting,
      cards: get_cards_from_deck(opts[:deck_type], opts[:custom_deck]),
      room_code: opts[:room_code]
    }

    {:ok, room}
  end

  @impl true
  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  # Helper
  defp get_cards_from_deck(deck_type, custom_deck) do
    case deck_type do
      "fibonacci" -> ["0", "1/2", "1", "2", "3", "5", "8", "13", "21", "34", "55", "89", "?"]
      "tshirt" -> ["XS", "S", "M", "L", "XL", "?"]
      "sequential" -> Enum.map(1..20, &Integer.to_string/1) ++ ["?"]
      "custom" -> custom_deck |> to_string() |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
      _ -> []
    end
  end

end
