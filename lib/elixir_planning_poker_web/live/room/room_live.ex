defmodule ElixirPlanningPokerWeb.RoomLive do
  use ElixirPlanningPokerWeb, :live_view
  import ElixirPlanningPokerWeb.ModalComponent

  def mount(%{"room_code" => room_code}, session, socket) do
    socket =
      case ElixirPlanningPoker.RoomManager.get_state(room_code) do
        {:ok, state} ->
          IO.inspect(state, label: "Room State")

          if connected?(socket) do
            Phoenix.PubSub.subscribe(ElixirPlanningPoker.PubSub, "room:#{room_code}")
          end

          socket =
            socket
            |> assign(:room, state)
            |> assign(:room_code, room_code)
            |> assign(:user_token, session["user_token"])

          socket =
            case find_user(socket, session["user_token"]) do
              {:ok, user} ->
                if is_nil(user.name) or String.trim(user.name) == "" do
                  assign(socket, :user, user)
                  |> assign(:modal_ask_name, true)
                else
                  assign(socket, :user, user)
                  |> assign(:modal_ask_name, false)
                end

              {:error, :not_found} ->
                assign(socket, :user, nil)
                |> assign(:modal_ask_name, true)
            end

          socket

        {:error, :not_found} ->
          socket
          |> put_flash(:error, "Room not found.")
          |> push_navigate(to: "/")
      end

    IO.inspect(socket.assigns, label: "Socket Assigns")
    {:ok, socket}
  end

  # handle events
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :modal_ask_name, false)}
  end

  def handle_event("submit_name", %{"user" => %{"name" => name}}, socket) do
    ElixirPlanningPoker.RoomManager.update_user_name(
      socket.assigns.room_code,
      socket.assigns.user_token,
      name
    )

    {:noreply, assign(socket, :modal_ask_name, false)}
  end

  def handle_event(_, _url, socket) do
    {:noreply, socket}
  end

  # handle info
  @impl true
  def handle_info({:users_updated, users}, socket) do
    {:noreply, assign(socket, :room, %{socket.assigns.room | users: users})}
  end

  # helpers
  defp find_user(socket, user_token) do
    case Enum.find(socket.assigns.room.users, nil, fn user -> user.user == user_token end) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end
end
