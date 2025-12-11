########################################
# 1. BUILD STAGE (Debian)
########################################
FROM hexpm/elixir:1.18.0-erlang-25.3.2.10-debian-bullseye-20251117 AS build

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    npm \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY mix.exs mix.lock ./
COPY config config

RUN mix local.hex --force && \
    mix local.rebar --force

RUN mix deps.get --only prod
RUN mix deps.compile

COPY . .

RUN MIX_ENV=prod mix assets.deploy

RUN MIX_ENV=prod mix compile
RUN MIX_ENV=prod mix release


########################################
# 2. RUN STAGE (Debian)
########################################
FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    openssl \
    libncurses5 \
    libstdc++6 \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /app/_build/prod/rel/elixir_planning_poker ./

ENV HOME=/app \
    MIX_ENV=prod \
    PORT=4000 \
    PHX_SERVER=true

EXPOSE 4000

CMD ["bin/elixir_planning_poker", "start"]
