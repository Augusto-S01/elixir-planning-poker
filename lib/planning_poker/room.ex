defmodule PlanningPoker.Room do
  use GenServer

  defstruct deck: [],
            players: [],
            round: 1,
            room: %{deck: [], players: [], round: 1  }


  def initialize_room(deck) do
    %PlanningPoker.Room{deck: deck, players: [], round: 1}

  end
end
