defmodule ElixirPlanningPoker.RoomConfig do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :name, :string
    field :deck_type, :string
    field :custom_deck, :string
  end

  def changeset(data, attrs \\ %{}) do
    data
    |> cast(attrs, [:name, :deck_type, :custom_deck])
    |> validate_required([:name, :deck_type])
    |> validate_custom_deck()
  end

  defp validate_custom_deck(changeset) do
    case get_field(changeset, :deck_type) do
      "custom" ->
        changeset
        |> validate_required([:custom_deck])
        |> validate_format(:custom_deck, ~r/^[^,]+(,[^,]+)+$/,  message: "must contain at least two comma-separated values")
      _ ->
        changeset
    end
  end
end
