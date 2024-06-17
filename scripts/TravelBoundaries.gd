extends Node2D

@export var score_state: ScoreState
@export var arena_tilemap: ArenaTileMap

@onready var team_one_boundary: TileMap = $TeamOneBoundary
@onready var team_two_boundary: TileMap = $TeamTwoBoundary

const TEAM_ONE_BOUNDARY_TILE := Vector2i(2, 0)
const TEAM_TWO_BOUNDARY_TILE := Vector2i(3, 0)

func _draw() -> void:
	for team in [Constants.Team.ONE, Constants.Team.TWO]:
		_draw_travel_boundary(team, score_state.travel_scores[team])

func _draw_travel_boundary(team: Constants.Team, current_travel_score: int) -> void:	
	# find the topmost tile
	var next_cell: Vector2i
	var boundary_tilemap: TileMap
	var tile_atlas_coords: Vector2i
	
	if team == Constants.Team.ONE:
		next_cell = Vector2i(0, -current_travel_score)
		boundary_tilemap = team_one_boundary
		tile_atlas_coords = TEAM_ONE_BOUNDARY_TILE
	else:
		next_cell = Vector2i(-current_travel_score, 0)
		boundary_tilemap = team_two_boundary
		tile_atlas_coords = TEAM_TWO_BOUNDARY_TILE
	
	boundary_tilemap.clear()
	
	while arena_tilemap.is_cell_pathable(Vector2i(next_cell.x - 1, next_cell.y - 1)):
		next_cell = Vector2i(next_cell.x - 1, next_cell.y - 1)
	print('team ', team, ' start_cell ', next_cell)
	
	while arena_tilemap.is_cell_pathable(next_cell):
		boundary_tilemap.set_cell(0, next_cell, 0, tile_atlas_coords)
		next_cell = Vector2i(next_cell.x + 1, next_cell.y + 1)


func _on_score_state_changed(_score_state):
	queue_redraw()
