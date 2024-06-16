class_name ScoreState

extends Node

signal changed(score_state: ScoreState)

@export var match_root: MatchRoot
@export var event_log: EventLog
@export var travel_scores = {Constants.Team.ONE: 0, Constants.Team.TWO: 0} # Dictionary[Constants.Team, int]


func _on_players_changed(players: Players):
	for team in [Constants.Team.ONE, Constants.Team.TWO]:
		check_for_travel_scoring(team, players.beacon_for_team(team))

func check_for_travel_scoring(team: Constants.Team, beacon_player: Player):
	if not beacon_player:
		return
	var scoring_direction := 1 if team == Constants.Team.ONE else -1
	var progress := beacon_player.arena_tilemap.distance_from_halfway_line(beacon_player.tile_position) * scoring_direction
	var new_progress: int = progress - travel_scores[team]
	if new_progress > 0:
		score_points(team, new_progress)
		travel_scores[team] += new_progress

func score_points(team: Constants.Team, points: int):
	match_root.score_points(team, points)
	event_log.log.call_deferred('[b]%s scored %s points![/b]' % [BB.team_name(team), points])
	changed.emit(self)
