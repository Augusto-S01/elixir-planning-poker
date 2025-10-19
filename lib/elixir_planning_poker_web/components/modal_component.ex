defmodule ElixirPlanningPokerWeb.ModalComponent do
  use ElixirPlanningPokerWeb, :html

  attr :show, :boolean, default: false
  attr :title, :string, default: nil
  slot :inner_block, required: true
  attr :form_id, :string, default: nil
  attr :footer, :atom, default: :default

  def modal(assigns) do
    ~H"""
    <div
      :if={@show}
      class="modal modal-open bg-black/50 backdrop-blur-sm"
      phx-click="close_modal"
    >
      <div
        class="modal-box max-w-2xl bg-base-100 text-base-content shadow-2xl border border-base-300 relative"
        phx-click="ignore_click"
      >
        <%= if @title do %>
          <h3 class="font-bold text-lg mb-4 text-primary">{@title}</h3>
        <% end %>

    <!-- corpo (inner_block padrão) -->
        {render_slot(@inner_block)}

    <!-- footer opcional -->
        {footer_render(assigns)}
      </div>
    </div>
    """
  end

  defp footer_render(assigns) do
    case assigns.footer do
      :default ->
        ~H"""
        <div class="modal-action">
          <button type="button" phx-click="close_modal" class="btn btn-outline">Close</button>
        </div>
        """

      :form ->
        ~H"""
        <div class="modal-action">
          <button type="submit" form={@form_id} class="btn btn-primary">Submit</button>
          <button type="button" phx-click="close_modal" class="btn btn-outline">Cancel</button>
        </div>
        """

      _ ->
        ~H"""
        <div class="modal-action"></div>
        """
    end
  end
end
