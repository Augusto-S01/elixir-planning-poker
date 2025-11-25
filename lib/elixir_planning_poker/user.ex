defmodule ElixirPlanningPoker.User do
  @enforce_keys [:user]
  defstruct [:name, :user, :role, :vote, :voted? , :observer?]

  @type t :: %__MODULE__{
          name: String.t(),
          user: String.t(),
          role: :host | :participant | atom(),
          vote: integer() | nil,
          observer?: boolean(),
          voted?: boolean()
        }

  @spec new(String.t(), String.t(), atom()) :: t()
  def new(user_token, name \\ "", role \\ :participant)
      when is_binary(user_token) and is_atom(role) do
      %__MODULE__{user: user_token, name: name, role: role, vote: nil, voted?: false, observer?: false}
  end

  @spec find_user([map()], String.t()) :: {:ok, map()} | {:error, :not_found}
  def find_user(users, user_token) when is_list(users) and is_binary(user_token) do
    case Enum.find(users, fn user ->
           match_user_token?(user, user_token)
         end) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  def is_host?(users, user_token) do
    case find_user(users, user_token) do
      {:ok, %__MODULE__{role: :host}} -> true
      {:ok, _} -> false
      {:error, :not_found} -> false
    end
  end

  def changeset(%__MODULE__{} = user, attrs \\ %{}) do
    {user, %{name: :string}}
    |> Ecto.Changeset.cast(attrs, [:name])
    |> Ecto.Changeset.validate_required([:name])
  end

  def fetch(%__MODULE__{} = user, field) when field in [:name, :user, :role, :vote, :voted?, :observer?] do
    Map.get(user, field)
  end


  def set_vote(%__MODULE__{} = user, vote) do
    %{user | vote: vote, voted?: !is_nil(vote)}
  end

  defp match_user_token?(%__MODULE__{user: token}, user_token), do: token == user_token

  defp match_user_token?(%{user: token}, user_token) when is_binary(token),
    do: token == user_token

  defp match_user_token?(_, _), do: false
end
