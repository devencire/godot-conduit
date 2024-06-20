class_name Players

extends Node

@export var round_root: RoundRoot

const player_scene := preload("res://scenes/player.tscn")

signal changed(players: Players)

var all_players: Array[Player]:
	get:
		var players: Array[Player] = []
		for player in get_children():
			players.append(player)
		return players

func _on_child_order_changed():
	changed.emit(self)

func _player_was_moved(_player: Player):
	changed.emit(self)
	
func _player_is_beacon_changed(_player: Player, is_beacon: bool):
	if is_beacon: # only emit once, for the receiver of the throw
		print('emitting changed after the throw')
		changed.emit(self)

func add_player(team: Constants.Team, tile_position: Vector2i, is_beacon: bool = false):
	var player: Player = player_scene.instantiate()
	player.round_root = round_root
	player.team = team
	player.tile_position = tile_position
	player.is_beacon = is_beacon
	player.was_moved.connect(_player_was_moved)
	player.is_beacon_changed.connect(_player_is_beacon_changed)
	add_child(player)

func player_in_cell(cell: Vector2i, team: Constants.Team = Constants.Team.NONE) -> Player:
	for player in all_players:
		if team and player.team != team:
			continue
		if player.tile_position == cell:
			return player
	return null

func beacon_for_team(team: Constants.Team) -> Player:
	for player in all_players:
		if player.team == team and player.is_beacon:
			return player
	return null # this shouldn't happen

func players_on_team(team: Constants.Team) -> Array[Player]:
	return all_players.filter(func(player: Player): return player.team == team)

func powered_players_on_team(team: Constants.Team) -> Array[Player]:
	return players_on_team(team).filter(func(player: Player): return player.is_powered)
