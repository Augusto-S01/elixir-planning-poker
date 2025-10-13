defmodule ElixirPlanningPoker.Room do

  use GenServer

  defstruct [:name, :deck_type, :custom_deck, :users, :stories, :current_story, :state , :cards, :room_code]

  # Client API
  def start_link(opts) do
    room_code = opts[:room_code] || generate_room_code()
    IO.inspect(room_code, label: "Generated room code")

    opts = Map.put(opts, :room_code, room_code)
    GenServer.start_link(__MODULE__, opts, name: String.to_atom(room_code))
  end

  @impl true
  def init(opts) do
    IO.inspect(opts, label: "Room init options")
    IO.inspect(opts[:name], label: "Room name option")
    IO.inspect(Map.get(opts, :name), label: "Room name from Map.get")
    room = %__MODULE__{
      name: opts[:name] || "New Room",
      deck_type: opts[:deck_type] || "fibonacci",
      custom_deck: opts[:custom_deck] || "",
      users: %{},
      stories: [],
      current_story: nil,
      state: :waiting,
      cards: get_cards_from_deck(opts[:deck_type], opts[:custom_deck]),
      room_code: opts[:room_code]
    }
    {:ok, room}
  end

  defp get_cards_from_deck(deck_type, custom_deck) do
    case deck_type do
      "fibonacci" -> ["0", "1/2", "1", "2", "3", "5", "8", "13", "21", "34", "55", "89", "?"]
      "tshirt" -> ["XS", "S", "M", "L", "XL", "?"]
      "sequential" -> Enum.map(1..20, &Integer.to_string/1) ++ ["?"]
      "custom" -> String.split(custom_deck || "", ",") |> Enum.map(&String.trim/1) |> Enum.filter(&(&1 != ""))
      _ -> []
    end
  end

  defp generate_room_code do
    :crypto.strong_rand_bytes(3) |> Base.url_encode64() |> binary_part(0, 4)
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  # server callbacks
  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end






end
