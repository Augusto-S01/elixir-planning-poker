defmodule ElixirPlanningPoker.Repo do
  use Ecto.Repo,
    otp_app: :elixir_planning_poker,
    adapter: Ecto.Adapters.Postgres
end
