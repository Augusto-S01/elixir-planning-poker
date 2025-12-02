defmodule ElixirPlanningPokerWeb.Components.RoomConfigModal do
  use Phoenix.LiveComponent

  import ElixirPlanningPokerWeb.CoreComponents
  import ElixirPlanningPokerWeb.ModalComponent
  alias ElixirPlanningPoker.RoomConfig

  def update(assigns, socket) do
    submit_event = Map.get(assigns, :submit_event, "submit_room_config")
    close_event = Map.get(assigns, :close_event, "close_room_config")

    data = Map.get(assigns, :data, %{})

    changeset =
      socket.assigns[:changeset] ||
        RoomConfig.changeset(%RoomConfig{}, data)
        |> to_form(as: :room_config)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:form, to_form(changeset))
     |> assign(:submit_event, submit_event)
     |> assign(:close_event, close_event)}
  end

  def handle_event("validate", %{"room_config" => params}, socket) do
    changeset =
      socket.assigns.changeset.data
      |> RoomConfig.changeset(params)
      |> Map.put(:action, :validate)

    form = to_form(changeset, as: :room_config)
    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:form, form)}
  end

  def handle_event("internal_submit_room_config", params, socket) do
    params = Map.get(params, "room_config", %{})
    changeset =
      %RoomConfig{}
      |> RoomConfig.changeset(params)

    if changeset.valid? do
      send(self(), {socket.assigns.submit_event, changeset.changes})
    end
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
    <.modal
      show={@show}
      title="Room Configuration"
      cancelable={true}
      close_event={@close_event}
    >

      <:body>
        <.form
          for={@form}
          as={:room_config}
          id="room_form"
          phx-change="validate"
          phx-submit="internal_submit_room_config"
          phx-target={@myself}
          class="space-y-4"
        >
          <.input
            field={@form[:name]}
            type="text"
            label="Room Name"
            placeholder="Enter room name"
          />

          <.input
            field={@form[:deck_type]}
            type="select"
            label="Deck Type"
            options={[
              {"Fibonacci", "fibonacci"},
              {"T-Shirt", "tshirt"},
              {"Sequential", "sequential"},
              {"Custom", "custom"}
            ]}
          />

          <%= if @form[:deck_type].value == "custom" do %>
            <.input
              field={@form[:custom_deck]}
              type="text"
              placeholder="1,2,3,5,8,13"
              label="Custom Deck (comma separated)"
            />
          <% end %>
        </.form>
      </:body>

      <:footer>
        <button type="submit" form="room_form" class="btn btn-primary">
          Save
        </button>

        <button
          type="button"
          phx-click={@close_event}
          class="btn btn-ghost"
        >
          Cancel
        </button>
      </:footer>

    </.modal>
    </div>
    """
  end
end
