class_name RoundRoot

extends Node

signal points_scored(team: Constants.Team, points: int)
signal round_ended(round_root: RoundRoot)

@onready var turn_state: TurnState = %TurnState
@onready var arena_tilemap: ArenaTileMap = %ArenaTileMap
@onready var event_log: EventLog = %EventLog
@onready var players: Players = %Players
@onready var score_state: ScoreState = %ScoreState
@onready var round_over_ui: CanvasLayer = %RoundOverUI

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

func end_round():
	round_over_ui.visible = true

func _on_next_round_button_pressed():
	round_ended.emit(self)
