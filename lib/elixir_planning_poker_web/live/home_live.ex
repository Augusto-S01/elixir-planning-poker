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
  IO.inspect(room_params, label: "Validating form with room_params")
  form = to_form(room_params, as: :room)
  IO.inspect(form, label: "Form after validation")

  {:noreply, assign(socket, :form, form)}
end

  def handle_event("save", %{"room" => params}, socket) do
    IO.inspect(params, label: "Room config submitted")
    {:noreply, assign(socket, :show_modal, false)}
  end

end
