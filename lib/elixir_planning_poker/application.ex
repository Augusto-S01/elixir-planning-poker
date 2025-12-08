defmodule ElixirPlanningPoker.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ElixirPlanningPokerWeb.Telemetry,
      # ElixirPlanningPoker.Repo,

      {DNSCluster, query: Application.get_env(:elixir_planning_poker, :dns_cluster_query) || :ignore},
      {Registry, keys: :unique, name: ElixirPlanningPoker.RoomRegistry},
      {Phoenix.PubSub, name: ElixirPlanningPoker.PubSub},
      {DynamicSupervisor, strategy: :one_for_one, name: ElixirPlanningPoker.RoomSupervisor},
      ElixirPlanningPokerWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: ElixirPlanningPoker.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    ElixirPlanningPokerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
