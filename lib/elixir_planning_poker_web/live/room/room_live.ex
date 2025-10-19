defmodule ElixirPlanningPokerWeb.RoomLive do
  use ElixirPlanningPokerWeb, :live_view

def mount(%{"room_code" => room_code}, session, socket) do
  socket =
    case ElixirPlanningPoker.RoomManager.get_state(room_code) do
      {:ok, state} ->
        IO.inspect(state, label: "Room State")
        socket = assign(socket, :room, state)
        case find_user(socket, session["user_token"]) do
          {:ok, user} ->
            socket
            |> assign(:user, user)
            |> assign(:modal_ask_name, false)
          {:error, :not_found} ->
            socket
            |> assign(:user, nil)
            |> assign(:modal_ask_name, true)

        end
        socket
        |> assign(:room, state)
        |> assign(:room_code, room_code)
        |> assign(:user_token, session["user_token"])
      {:error, :not_found} ->
        socket
        |> put_flash(:error, "Room not found.")
        |> push_navigate(to: "/")

    end
  {:ok,socket}
end

defp find_user(socket, user_token) do
  case Enum.find(socket.assigns.room.users, nil, fn user -> user.user == user_token end) do
    nil -> {:error, :not_found}
    user -> {:ok , user}
  end
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
