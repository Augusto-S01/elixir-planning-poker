defmodule ElixirPlanningPoker.RoomManager do
  use GenServer

  # Client API
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def add_room(pid) do
    GenServer.cast(__MODULE__, {:add_room, pid })
  end
  def remove_room(room_code) do
    GenServer.cast(__MODULE__, {:remove_room, room_code})
  end
  def get_rooms() do
    GenServer.call(__MODULE__, :get_rooms)
  end

  def get_state(room_code) do
    GenServer.call(__MODULE__, {:get_state, room_code})
  end

  # Server Callbacks
  @impl true
  def handle_call({:get_state, room_code}, _from, state) do
    IO.inspect(state, label: "RoomManager state")
    room_pid = Enum.find(Map.keys(state), fn pid -> Map.get(state, pid) == room_code end)
    room_state = ElixirPlanningPoker.Room.get_state(room_pid)
    {:reply, room_state, state}
  end

  @impl true
  def handle_call(:get_rooms, _from, state) do
    {:reply, Map.keys(state), state}
  end

  @impl true
  def handle_cast({:add_room, pid}, room_map) do #handle cast is async
    room_state = ElixirPlanningPoker.Room.get_state(pid)
    room_code = room_state.room_code
    {:noreply, Map.put(room_map, pid, room_code)}
  end

  @impl true
  def handle_cast({:remove_room, room_code}, room_map) do
    {:noreply, Map.delete(room_map, room_code)}
  end

  @impl true
  def init(params) do
    IO.inspect(params, label: "RoomManager init params")
    {:ok, params}
  end

end
