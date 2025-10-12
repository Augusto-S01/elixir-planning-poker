defmodule ElixirPlanningPokerWeb.Components.Icon do
  use Phoenix.Component

  attr :name, :string, required: true
  attr :class, :string, default: "w-6 h-6"

  def icon(assigns) do
    ~H"""
    <%= case @name do %>
      <% "naipe" -> %>
        <.naipe_icon class={@class} />
      <% "people_icon" -> %>
        <.people_icon class={@class} />
      <% "arrow_left_icon" -> %>
        <.arrow_left_icon class={@class} />
      <% "hashtag_icon" -> %>
        <.hashtag_icon class={@class} />
      <% _ -> %>
        <svg xmlns="http://www.w3.org/2000/svg" class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.5v15m7.5-7.5h-15" />
        </svg>
    <% end %>
    """
  end

  def naipe_icon(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg"
     viewBox="0 0 24 24" fill="none" stroke="currentColor"
     stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
     class={["lucide lucide-spade", @class]} aria-hidden="true">
     <path d="M12 18v4"></path>
     <path d="M2 14.499a5.5 5.5 0 0 0 9.591 3.675.6.6 0 0 1 .818.001A5.5 5.5 0 0 0 22 14.5c0-2.29-1.5-4-3-5.5l-5.492-5.312a2 2 0 0 0-3-.02L5 8.999c-1.5 1.5-3 3.2-3 5.5"></path>
    </svg>
    """
  end

  def people_icon(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
     fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
     class={["lucide lucide-users", @class]} aria-hidden="true">
      <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path>
      <path d="M16 3.128a4 4 0 0 1 0 7.744"></path>
      <path d="M22 21v-2a4 4 0 0 0-3-3.87"></path>
      <circle cx="9" cy="7" r="4"></circle>
    </svg>
    """
  end

  def arrow_left_icon(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
     fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
     class={["lucide lucide-arrow-right", @class]} aria-hidden="true">
      <path d="M5 12h14"></path>
      <path d="m12 5 7 7-7 7"></path>
    </svg>
    """
  end

  def hashtag_icon(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
     fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
     class={["lucide lucide-hash", @class]} aria-hidden="true">
      <line x1="4" x2="20" y1="9" y2="9"></line>
      <line x1="4" x2="20" y1="15" y2="15"></line>
      <line x1="10" x2="8" y1="3" y2="21"></line>
      <line x1="16" x2="14" y1="3" y2="21"></line>
    </svg>
    """
  end
end
