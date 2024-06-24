class_name MatchRoot

extends Node

signal changed(match_root: MatchRoot)

const round_root_scene := preload("res://scenes/round_root.tscn")

@export var team_one_score := 0
@export var team_two_score := 0

func score_points(team: Constants.Team, points: int) -> void:
	if team == Constants.Team.ONE:
		team_one_score += points
	else:
		team_two_score += points
	changed.emit(self)

func _ready():
	(func(): changed.emit(self)).call_deferred()
	start_new_round()

func _on_round_root_points_scored(team: Constants.Team, points: int):
	score_points(team, points)

func _on_round_root_next_round_requested(round_root: RoundRoot):
	round_root.queue_free()
	start_new_round.call_deferred()

func start_new_round():
	var round_root: RoundRoot = round_root_scene.instantiate()
	round_root.points_scored.connect(_on_round_root_points_scored)
	round_root.next_round_requested.connect(_on_round_root_next_round_requested)
	add_child(round_root)
