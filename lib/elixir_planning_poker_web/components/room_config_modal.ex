defmodule ElixirPlanningPokerWeb.Components.RoomConfigModal do
  use Phoenix.Component

  import ElixirPlanningPokerWeb.CoreComponents
  import ElixirPlanningPokerWeb.ModalComponent

  attr :form, :any, required: true
  attr :show, :boolean, required: true
  attr :close_event, :string, required: true
  attr :submit_event, :string, default: "submit"
  attr :validate_event, :string, default: "validate"



def room_config_modal(assigns) do
  ~H"""
  <.modal show={@show} footer={:form}  form_id="room_form" title="Room Configuration" close_event={@close_event}>
    <.form for={@form} id="room_form" phx-change="teste" phx-submit={@submit_event} class="space-y-4">
      <div>
        <.input
          type="text"
          field={@form[:name]}
          value={@form[:name].value}
          required
          label="Room Name"
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


        <%= if @form[:deck_type].value == "custom"  do %>
          <.input
            type="text"
            field={@form[:custom_deck]}
            value={@form[:custom_deck].value}
            placeholder="1,2,3,5,8,13"
            label="Custom Deck (Comma separated values)"
            />

        <% end %>
      </div>
    </.form>
  </.modal>
  """
end

def handle_event("teste", params, socket) do
  IO.inspect(params, label: "Room config params")
  {:noreply, socket}
end




end
