import Config

config :server,
  world_max_players: 3,
  world_file: "./data/world_0.txt",
  session_max_players: 5

config :entities,
  player_health: 100,
  bandido: {"Bandido", 10, 20},
  automata: {"Automata", 15, 25},
  renacido: {"Renacido", 30, 50},
  vges_gis: {"Vges-Gis", 50, 80},
  goblin: {"Goblin", 10, 20}

config :client,
  server_name: :server@localhost,
  time_to_draw: 1500
