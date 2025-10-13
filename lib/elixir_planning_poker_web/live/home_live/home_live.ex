defmodule ElixirPlanningPokerWeb.HomeLive do
  use ElixirPlanningPokerWeb, :live_view

  import ElixirPlanningPokerWeb.Components.Swiper
  import ElixirPlanningPokerWeb.Components.RoomConfigModal
  alias ElixirPlanningPokerWeb.Components.Icon


  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:selected_mode, :left)
     |> assign(:show_modal, false)
     |> assign(:form, to_form(%{"name" => "" , "deck_type" => "tshirt", "custom_deck" => ""}))}
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
    atomized =
    for {k, v} <- params, into: %{} do
      {String.to_atom(k), v}
    end
    {room_status , room_pid} = ElixirPlanningPoker.Room.start_link(atomized)
    IO.inspect(room_status, label: "Room start status")
    IO.inspect(room_pid, label: "Room PID")

    room_state = ElixirPlanningPoker.Room.get_state(room_pid)
    IO.inspect(room_state, label: "Room state after creation")
    room_code = room_state.room_code
    IO.inspect(room_code, label: "Room code after creation")

    {:noreply,
    socket
    |> push_navigate(to: ~p"/rooms/#{room_code}")}

  end

end
