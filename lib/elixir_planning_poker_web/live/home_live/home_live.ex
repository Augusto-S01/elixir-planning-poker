defmodule ElixirPlanningPokerWeb.HomeLive do
  use ElixirPlanningPokerWeb, :live_view

  import ElixirPlanningPokerWeb.Components.Swiper
  import ElixirPlanningPokerWeb.Components.RoomConfigModal
  import ElixirPlanningPokerWeb.ModalComponent
  alias ElixirPlanningPokerWeb.Components.Icon

  def mount(_params, session, socket) do
    IO.inspect(session, label: "HomeLive session")
    IO.inspect(socket, label: "HomeLive socket")

    {:ok,
     socket
     |> assign(:user_token, session["user_token"])
     |> assign(:selected_mode, :left)
     |> assign(:show_modal, false)
     |> assign(:form, to_form(%{"name" => "", "deck_type" => "tshirt", "custom_deck" => ""}))}
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
    room_params =
      params
      |> Enum.into(%{}, fn {k, v} -> {String.to_atom(k), v} end)
      |> Map.put(:users, [%{:user => socket.assigns.user_token, :role => :host, name: params["user_name"] || ""}])
      |> Map.put_new(:room_code, generate_room_code())

    case ElixirPlanningPoker.RoomManager.start_or_get(room_params) do
      {:ok, _pid} ->
        {:noreply, push_navigate(socket, to: ~p"/rooms/#{room_params.room_code}")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Não foi possível criar a sala: #{inspect(reason)}")}
    end
  end

  def handle_event("ignore_click", _params, socket) do
    {:noreply, socket}
  end

  defp generate_room_code do
    :crypto.strong_rand_bytes(3) |> Base.url_encode64() |> binary_part(0, 4)
  end
end
