defmodule ElixirPlanningPoker.User do
  @enforce_keys [:user]
  defstruct [:name, :user, :role, :vote, :voted? , :observer?, :icon]
  import Ecto.Changeset
  @icon_profile_options ["axolotl","cat","dog","donkey","elephant","owl","penguin","platypus","reindeer","tiger"]

  @type t :: %__MODULE__{
          name: String.t(),
          user: String.t(),
          icon: String.t(),
          role: :host | :participant | atom(),
          vote: integer() | nil,
          observer?: boolean(),
          voted?: boolean(),
        }

  @spec icon_profile_options() :: [String.t()]
  def icon_profile_options, do: @icon_profile_options

  @spec new(String.t(), String.t(), atom()) :: t()
  def new(user_token, name \\ "", role \\ :participant)
      when is_binary(user_token) and is_atom(role) do
      %__MODULE__{user: user_token, name: name, role: role, vote: nil, voted?: false, observer?: false, icon: random_icon()}
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

  defp random_icon do
    Enum.random(@icon_profile_options)
  end

  def get_user_icon(users, user_token) do
    case find_user(users, user_token) do
      {:ok, %__MODULE__{icon: icon}} -> icon
      {:ok, %{} = user} -> Map.get(user, :icon, "cat")
      {:error, :not_found} -> "cat"
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
    {user, %{name: :string, icon: :string}}
    |> cast(attrs, [:name, :icon])
    |> validate_required([:name])
    |> validate_length(:name, min: 2)
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
