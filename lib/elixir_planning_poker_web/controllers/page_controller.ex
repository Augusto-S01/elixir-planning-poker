defmodule ElixirPlanningPokerWeb.PageController do
  use ElixirPlanningPokerWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
