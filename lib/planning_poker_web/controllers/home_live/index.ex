defmodule PlanningPokerWeb.HomeLive.Index do
  use PlanningPokerWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,socket}
  end

  def handle_event("start_new_session",_,socket) do
    {:noreply, push_navigate(socket, to: ~p"/room/#{get_code()}")}
  end

  def handle_event("go_to_room", _, socket) do
   code = "qwerty"
    {:noreply, push_navigate(socket, to: ~p"/room/#{code}")}
  end

  defp get_code do
    PlanningPoker.RoomTicketDispenser.get_ticket()
  end
end
