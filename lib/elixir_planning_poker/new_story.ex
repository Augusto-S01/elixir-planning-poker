defmodule ElixirPlanningPoker.NewStory do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :title, :string
    field :description, :string
  end

  def changeset(data, attrs \\ %{}) do
    data
    |> cast(attrs, [:title, :description])
    |> validate_required([:title])
  end


end
