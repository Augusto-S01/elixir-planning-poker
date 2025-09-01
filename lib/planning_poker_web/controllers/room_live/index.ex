defmodule PlanningPokerWeb.RoomLive.Index do
  use PlanningPokerWeb , :live_view

  def mount(params, _session, socket) do
    show_modal = !Map.has_key?(params, "code")
    {:ok, assign(socket, show_modal: show_modal)}
  end



end
