defmodule PlanningPokerWeb.RoomConfigModalComponent do
  use PlanningPokerWeb, :live_component

  # props vindas do pai
  # show?: controla visibilidade; deck: valor inicial (edição)
  @impl true
  def update(%{show?: show?, deck: deck} = assigns, socket) do
    socket =
      socket
      |> assign_new(:deck, fn -> deck || "fibonacci" end) # estado interno com default
      |> assign(show?: show?)

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("ignore", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("close_room_config", _params, socket) do
    {:noreply, assign(socket, show?: false)}
  end

  @impl true
  def handle_event("save_room_config", %{"deck" => deck}, socket) do
    # aqui você valida/persist e notifica o pai
    send(self(), {:room_config_saved, %{deck: deck}})
    {:noreply, assign(socket, deck: deck, show?: false)}
  end

  embed_templates "*"
end
