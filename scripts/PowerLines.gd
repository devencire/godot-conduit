class_name PowerLines

extends Node2D

var tilemap_layer_scene := preload("res://scenes/power_line_tile_map_layer.tscn")

@onready var arena_tilemap: ArenaTileMap = %ArenaTileMap
@onready var players: Players = %Players
@onready var turn_state: TurnState = %TurnState

class TeamLayersRef:
	var active: Dictionary # Dictionary[TileSet.CellNeighbor, TileMapLayer]
	var inactive: Dictionary # Dictionary[TileSet.CellNeighbor, TileMapLayer]

var team_one: TeamLayersRef
var team_two: TeamLayersRef

const ATLAS_COORDS_FOR_DIRECTION := {
	TileSet.CELL_NEIGHBOR_TOP_SIDE: Vector2(0, 0),
	TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE: Vector2(1, 0),
	TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE: Vector2(2, 1),
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE: Vector2(0, 1),
	TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE: Vector2(1, 1),
	TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE: Vector2(2, 0),
}

const OPPOSITE_DIRECTION := {
	TileSet.CELL_NEIGHBOR_TOP_SIDE: TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE: TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE: TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE: TileSet.CELL_NEIGHBOR_TOP_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE: TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE: TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE,
}

func _ready() -> void:
	team_one = _instantiate_team_layers(Constants.Team.ONE, $TeamOne)
	team_two = _instantiate_team_layers(Constants.Team.TWO, $TeamTwo)
	
func _instantiate_team_layers(team: Constants.Team, team_root: Node2D) -> TeamLayersRef:
	team_root.modulate = Constants.team_color(team)
	var ref := TeamLayersRef.new()
	ref.active = {}
	ref.inactive = {}
	for direction in ATLAS_COORDS_FOR_DIRECTION:
		ref.active[direction] = _instantiate_tile_map_layer(team_root.find_child("Active"))
		ref.inactive[direction] = _instantiate_tile_map_layer(team_root.find_child("Inactive"))
	return ref

func _instantiate_tile_map_layer(parent: Node2D) -> TileMapLayer:
	var layer: TileMapLayer = tilemap_layer_scene.instantiate()
	parent.add_child(layer)
	return layer

func _set_power_lines() -> void:
	_set_power_lines_for_team(Constants.Team.ONE, team_one)
	_set_power_lines_for_team(Constants.Team.TWO, team_two)

func _set_power_lines_for_team(team: Constants.Team, ref: TeamLayersRef) -> void:
	for direction in ref.active:
		ref.active[direction].clear()
		ref.inactive[direction].clear()
	
	for player in players.powered_players_on_team(team):
		_flood_active_power_lines_from_player(player, ref)
		_set_inactive_power_lines_from_player(player, ref)

func _flood_active_power_lines_from_player(casting_player: Player, ref: TeamLayersRef) -> void:
	for player in players.powered_players_on_team(casting_player.team):
		if player != casting_player and arena_tilemap.are_cells_aligned(casting_player.tile_position, player.tile_position):
			var direction := arena_tilemap.direction_of_cell(casting_player.tile_position, player.tile_position)
			var opposite_direction: TileSet.CellNeighbor = OPPOSITE_DIRECTION[direction]
			var active_layer: TileMapLayer = ref.active[direction]
			var opposite_active_layer: TileMapLayer = ref.active[opposite_direction]
			var atlas_coords: Vector2i = ATLAS_COORDS_FOR_DIRECTION[direction]
			var opposite_atlas_coords: Vector2i = ATLAS_COORDS_FOR_DIRECTION[opposite_direction]
			var current_cell := casting_player.tile_position
			active_layer.set_cell(current_cell, 0, atlas_coords)
			while current_cell != player.tile_position:
				current_cell = arena_tilemap.get_neighbor_cell(current_cell, direction)
				opposite_active_layer.set_cell(current_cell, 0, opposite_atlas_coords)
				if current_cell != player.tile_position:
					active_layer.set_cell(current_cell, 0, atlas_coords)

func _set_inactive_power_lines_from_player(player: Player, ref: TeamLayersRef) -> void:
	var aligned_cells_by_direction := arena_tilemap.get_aligned_cells_by_direction(player.tile_position)
	for direction in aligned_cells_by_direction:
		var opposite_direction: TileSet.CellNeighbor = OPPOSITE_DIRECTION[direction]
		var inactive_layer: TileMapLayer = ref.inactive[direction]
		var opposite_inactive_layer: TileMapLayer = ref.inactive[opposite_direction]
		var atlas_coords: Vector2i = ATLAS_COORDS_FOR_DIRECTION[direction]
		var opposite_atlas_coords: Vector2i = ATLAS_COORDS_FOR_DIRECTION[opposite_direction]
		var aligned_cells: Array[Vector2i] = aligned_cells_by_direction[direction]
		inactive_layer.set_cell(player.tile_position, 0, atlas_coords)
		for cell in aligned_cells:
			inactive_layer.set_cell(cell, 0, atlas_coords)
			opposite_inactive_layer.set_cell(cell, 0, opposite_atlas_coords)

func _on_players_changed(_players: Players) -> void:
	_set_power_lines()

func _on_turn_state_new_turn_started(_state: TurnState) -> void:
	_set_power_lines()
