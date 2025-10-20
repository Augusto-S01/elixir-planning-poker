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

  def update_user_name(room_code, user_token, name) do
    case Registry.lookup(ElixirPlanningPoker.RoomRegistry, room_code) do
      [{_pid, _}] ->
        teste = ElixirPlanningPoker.Room.update_user_name(room_code, user_token, name)
      IO.inspect(teste, label: "Teste RoomManager update_user_name")

      [] -> {:error, :room_not_found}
    end
  end
end
