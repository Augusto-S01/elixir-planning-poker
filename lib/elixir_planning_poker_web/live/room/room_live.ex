defmodule ElixirPlanningPokerWeb.RoomLive do
  use ElixirPlanningPokerWeb, :live_view

  alias ElixirPlanningPoker.RoomManager

  def mount(%{"room_code" => room_code}, session, socket) do
    socket
    |> assign(:user_token, session["user_token"])
    |> assign(:room_code, room_code)
    {:ok, assign(socket, :room_code, room_code)}
  end

  def handle_event("teste", _url, socket) do
    {:noreply, socket}
  end

  def handle_event(_, _url, socket) do
    IO.inspect("handler")
    {:noreply, socket}
  end

end
