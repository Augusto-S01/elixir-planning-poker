defmodule ElixirPlanningPokerWeb.RoomLive do
  use ElixirPlanningPokerWeb, :live_view

  def mount(%{"room_code" => room_code}, session, socket) do
    socket
    |> assign(:user_token, session["user_token"])
    |> assign(:room_code, room_code)
    {:ok, assign(socket, :room_code, room_code)}
  end

def handle_event("teste", _params, socket) do
  case ElixirPlanningPoker.RoomManager.get_state(socket.assigns.room_code) do
    {:ok, state} -> IO.inspect(state, label: "Room State"); {:noreply, socket}
    {:error, :not_found} -> {:noreply, put_flash(socket, :error, "Sala não está ativa.")}
  end
end


  def handle_event(_, _url, socket) do
    IO.inspect("handler")
    {:noreply, socket}
  end

end
