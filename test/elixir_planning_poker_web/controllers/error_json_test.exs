defmodule ElixirPlanningPokerWeb.ErrorJSONTest do
  use ElixirPlanningPokerWeb.ConnCase, async: true

  test "renders 404" do
    assert ElixirPlanningPokerWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert ElixirPlanningPokerWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
