extends Node2D

const player_scene := preload("res://scenes/player.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	add_player(Constants.Team.ONE, Vector2i(-3, 2))
	add_player(Constants.Team.ONE, Vector2i(-3, 0))
	add_player(Constants.Team.ONE, Vector2i(-1, 2))
	add_player(Constants.Team.ONE, Vector2i(-1, 0))
	
	add_player(Constants.Team.TWO, Vector2i(0, -1))
	add_player(Constants.Team.TWO, Vector2i(0, -3))
	add_player(Constants.Team.TWO, Vector2i(2, -1))
	add_player(Constants.Team.TWO, Vector2i(2, -3))

	$TurnState.start_turn(Constants.Team.ONE)

func add_player(team: Constants.Team, tile_position: Vector2i):
	var player := player_scene.instantiate()
	player.team = team
	player.tile_position = tile_position
	%Players.add_child(player)
