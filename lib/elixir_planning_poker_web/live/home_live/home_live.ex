defmodule ElixirPlanningPokerWeb.HomeLive do
  use ElixirPlanningPokerWeb, :live_view

  import ElixirPlanningPokerWeb.Components.Swiper
  import ElixirPlanningPokerWeb.Components.RoomConfigModal
  alias ElixirPlanningPoker.{RoomManager, User}
  import ElixirPlanningPokerWeb.Utils
  alias ElixirPlanningPokerWeb.Components.Icon

  def mount(_params, session, socket) do
    user = User.new(session["user_token"])

    {:ok,
     socket
     |> assign(:user_token, session["user_token"])
     |> assign(:selected_mode, :left)
     |> assign(:show_modal, false)
     |> assign(:form, to_form(User.changeset(user)))}
  end

  def handle_event("swiper_toggle", params, socket) do
    selected =
      case params["selected"] do
        "left" -> :left
        "right" -> :right
      end

    {:noreply, assign(socket, :selected_mode, selected)}
  end

  def handle_event("create_room", _params, socket) do
    {:noreply, assign(socket, :show_modal, true)}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :show_modal, false)}
  end

  def handle_event("validate", %{"room" => room_params}, socket) do
    form = to_form(room_params, as: :room)
    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("submit", %{"room" => params}, socket) do
  params = atomize_keys(params)
  user =
    socket.assigns.user_token
    |> User.new(params[:user_name] || "", :host)
    |> Map.from_struct()

  room_params =
    params
    |> Map.put(:users, [user])
    |> Map.put_new(:room_code, generate_room_code())

  with {:ok, _pid} <- RoomManager.start_or_get(room_params) do
    {:noreply,
     socket
     |> assign(:show_modal, false)
     |> push_navigate(to: ~p"/rooms/#{room_params.room_code}")}
  else
    {:error, reason} ->
      {:noreply,
       socket
       |> assign(:show_modal, false)
       |> put_flash(:error, "Error creating room: #{inspect(reason)}")
       |> push_navigate(to: "/")}
  end
end

  def handle_event("ignore_click", _params, socket) do
    {:noreply, socket}
  end

  defp generate_room_code do
    :crypto.strong_rand_bytes(3) |> Base.url_encode64() |> binary_part(0, 4)
  end
end
