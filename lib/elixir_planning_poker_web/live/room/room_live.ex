defmodule ElixirPlanningPokerWeb.RoomLive do
  use ElixirPlanningPokerWeb, :live_view
  import ElixirPlanningPokerWeb.ModalComponent
  import ElixirPlanningPokerWeb.Utils, only: [atom_keys_to_strings: 1]
  alias ElixirPlanningPoker.{RoomManager, User}

  @impl true
  def mount(%{"room_code" => room_code}, session, socket) do
    with {:ok, state} <- RoomManager.get_state(room_code),
         {:ok, socket} <- subscribe_room_pubsub(socket, room_code) do
      socket
      |> assign_base_assigns(state, room_code, session["user_token"])
      |> assign_user_and_modal(session["user_token"])
      |> then(&{:ok, &1})
    else
      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Room not found.")
         |> push_navigate(to: "/")}

      {:error, {:subscribe_failed, reason}} ->
        {:ok,
         socket
         |> put_flash(:error, "Error subscribing: #{inspect(reason)}")
         |> push_navigate(to: "/")}
    end
  end

  # --- helpers ---

  defp subscribe_room_pubsub(socket, room_code) do
    if connected?(socket) do
      case Phoenix.PubSub.subscribe(ElixirPlanningPoker.PubSub, "room:#{room_code}") do
        :ok -> {:ok, socket}
        {:error, reason} -> {:error, {:subscribe_failed, reason}}
      end
    else
      {:ok, socket}
    end
  end

  defp assign_base_assigns(socket, state, room_code, user_token) do
    socket
    |> assign(:room, state)
    |> assign(:room_code, room_code)
    |> assign(:user_token, user_token)
  end

  defp assign_user_and_modal(socket, user_token) do
    users = socket.assigns.room.users

    case User.find_user(users, user_token) do
      {:ok, user} ->
        modal_needed = is_nil(user.name) or String.trim(user.name) == ""

        assign(socket,
          user: user,
          modal_ask_name: modal_needed
        )

      {:error, :not_found} ->
        assign(socket,
          user: User.new(user_token),
          modal_ask_name: true
        )
    end
  end

  # --- event handlers ---

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :modal_ask_name, false)}
  end

  def handle_event("submit_name", %{"user" => %{"name" => name}}, socket) do
    RoomManager.update_user_name(
      socket.assigns.room_code,
      socket.assigns.user_token,
      name
    )

    {:noreply, assign(socket, :modal_ask_name, false)}
  end

  def handle_event(_, _, socket), do: {:noreply, socket}

  # --- info handlers ---
  @impl true
  def handle_info({:users_updated, users}, socket) do
    {:noreply, assign(socket, :room, %{socket.assigns.room | users: users})}
  end
end
