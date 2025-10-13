defmodule ElixirPlanningPokerWeb.RoomLive do
  use ElixirPlanningPokerWeb, :live_view

  alias ElixirPlanningPoker.Room

  def mount(%{"id" => room_pid}, _session, socket) do
    {:ok, assign(socket, :room_pid, room_pid)}
  end

end
