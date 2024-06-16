class_name MatchRoot

extends Node

signal changed(match_root: MatchRoot)

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
