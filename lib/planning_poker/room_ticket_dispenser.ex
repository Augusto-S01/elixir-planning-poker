defmodule PlanningPoker.RoomTicketDispenser do
 use GenServer

 # Client API

  def start_link(opts \\ []) do
    IO.inspect("Starting RoomTicketDispenser")
    opts = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, %{}, opts)
  end


  def get_ticket() do
    IO.inspect("Getting ticket")
    GenServer.call(__MODULE__, :get_ticket)
  end

  # Server (callbacks)
  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(:get_ticket, _from, state) do
    {:reply, generate_room_code(), state}
  end


  # Helper functions
  defp generate_room_code() do
    :crypto.strong_rand_bytes(4) |> Base.encode16() |> binary_part(0, 4)
  end

end
