class_name PoweredTiles

extends Node

@onready var arena_tilemap: ArenaTileMap = %ArenaTileMap
@onready var players: Players = %Players
@onready var turn_state: TurnState = %TurnState

@onready var team_one_power_lines: TileMap = $TeamOnePowerLines
@onready var team_two_power_lines: TileMap = $TeamTwoPowerLines

var powered_tile_scene := preload("res://scenes/powered_tile.tscn")
var powered_tile_container: Node2D

var pulse_tween: Tween

func _on_players_changed(_players: Players):
	_set_powered_tiles()

func _on_turn_state_new_turn_started(_state: TurnState):
	_set_powered_tiles()

func _set_powered_tiles():
	if not is_inside_tree():
		return
	
	for team in [Constants.Team.ONE, Constants.Team.TWO]:
		_set_powered_tiles_for_team(team)

const POWER_LINES_SOURCE := 1
const ATLAS_COORDS_FOR_DIRECTION := {
	TileSet.CELL_NEIGHBOR_TOP_SIDE: Vector2(0, 0),
	TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE: Vector2(1, 0),
	TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE: Vector2(2, 0),
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE: Vector2(0, 0),
	TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE: Vector2(1, 0),
	TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE: Vector2(2, 0),
}
const ATLAS_COORDS_FOR_ORIGIN := Vector2i(3, 0)

func _set_powered_tiles_for_team(team: Constants.Team) -> void:
	var power_lines_map: TileMap
	
	if team == Constants.Team.ONE:
		power_lines_map = team_one_power_lines
	else:
		power_lines_map = team_two_power_lines
	
	power_lines_map.clear()
	power_lines_map.modulate = Constants.team_color(team)
	
	var beacon_player := players.beacon_for_team(team)
	if not beacon_player:
		return
	var aligned_cells_by_direction := arena_tilemap.get_aligned_cells_by_direction(beacon_player.tile_position)
	for direction in aligned_cells_by_direction:
		var atlas_coords: Vector2i = ATLAS_COORDS_FOR_DIRECTION[direction]
		var aligned_cells: Array[Vector2i] = aligned_cells_by_direction[direction]
		for cell in aligned_cells:
			power_lines_map.set_cell(0, cell, POWER_LINES_SOURCE, atlas_coords)
	power_lines_map.set_cell(0, beacon_player.tile_position, POWER_LINES_SOURCE, ATLAS_COORDS_FOR_ORIGIN)
	
	var team_color := Constants.team_color(team)
	if team == turn_state.active_team:
		# move in front of the other power line
		move_child(power_lines_map, 1)
		
		power_lines_map.modulate = team_color
		
		if pulse_tween:
			pulse_tween.kill() # I hope this means it gets freed
		pulse_tween = create_tween()
		pulse_tween.tween_property(power_lines_map, 'modulate', Color(team_color, 0.6), 1).set_trans(Tween.TRANS_BOUNCE)
		pulse_tween.tween_property(power_lines_map, 'modulate', team_color, 1).set_trans(Tween.TRANS_BOUNCE)
		pulse_tween.set_loops()
	else:
		power_lines_map.modulate = Color(team_color, 0.6)
