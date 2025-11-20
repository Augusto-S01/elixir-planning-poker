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
    <.form for={@form} id="room_form" phx-change={@validate_event} phx-submit={@submit_event} class="space-y-4">
      <div>
        <label phx-click="teste" class="block text-sm font-medium mb-2">Room Name</label>
        <input type="text" name="room[name]" value={@form[:name].value} class="input input-bordered w-full" required />

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
          <label class="block text-sm font-medium mb-2 mt-4">Custom Deck</label>
          <input type="text" name="room[custom_deck]" value={@form[:custom_deck].value} class="input input-bordered w-full" />
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
