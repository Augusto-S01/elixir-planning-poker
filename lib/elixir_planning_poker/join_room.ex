defmodule ElixirPlanningPoker.JoinRoom do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :room_code, :string
  end

  def changeset(data, params \\ %{}) do
    cast(data, params, [:room_code])
  end
end
