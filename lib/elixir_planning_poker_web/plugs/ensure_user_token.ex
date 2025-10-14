defmodule ElixirPlanningPokerWeb.Plugs.EnsureUserToken do
  import Plug.Conn
  alias Ecto.UUID

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :user_token) do
      nil ->
        token = UUID.generate()
        put_session(conn, :user_token, token)
      _token ->
        conn
    end
  end
end
