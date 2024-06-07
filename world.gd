class_name MatchRoot

extends Node2D

@onready var turn_state: TurnState = $TurnState
@onready var arena_tilemap: ArenaTileMap = $ArenaTileMap
@onready var event_log: EventLog = $EventLog
@onready var players: Players = %Players

# Called when the node enters the scene tree for the first time.
func _ready():
	players.add_player(Constants.Team.ONE, Vector2i(-3, 2), true)
	players.add_player(Constants.Team.ONE, Vector2i(-3, 0))
	players.add_player(Constants.Team.ONE, Vector2i(-1, 2))
	players.add_player(Constants.Team.ONE, Vector2i(-1, 0))
	
	players.add_player(Constants.Team.TWO, Vector2i(0, -1))
	players.add_player(Constants.Team.TWO, Vector2i(0, -3))
	players.add_player(Constants.Team.TWO, Vector2i(2, -1))
	players.add_player(Constants.Team.TWO, Vector2i(2, -3), true)

	turn_state.start_turn(Constants.Team.ONE)
