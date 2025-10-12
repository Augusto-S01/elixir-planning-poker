defmodule ElixirPlanningPokerWeb.Components.Swiper do
  use Phoenix.Component

  alias ElixirPlanningPokerWeb.Components.Icon

  attr :left_label, :string, required: true
  attr :left_icon, :string, required: true
  attr :right_label, :string, required: true
  attr :right_icon, :string, required: true
  attr :selected, :atom, default: :left
  attr :phx_target, :any, default: nil

  def swiper(assigns) do
    ~H"""
    <div class="flex justify-center mt-6">
      <div class="join shadow-lg rounded-lg overflow-hidden">
        <button
          type="button"
          phx-click="swiper_toggle"
          phx-value-selected="left"
          phx-target={@phx_target}
          class={[
            "join-item flex items-center gap-2 px-6 py-3 font-semibold transition-colors duration-200 transition-transform duration-200 active:scale-95 ",
            if(@selected == :left,
              do: "bg-primary text-primary-content",
              else: "bg-base-200 text-base-content hover:bg-base-300"
            )
          ]}
        >
          <Icon.icon name={@left_icon} class="w-5 h-5" />
          <%= @left_label %>
        </button>

        <button
          type="button"
          phx-click="swiper_toggle"
          phx-value-selected="right"
          phx-target={@phx_target}
          class={[
            "join-item flex items-center gap-2 px-6 py-3 font-semibold transition-colors duration-200 transition-transform duration-200 active:scale-95",
            if(@selected == :right,
              do: "bg-primary text-primary-content",
              else: "bg-base-200 text-base-content hover:bg-base-300"
            )
          ]}
        >
          <Icon.icon name={@right_icon} class="w-5 h-5" />
          <%= @right_label %>
        </button>
      </div>
    </div>
    """
  end
end
