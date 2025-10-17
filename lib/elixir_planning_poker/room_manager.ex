defmodule ElixirPlanningPoker.RoomManager do
  def start_or_get(%{room_code: room_code} = params) do
    case Registry.lookup(ElixirPlanningPoker.RoomRegistry, room_code) do
      [{pid, _}] ->
        {:ok, pid}

      [] ->
        case DynamicSupervisor.start_child(ElixirPlanningPoker.RoomSupervisor, {ElixirPlanningPoker.Room, params}) do
          {:ok, pid} -> {:ok, pid}
          {:error, {:already_started, pid}} -> {:ok, pid}
          other -> other
        end
    end
  end

  def get_state(room_code) do
    case Registry.lookup(ElixirPlanningPoker.RoomRegistry, room_code) do
      [{_pid, _}] -> {:ok, ElixirPlanningPoker.Room.get_state(room_code)}
      [] -> {:error, :not_found}
    end
  end
end
