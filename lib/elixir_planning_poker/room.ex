defmodule ElixirPlanningPoker.Room do

  use GenServer

  defstruct [:name, :deck_type, :custom_deck, :users, :stories, :current_story, :state , :cards, :room_code]

  # Client API
  def start_link(opts) do
    {:ok, pid} = GenServer.start_link(__MODULE__, opts)
    ElixirPlanningPoker.RoomManager.add_room(pid)
    IO.inspect(pid, label: "Started Room with PID")
    {:ok, pid}
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  # server callbacks
  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

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
      room_code: opts[:room_code] || generate_room_code()
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

end
