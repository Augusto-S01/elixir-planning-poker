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

  def select_card(room_code, user_token, card) do
    case Registry.lookup(ElixirPlanningPoker.RoomRegistry, room_code) do
      [{_pid, _}] ->
        ElixirPlanningPoker.Room.select_card(room_code, user_token, card)
    end
  end

  def alter_room_status(room_code, user_token, status) do
    case Registry.lookup(ElixirPlanningPoker.RoomRegistry, room_code) do
      [{_pid, _}] ->
        ElixirPlanningPoker.Room.alter_room_status(room_code, user_token, status)
      [] -> {:error, :room_not_found}
    end
  end

  def update_user_name(room_code, user_token, name) do
    case Registry.lookup(ElixirPlanningPoker.RoomRegistry, room_code) do
      [{_pid, _}] ->
        teste = ElixirPlanningPoker.Room.update_user_name(room_code, user_token, name)

      [] -> {:error, :room_not_found}
    end
  end

  def add_user(room_code, user_params) do
    case Registry.lookup(ElixirPlanningPoker.RoomRegistry, room_code) do
      [{_pid, _}] ->
        ElixirPlanningPoker.Room.add_user(room_code, user_params)

      [] -> {:error, :room_not_found}
    end
  end
end
