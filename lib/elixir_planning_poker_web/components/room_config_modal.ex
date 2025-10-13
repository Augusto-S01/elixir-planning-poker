defmodule ElixirPlanningPokerWeb.Components.RoomConfigModal do
  use Phoenix.Component
  alias ElixirPlanningPokerWeb.Components.Icon

  attr :form, :any, required: true


  def room_config_modal(assigns) do
    ~H"""
    <div id="room-config-modal" class="modal modal-open">
      <div class="modal-box max-w-3xl">
        <h3 class="font-bold text-lg mb-4">Room Configuration</h3>

        <.form for={@form} phx-change="validate" phx-submit="submit" class="space-y-4">
          <div>
            <label for="room_name" class="block text-sm font-medium mb-2">
              Room Name
            </label>
            <input type="text" name="room[name]" id="room_name"
                   value={@form[:name].value} class="input input-bordered w-full" required />
            <label for="room_deck_type" class="block text-sm font-medium mb-2 mt-4">
              Deck Type
            </label>
            <select value={@form[:deck_type].value} name="room[deck_type]" id="room_deck_type" class="select select-bordered w-full">

              <option value="fibonacci" selected={@form[:deck_type].value == "fibonacci"}>Fibonacci (0, 1/2, 1, 2, 3, 5, 8, ...)</option>
              <option value="tshirt" selected={@form[:deck_type].value == "tshirt"}>T-Shirt Sizes (XS, S, M, L, XL)</option>
              <option value="sequential" selected={@form[:deck_type].value == "sequential"}>Sequential Numbers (1, 2, 3, ...)</option>
              <option value="custom" selected={@form[:deck_type].value == "custom"}>Custom</option>
            </select>

            <%= if @form[:deck_type].value == "custom" do %>
              <label for="room_custom_deck" class="block text-sm font-medium mb-2 mt-4">
                Custom Deck (comma-separated values)
              </label>
              <input type="text" name="room[custom_deck]" id="room_custom_deck"
                     value={@form[:custom_deck].value} class="input input-bordered w-full" />
            <% end %>


            <p class="mt-2 text-sm text-red-600">
              <%= Enum.join(Keyword.get_values(@form.errors, :name), ", ") %>
            </p>
          </div>

          <div class="flex justify-end space-x-2 mt-4">
            <button type="button" class="btn btn-outline" phx-click="close_modal">
              <Icon.icon name="arrow_left_icon" class="inline-block w-4 h-4 mr-1" />
              Cancel
            </button>
            <button type="submit" class="btn btn-primary">
              <Icon.icon name="hashtag_icon" class="inline-block w-4 h-4 mr-1" />
              Save
            </button>
          </div>
        </.form>
      </div>
    </div>
    """
  end
end
