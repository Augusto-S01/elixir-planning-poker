defmodule ElixirPlanningPokerWeb.Components.RoomConfigModal do
  use Phoenix.Component

  import ElixirPlanningPokerWeb.ModalComponent

  attr :form, :any, required: true
  attr :show, :boolean, required: true


def room_config_modal(assigns) do
  ~H"""
  <.modal show={@show} footer={:form} form_id="room_form" title="Room Configuration">
    <.form for={@form} id="room_form" phx-change="validate" phx-submit="submit" class="space-y-4">
      <div>
        <label class="block text-sm font-medium mb-2">Room Name</label>
        <input type="text" name="room[name]" value={@form[:name].value} class="input input-bordered w-full" required />

        <label class="block text-sm font-medium mb-2 mt-4">Deck Type</label>
        <select name="room[deck_type]" class="select select-bordered w-full" value={@form[:deck_type].value}>
          <option value="fibonacci">Fibonacci</option>
          <option value="tshirt">T-Shirt</option>
          <option value="sequential">Sequential</option>
          <option value="custom">Custom</option>
        </select>

        <%= if @form[:deck_type].value == "custom" do %>
          <label class="block text-sm font-medium mb-2 mt-4">Custom Deck</label>
          <input type="text" name="room[custom_deck]" value={@form[:custom_deck].value} class="input input-bordered w-full" />
        <% end %>
      </div>
    </.form>
  </.modal>
  """
end


end
