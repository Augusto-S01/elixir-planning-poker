defmodule ElixirPlanningPokerWeb.HomeLive do
  use ElixirPlanningPokerWeb, :live_view

  import ElixirPlanningPokerWeb.Components.Swiper
  alias ElixirPlanningPoker.{RoomManager, User}
  alias ElixirPlanningPokerWeb.Components.Icon

  @close_room_config "close_room_config"
  @submit_room_config "submit_room_config"
  @validate_room_config "validate_room_config"

  def mount(_params, session, socket) do
    user = User.new(session["user_token"])

    {:ok,
     socket
     |> assign(:user_token, session["user_token"])
     |> assign(:selected_mode, :left)
     |> assign(:show_room_config_modal, false)
     |> assign(:close_room_config, @close_room_config)
     |> assign(:validate_room_config, @validate_room_config)
     |> assign(:submit_room_config, @submit_room_config)
     |> assign_join_room_form()
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
    {:noreply, assign(socket, :show_room_config_modal, true)}
  end

  def handle_event(@close_room_config, _params, socket) do
    {:noreply, assign(socket, :show_room_config_modal, false)}
  end

  def handle_event("join_room", %{"join_room" => %{"room_code" => room_code}}, socket) do
    case RoomManager.exists?(room_code) do
      true ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/room/#{room_code}")}
      false ->
        {:noreply,
         socket
         |> put_flash(:error, "Room not found")
         |> assign_join_room_form()}
    end
  end

  def handle_info({@submit_room_config, params}, socket) do
    user =
      socket.assigns.user_token
      |> User.new(params[:user_name] || "", :host)

    room_params =
      params
      |> Map.put(:users, [user])
      |> Map.put_new(:room_code, generate_room_code())

    with {:ok, _pid} <- RoomManager.start_or_get(room_params) do
      {:noreply,
       socket
       |> assign(:show_modal, false)
       |> push_navigate(to: ~p"/room/#{room_params.room_code}")}
    else
      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:show_modal, false)
         |> put_flash(:error, "Error creating room: #{inspect(reason)}")
         |> push_navigate(to: "/")}
    end
  end

  defp generate_room_code do
    :crypto.strong_rand_bytes(3) |> Base.url_encode64() |> binary_part(0, 4)
  end

  defp assign_join_room_form(socket) do
    cs = ElixirPlanningPoker.JoinRoom.changeset(%ElixirPlanningPoker.JoinRoom{})
    assign(socket, :join_room_form, to_form(cs))
  end

end
