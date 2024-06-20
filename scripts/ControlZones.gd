class_name ControlZones

extends Node2D

@onready var arena_tilemap: ArenaTileMap = %ArenaTileMap
@onready var players: Players = %Players
@onready var turn_state: TurnState = %TurnState

@onready var team_one_zones: TileMap = $TeamOneZones
@onready var team_two_zones: TileMap = $TeamTwoZones

func _on_players_changed(_players: Players) -> void:
	_set_control_zones()

func _on_turn_state_new_turn_started(_state: TurnState) -> void:
	_set_control_zones()

func _set_control_zones() -> void:
	if not is_inside_tree():
		return
	
	for team in [Constants.Team.ONE, Constants.Team.TWO]:
		_set_control_zones_for_team(team)

const ZONE_SOURCE := 1
const ATLAS_COORDS_FOR_ZONE := Vector2i(0, 1)

func _zones_map_for_team(team: Constants.Team) -> TileMap:
	if team == Constants.Team.ONE:
		return team_one_zones
	return team_two_zones

func _set_control_zones_for_team(team: Constants.Team) -> void:
	var zones_map := _zones_map_for_team(team)
	zones_map.clear()
	
	var powered_players := players.powered_players_on_team(team)
	for player in powered_players:
		var zone_cells_by_direction := arena_tilemap.get_aligned_cells_at_range(player.tile_position, 1)
		var zone_cells = zone_cells_by_direction.values()
		zone_cells.push_back(player.tile_position)
		for cell: Vector2i in zone_cells:
			zones_map.set_cell(0, cell, ZONE_SOURCE, ATLAS_COORDS_FOR_ZONE)
	
	zones_map.modulate = Constants.team_zone_color(team)
	if team == turn_state.active_team:
		zones_map.modulate.a *= 0.8
	else:
		move_child(zones_map, 1)
		
func cell_controlled_by_team(cell: Vector2i, team: Constants.Team) -> bool:
	var zones_map := _zones_map_for_team(team)
	return zones_map.get_cell_source_id(0, cell) != -1
