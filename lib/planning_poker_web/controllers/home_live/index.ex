defmodule PlanningPokerWeb.HomeLive.Index do
  use PlanningPokerWeb, :live_view

  def mount(_params, _session, socket) do
    socket = socket
    |> assign(show_room_config: false)
    |> assign(deck: "fibonacci")
    |> assign(room_code: "")


    {:ok, socket}
  end

  def handle_event("start_new_session", _, socket) do

    {:noreply,assign(socket, show_room_config: true)}
    #{:noreply, push_navigate(socket, to: ~p"/room/#{get_code()}")}
  end

  def handle_event("go_to_room", %{"room_code" => code}, socket) do
    # Aqui você pode usar o valor do input
    {:noreply, push_navigate(socket, to: ~p"/room/#{code}")}
  end


  def handle_event("show_room_config", _, socket) do
    {:noreply, assign(socket, show_room_config: true)}
  end

  def handle_event("close_room_config", _, socket) do
    {:noreply, assign(socket, show_room_config: false)}
  end

  def handle_event("ignore", _, socket) do
    {:noreply, socket}
  end

  def handle_event("teste",_,socket) do
    IO.inspect("teste")
    {:noreply, socket}
  end

  @impl true
  def handle_info({:room_config_saved, %{deck: deck}}, socket) do
    # aqui você decide: salvar no DB, iniciar sessão, etc.
    {:noreply, assign(socket, deck: deck, show_room_config: false)}
  end

  defp get_code do
    PlanningPoker.RoomTicketDispenser.get_ticket()
  end
end
