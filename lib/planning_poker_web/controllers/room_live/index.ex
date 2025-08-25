defmodule PlanningPokerWeb.RoomLive.Index do
  use PlanningPokerWeb , :live_view

  def mount(%{"code" => code}, _session, socket) do

    {:ok, socket}
  end
end
