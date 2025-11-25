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
        ElixirPlanningPoker.Room.update_user_name(room_code, user_token, name)

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

  def change_room_config(room_code, config_params) do
    case Registry.lookup(ElixirPlanningPoker.RoomRegistry, room_code) do
      [{_pid, _}] ->
        ElixirPlanningPoker.Room.change_room_config(room_code, config_params)

      [] -> {:error, :room_not_found}
    end
  end

  def change_observer_status(room_code, user_token, new_observer_status) do
    case Registry.lookup(ElixirPlanningPoker.RoomRegistry, room_code) do
      [{_pid, _}] ->
        ElixirPlanningPoker.Room.change_observer_status(room_code, user_token, new_observer_status)

      [] -> {:error, :room_not_found}
    end
  end

  def add_story(room_code, story_params) do
    case Registry.lookup(ElixirPlanningPoker.RoomRegistry, room_code) do
      [{_pid, _}] ->
        ElixirPlanningPoker.Room.add_story(room_code, story_params)

      [] -> {:error, :room_not_found}
    end
  end

  def select_story(room_code, story_id) do
    IO.inspect("select_story called", label: "Select Story API")
    case Registry.lookup(ElixirPlanningPoker.RoomRegistry, room_code) do
      [{_pid, _}] ->
        ElixirPlanningPoker.Room.select_story(room_code, story_id)

      [] -> {:error, :room_not_found}
    end
  end

  def remove_story(room_code, story_id) do
    case Registry.lookup(ElixirPlanningPoker.RoomRegistry, room_code) do
      [{_pid, _}] ->
        ElixirPlanningPoker.Room.remove_story(room_code, story_id)

      [] -> {:error, :room_not_found}
    end
  end

  def reveal_votes(room_code, force? \\ false) do
    case Registry.lookup(ElixirPlanningPoker.RoomRegistry, room_code) do
      [{_pid, _}] ->
        ElixirPlanningPoker.Room.reveal_votes(room_code, force?)

      [] -> {:error, :room_not_found}
    end
  end

  def confirm_reveal_votes(room_code, decisive_vote) do
    case Registry.lookup(ElixirPlanningPoker.RoomRegistry, room_code) do
      [{_pid, _}] ->
        ElixirPlanningPoker.Room.confirm_reveal_votes(room_code, decisive_vote)

      [] -> {:error, :room_not_found}
    end
  end

end
