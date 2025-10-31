defmodule ElixirPlanningPokerWeb.RoomLive do
  use ElixirPlanningPokerWeb, :live_view
  import ElixirPlanningPokerWeb.ModalComponent
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
    |> assign(:modal_ask_name, false)
    |> assign(:modal_ask_name_form, %{"name" => ""})
    |> assign(:new_user, false)
  end

  defp assign_user_and_modal(socket, user_token) do
    users = socket.assigns.room.users

    case User.find_user(users, user_token) do
      {:ok, user} ->
        modal_needed = is_nil(user.name) or String.trim(user.name) == ""

        assign(socket,
          modal_ask_name_form: %{"name" => user.name || ""},
          modal_ask_name: modal_needed
        )

      {:error, :not_found} ->
        new_user = User.new(user_token)

        assign(socket,
          modal_ask_name_form: %{"name" => new_user.name},
          modal_ask_name: true,
          new_user: true
        )
    end
  end

  # --- event handlers ---

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :modal_ask_name, false)}
  end

  def handle_event("submit_name", %{"user" => user_params}, socket) do
    name = user_params["name"] |> String.trim()
    case socket.assigns.new_user do
      true ->
        user =
          socket.assigns.user_token
          |> User.new(name)
        RoomManager.add_user(
          socket.assigns.room_code,
          user
        )
      false ->
        RoomManager.update_user_name(
          socket.assigns.room_code,
          socket.assigns.user_token,
          name
        )
    end
    {:noreply, assign(socket, :modal_ask_name, false)}
  end

  def handle_event("alter-status", %{"status" => status}, socket) do
    RoomManager.alter_room_status(socket.assigns.room_code, socket.assigns.user_token, String.to_atom(status))
    {:noreply, socket}
  end

  def handle_event("select_card", %{"card" => card}, socket) do
    case socket.assigns.room.state do
      :voting ->
        RoomManager.select_card(
          socket.assigns.room_code,
          socket.assigns.user_token,
          card
        )
        {:noreply, socket}
      _ ->
        socket = put_flash(socket, :error, "Cannot select card in the current state.")
        {:noreply, socket}
    end
  end

  def handle_event(_, _, socket), do: {:noreply, socket}

  # --- info handlers ---
  @impl true
  def handle_info({:users_updated, users}, socket) do
    {:noreply, assign(socket, :room, %{socket.assigns.room | users: users})}
  end

  @impl true
  def handle_info({:room_status_changed, new_status}, socket) do
    {:noreply, assign(socket, :room, %{socket.assigns.room | state: new_status})}
  end


end
