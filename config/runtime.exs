import Config

config :server,
  world_max_players: 3,
  world_file: "./data/world_0.txt",
  max_clients: 5

config :entities,
  player_health: 100,
  outskirts: {"Bandido", 10, 20},
  trap: {"Automata", 15, 25},
  tomb: {"Renacido", 30, 50},
  boss: {"Ferrigneo", 50, 80},
  other: {"Goblin", 10, 20}

config :client,
  server_name: :server@localhost,
  time_to_draw: 1500
