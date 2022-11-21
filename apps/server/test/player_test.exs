defmodule PlayerTest do
  use ExUnit.Case
  doctest Player

  test "creates succesfully" do
    player = Player.start_link(100, :rock)
    world = World.start_link("./data/tests/player_test_1.txt", 4)
    World.add_player(world, player)
    room = Player.get_room(player)

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
    player = Player.start_link(100, :rock)
    world = World.start_link("./data/tests/player_test_2.txt", 4)
    World.add_player(world, player)
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
    player = Player.start_link(100, :rock)
    world = World.start_link("./data/tests/player_test_3.txt", 4)
    World.add_player(world, player)
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
    player = Player.start_link(100, :rock)
    world = World.start_link("./data/tests/player_test_3.txt", 4)
    World.add_player(world, player)
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
    player = Player.start_link(100, :rock)
    world = World.start_link("./data/tests/player_test_4.txt", 4)
    World.add_player(world, player)
    room = Player.get_room(player)

    assert Player.get_room(player) == room

    Player.move(player, "B")

    assert Player.get_room(player) != room
  end

  test "move unsuccesfully" do
    player = Player.start_link(100, :rock)
    world = World.start_link("./data/tests/player_test_3.txt", 4)
    World.add_player(world, player)
    room = Player.get_room(player)

    assert Player.get_room(player) == room

    Player.move(player, "B")

    assert Player.get_room(player) == room
  end

  test "add two players succesfully" do
    player1 = Player.start_link(100, :rock)
    player2 = Player.start_link(100, :rock)
    world = World.start_link("./data/tests/player_test_3.txt", 4)
    World.add_player(world, player1)
    World.add_player(world, player2)
    room1 = Player.get_room(player1)
    room2 = Player.get_room(player2)

    assert room1 == room2

    %{
      players: players
    } = Room.get_state(room1)

    assert length(players) == 2
  end

  test "attack two players succesfully" do
    player1 = Player.start_link(100, :rock)
    player2 = Player.start_link(100, :rock)
    world = World.start_link("./data/tests/player_test_3.txt", 4)
    World.add_player(world, player1)
    World.add_player(world, player2)
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
    player1 = Player.start_link(100, :rock)
    player2 = Player.start_link(100, :rock)
    world = World.start_link("./data/tests/player_test_3.txt", 4)
    World.add_player(world, player1)
    World.add_player(world, player2)
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
    player1 = Player.start_link(100, :rock)
    player2 = Player.start_link(100, :rock)
    world = World.start_link("./data/tests/player_test_3.txt", 4)
    World.add_player(world, player1)
    World.add_player(world, player2)
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
    player1 = Player.start_link(100, :rock)
    player2 = Player.start_link(100, :rock)
    world = World.start_link("./data/tests/player_test_5.txt", 4)
    World.add_player(world, player1)
    World.add_player(world, player2)
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
end
