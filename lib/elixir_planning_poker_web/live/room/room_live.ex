defmodule ElixirPlanningPokerWeb.RoomLive do
  use ElixirPlanningPokerWeb, :live_view

def mount(%{"room_code" => room_code}, session, socket) do
  socket =
    case ElixirPlanningPoker.RoomManager.get_state(room_code) do
      {:ok, state} ->
        IO.inspect(state, label: "Room State")
        socket
        |> assign(:room, state)


      {:error, :not_found} ->
        socket
        |> put_flash(:error, "Room not found.")
        |> push_navigate(to: "/")

    end

  user = find_user(socket, session["user_token"])
  modal_ask_name =
  case user do
    nil -> true
    %{name: ""} -> true
    _ -> false
  end

  IO.inspect(socket , label: "Socket after mount")
  {:ok,
   socket
   |> assign(:modal_ask_name, modal_ask_name)
   |> assign(:user_token, session["user_token"])
   |> assign(:room_code, room_code)}
end

defp find_user(socket, user_token) do
  Enum.find(socket.assigns.room.users, fn user -> user.user == user_token end)
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
