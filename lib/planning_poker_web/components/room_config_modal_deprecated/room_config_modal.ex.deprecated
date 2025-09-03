defmodule PlanningPokerWeb.RoomConfigModal do
  use PlanningPokerWeb, :html

  attr :show?, :boolean, required: true
  attr :deck, :string, default: "fibonacci"
  attr :on_close, :any, default: "close_room_config"
  attr :on_save, :any, default: "save_room_config"
  # wrapper que recebe attrs e chama o template embutido
  def room_config_modal(assigns) do
    room_config_modal_html(assigns)
  end
  # procura por room_config_modal/*.heex OU pelo arquivo nesta pasta
  embed_templates "*"
  # se o .heex estiver na mesma pasta do .ex, você pode usar:
  # embed_templates "*"
end
