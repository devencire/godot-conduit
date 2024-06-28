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
	_update_players()

func _player_was_moved(_player: Player):
	_update_players()
	
func _player_is_beacon_changed(_player: Player, is_beacon: bool):
	if is_beacon: # only emit once, for the receiver of the throw
		_update_players()

func _player_status_changed(_player: Player, status: Player.Status):
	_update_players()

# only recalculate once an action has finished all player moves
# (otherwise players can be overlapping or other weird states)
var will_update := false

func _update_players():
	if will_update:
		return
	_perform_update.call_deferred()
	will_update = true

func _perform_update():
	will_update = false
	_set_is_powered_on_players()
	changed.emit(self)

func add_player(team: Constants.Team, tile_position: Vector2i, is_beacon: bool = false):
	var player: Player = player_scene.instantiate()
	player.round_root = round_root
	player.team = team
	player.tile_position = tile_position
	player.is_beacon = is_beacon
	player.was_moved.connect(_player_was_moved)
	player.is_beacon_changed.connect(_player_is_beacon_changed)
	player.status_changed.connect(_player_status_changed)
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

func conscious_players_on_team(team: Constants.Team) -> Array[Player]:
	return all_players.filter(func(player: Player): return player.team == team and player.conscious)

func powered_players_on_team(team: Constants.Team) -> Array[Player]:
	return players_on_team(team).filter(func(player: Player): return player.is_powered)

func _set_is_powered_on_players() -> void:
	for team in [Constants.Team.ONE, Constants.Team.TWO]:
		_set_is_powered_on_players_of_team(team)

func _set_is_powered_on_players_of_team(team: Constants.Team) -> void:
	var team_players := players_on_team(team)
	for player in team_players:
		player.is_powered = player.conscious and player.is_beacon
	var beacon_player := beacon_for_team(team)
	if not beacon_player:
		return
	var newly_powered_players: Array[Player] = [beacon_player]
	while newly_powered_players.size() > 0:
		var casting_player: Player = newly_powered_players.pop_back()
		for player in team_players:
			if player.conscious and not player.is_powered and player.arena_tilemap.are_cells_aligned(player.tile_position, casting_player.tile_position):
				player.is_powered = true
				newly_powered_players.push_back(player)
