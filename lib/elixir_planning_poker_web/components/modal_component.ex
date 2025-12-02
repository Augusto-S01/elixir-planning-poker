defmodule ElixirPlanningPokerWeb.ModalComponent do
  use ElixirPlanningPokerWeb, :html

  attr :show, :boolean, default: false
  attr :title, :string, default: nil
  attr :cancelable, :boolean, default: true
  attr :close_event, :string, default: "close_modal"

  slot :body, required: true
  slot :footer

  def modal(assigns) do
    ~H"""
    <div
      class={[
        "modal fixed inset-0 flex items-center justify-center transition-all duration-200",
        # quando aberto
        @show && "modal-open bg-black/50 backdrop-blur-sm opacity-100 pointer-events-auto",
        # quando fechado
        !@show && "bg-transparent backdrop-blur-0 opacity-0 pointer-events-none"
      ]}
    >
      <div
        class={[
          "modal-box max-w-2xl bg-base-100 text-base-content shadow-xl border border-base-300 relative",
          "transform transition-all duration-200",
          @show && "animate-modal-in",
          !@show && "animate-modal-out"
        ]}
      >
        <%= if @title do %>
          <h3 class="font-bold text-lg mb-4 text-primary">{@title}</h3>
        <% end %>

        <!-- Body slot -->
        <div class="mb-4">
          <%= render_slot(@body) %>
        </div>

        <!-- Footer slot (se nao tiver, mostra nada) -->
        <div :if={@footer != []} class="modal-action">
          <%= render_slot(@footer) %>
        </div>
      </div>

      <button
        :if={@cancelable}
        type="button"
        phx-click={@close_event}
        class="modal-backdrop"
      ></button>
    </div>
    """
  end
end
