defmodule ElixirPlanningPokerWeb.ModalComponent do
  use ElixirPlanningPokerWeb, :html

  attr :show, :boolean, default: false
  attr :title, :string, default: nil
  slot :inner_block, required: true
  attr :form_id, :string, default: nil
  attr :cancelable, :boolean, default: true
  attr :close_event, :string, default: "close_modal"
  attr :footer, :atom, default: :default

  def modal(assigns) do
    ~H"""
    <div
      :if={@show}
      class="modal modal-open bg-black/50 backdrop-blur-sm"
    >
      <div
        class="modal-box max-w-2xl bg-base-100 text-base-content shadow-2xl border border-base-300 relative"
      >
        <%= if @title do %>
          <h3 class="font-bold text-lg mb-4 text-primary">{@title}</h3>
        <% end %>

        {render_slot(@inner_block)}

        {footer_render(assigns)}
      </div>

      <button
        :if={@cancelable}
        type="button"
        phx-click={@close_event}
        class="modal-backdrop"
      >
      </button>
    </div>
    """
  end


  defp footer_render(assigns) do
    case assigns.footer do
      :default ->
        ~H"""
        <div class="modal-action">
          <button type="button" phx-click={@close_event} class="btn btn-outline">Close</button>
        </div>
        """

      :form ->
        ~H"""
        <div class="modal-action">
          <button type="submit" form={@form_id} class="btn btn-primary">Submit</button>
          <%= if @cancelable do %>
            <button type="button" phx-click={@close_event} class="btn btn-outline">Cancel</button>
          <% end %>
        </div>
        """

      _ ->
        ~H"""
        <div class="modal-action"></div>
        """
    end
  end
end
