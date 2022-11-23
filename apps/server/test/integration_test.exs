defmodule ClientProxyMock do
  def start_link() do
    {_, client} = GenServer.start_link(__MODULE__, :ok)
    client
  end

  def init(:ok) do
    {:ok, :ok}
  end

  def handle_cast({:receive_state, _recv_state}, _state) do
    {:noreply, :ok}
  end
end

defmodule IntegrationTest do
  use ExUnit.Case
  require Logger
  doctest Player

  test "creates succesfully" do
    client = ClientProxyMock.start_link()
    player = Player.start_link("Jugador", 100, :rock, client)
    world = World.start_link("./data/tests/player_test_1.txt", 4)
    room = World.get_first_room(world)
    Room.add_player(room, player)

    %{
      world: _world,
      enemies: enemies,
      players: players,
      turn: _turn,
      turn_order: _turn_order,
      type: _type
    } = Room.get_state(room)

    assert List.first(players) == player
    assert length(enemies) == 0
  end

  test "attack succesfully" do
    client = ClientProxyMock.start_link()
    player = Player.start_link("Jugador", 100, :rock, client)
    world = World.start_link("./data/tests/player_test_2.txt", 4)
    room_ = World.get_first_room(world)
    Room.add_player(room_, player)
    Player.move(player, "B")
    room = Player.get_room(player)

    %{
      enemies: enemies
    } = Room.get_state(room)

    assert length(enemies) == 1
    Player.attack(player, List.first(enemies))

    %{
      enemies: enemies
    } = Room.get_state(room)

    assert length(enemies) == 0
  end

  test "attack and receive damage" do
    # This test works with the assumption that the enemies are rock with 1 hp and attack with 10 amount, and the player attacks with 10 amount
    client = ClientProxyMock.start_link()
    player = Player.start_link("Jugador", 100, :rock, client)
    world = World.start_link("./data/tests/player_test_3.txt", 4)
    room_ = World.get_first_room(world)
    Room.add_player(room_, player)
    Player.move(player, "B")
    room = Player.get_room(player)

    %{
      enemies: enemies
    } = Room.get_state(room)

    assert length(enemies) == 2
    Player.attack(player, List.first(enemies))

    %{
      enemies: enemies
    } = Room.get_state(room)

    # Sleep to wait for the damage to be applied
    :timer.sleep(100)
    assert length(enemies) == 1
    assert Player.get_state(player).health == 90
  end

  test "attack , receive damage and attack again" do
    # This test works with the assumption that the enemies are rock with 1 hp and attack with 10 amount, and the player attacks with 10 amount
    client = ClientProxyMock.start_link()
    player = Player.start_link("Jugador", 100, :rock, client)
    world = World.start_link("./data/tests/player_test_3.txt", 4)
    room_ = World.get_first_room(world)
    Room.add_player(room_, player)
    Player.move(player, "B")
    room = Player.get_room(player)

    %{
      enemies: enemies
    } = Room.get_state(room)

    assert length(enemies) == 2
    Player.attack(player, List.first(enemies))

    %{
      enemies: enemies
    } = Room.get_state(room)

    # Sleep to wait for the damage to be applied
    :timer.sleep(100)
    assert length(enemies) == 1
    assert Player.get_state(player).health == 90
    Player.attack(player, List.first(enemies))

    %{
      enemies: enemies
    } = Room.get_state(room)

    assert length(enemies) == 0
    assert Player.get_state(player).health == 90
  end

  test "move succesfully" do
    client = ClientProxyMock.start_link()
    player = Player.start_link("Jugador", 100, :rock, client)
    world = World.start_link("./data/tests/player_test_4.txt", 4)
    room = World.get_first_room(world)
    Room.add_player(room, player)

    assert Player.get_room(player) == room

    Player.move(player, "B")

    assert Player.get_room(player) != room
  end

  test "move unsuccesfully" do
    client = ClientProxyMock.start_link()
    player = Player.start_link("Jugador", 100, :rock, client)
    world = World.start_link("./data/tests/player_test_6.txt", 4)
    room = World.get_first_room(world)
    Room.add_player(room, player)

    assert Player.get_room(player) == room

    Player.move(player, "B")

    assert Player.get_room(player) == room
  end

  test "add two players succesfully" do
    client = ClientProxyMock.start_link()
    player1 = Player.start_link("Jugador", 100, :rock, client)
    player2 = Player.start_link("Jugador", 100, :rock, client)
    world = World.start_link("./data/tests/player_test_3.txt", 4)
    room_ = World.get_first_room(world)
    Room.add_player(room_, player1)
    Room.add_player(room_, player2)
    Player.move(player1, "B")
    Player.move(player2, "B")
    room1 = Player.get_room(player1)
    room2 = Player.get_room(player2)

    assert room1 == room2

    %{
      players: players
    } = Room.get_state(room1)

    assert length(players) == 2
  end

  test "attack two players succesfully" do
    client = ClientProxyMock.start_link()
    player1 = Player.start_link("Jugador", 100, :rock, client)
    player2 = Player.start_link("Jugador", 100, :rock, client)
    world = World.start_link("./data/tests/player_test_3.txt", 4)
    room_ = World.get_first_room(world)
    Room.add_player(room_, player1)
    Room.add_player(room_, player2)
    Player.move(player1, "B")
    Player.move(player2, "B")
    room1 = Player.get_room(player1)
    room2 = Player.get_room(player2)

    assert room1 == room2

    %{
      enemies: enemies
    } = Room.get_state(room1)

    assert length(enemies) == 2
    Player.attack(player1, List.first(enemies))

    %{
      enemies: enemies
    } = Room.get_state(room1)

    assert length(enemies) == 1

    Player.attack(player2, List.first(enemies))

    %{
      enemies: enemies
    } = Room.get_state(room1)

    assert length(enemies) == 0
  end

  test "second player cant attack before first" do
    client = ClientProxyMock.start_link()
    player1 = Player.start_link("Jugador", 100, :rock, client)
    player2 = Player.start_link("Jugador", 100, :rock, client)
    world = World.start_link("./data/tests/player_test_3.txt", 4)
    room_ = World.get_first_room(world)
    Room.add_player(room_, player1)
    Room.add_player(room_, player2)
    Player.move(player1, "B")
    Player.move(player2, "B")
    room1 = Player.get_room(player1)
    room2 = Player.get_room(player2)

    assert room1 == room2

    %{
      enemies: enemies
    } = Room.get_state(room1)

    assert length(enemies) == 2
    Player.attack(player2, List.first(enemies))

    %{
      enemies: enemies
    } = Room.get_state(room1)

    assert length(enemies) == 2
  end

  test "first player cant attack twice" do
    client = ClientProxyMock.start_link()
    player1 = Player.start_link("Jugador", 100, :rock, client)
    player2 = Player.start_link("Jugador", 100, :rock, client)
    world = World.start_link("./data/tests/player_test_3.txt", 4)
    room_ = World.get_first_room(world)
    Room.add_player(room_, player1)
    Room.add_player(room_, player2)
    Player.move(player1, "B")
    Player.move(player2, "B")
    room1 = Player.get_room(player1)
    room2 = Player.get_room(player2)

    assert room1 == room2

    %{
      enemies: enemies
    } = Room.get_state(room1)

    assert length(enemies) == 2
    Player.attack(player1, List.first(enemies))

    %{
      enemies: enemies
    } = Room.get_state(room1)

    assert length(enemies) == 1
    Player.attack(player1, List.first(enemies))

    %{
      enemies: enemies
    } = Room.get_state(room1)

    assert length(enemies) == 1
  end

  test "attack two players twice" do
    client = ClientProxyMock.start_link()
    player1 = Player.start_link("Jugador", 100, :rock, client)
    player2 = Player.start_link("Jugador", 100, :rock, client)
    world = World.start_link("./data/tests/player_test_5.txt", 4)
    room_ = World.get_first_room(world)
    Room.add_player(room_, player1)
    Room.add_player(room_, player2)
    Player.move(player1, "B")
    Player.move(player2, "B")
    room1 = Player.get_room(player1)
    room2 = Player.get_room(player2)

    assert room1 == room2

    %{
      enemies: enemies
    } = Room.get_state(room1)

    assert length(enemies) == 4
    Player.attack(player1, List.first(enemies))

    %{
      enemies: enemies
    } = Room.get_state(room1)

    assert length(enemies) == 3

    Player.attack(player2, List.first(enemies))

    %{
      enemies: enemies
    } = Room.get_state(room1)

    :timer.sleep(100)
    assert length(enemies) == 2
    assert Player.get_state(player1).health + Player.get_state(player2).health == 180

    Player.attack(player1, List.first(enemies))

    %{
      enemies: enemies
    } = Room.get_state(room1)

    assert length(enemies) == 1

    Player.attack(player2, List.first(enemies))

    %{
      enemies: enemies
    } = Room.get_state(room1)

    assert length(enemies) == 0
  end

  test "move error" do
    client = ClientProxyMock.start_link()
    player = Player.start_link("Jugador", 100, :rock, client)
    world = World.start_link("./data/tests/player_test_6.txt", 4)
    room = World.get_first_room(world)
    Room.add_player(room, player)
    {error, msg} = Player.move(player, "B")
    assert error
    assert msg == "There are enemies in the room"
    {error2, msg2} = Player.move(player, "NADA")
    assert error2
    assert msg2 == "Invalid Direction"
  end

  test "attack error" do
    client = ClientProxyMock.start_link()
    player = Player.start_link("Jugador", 100, :rock, client)
    world = World.start_link("./data/tests/player_test_3.txt", 4)
    room = World.get_first_room(world)
    Room.add_player(room, player)

    {error, msg} = Player.attack(player, "Nada")
    assert error
    assert msg == "Invalid Attack"

    %{enemies: enemies} = Room.get_state(room)
    {error2, msg2} = Room.attack(room, "Nada", List.first(enemies), 10, :rock)
    assert error2
    assert msg2 == "Invalid Attack"
  end

  test "attack turn error" do
    client = ClientProxyMock.start_link()
    player1 = Player.start_link("Jugador", 100, :rock, client)
    player2 = Player.start_link("Jugador", 100, :rock, client)
    world = World.start_link("./data/tests/player_test_5.txt", 4)
    room_ = World.get_first_room(world)
    Room.add_player(room_, player1)
    Room.add_player(room_, player2)
    Player.move(player1, "B")
    Player.move(player2, "B")
    room = Player.get_room(player1)
    %{enemies: enemies} = Room.get_state(room)

    {error, msg} = Player.attack(player2, List.first(enemies))
    assert error
    assert msg == "Its not your turn"
  end
end
