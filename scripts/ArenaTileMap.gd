class_name ArenaTileMap

extends TileMap

const GROUND_LAYER := 0
const WALL_LAYER := 1

var astar: ZoneRespectingAStar2D
var disabled_point_ids: Array[int] = []

@export var control_zones: ControlZones

func _ready():
	_build_astar()

## A specialised AStar2D that knows the `moving_team` and heavily penalises moves
## that leave a tile controlled by the opposing team (since players cannot normally
## make such moves).
class ZoneRespectingAStar2D:
	extends AStar2D
	
	var control_zones: ControlZones
	var moving_team: Constants.Team
	
	func _init(new_control_zones: ControlZones):
		control_zones = new_control_zones
	
	func _compute_cost(from_id: int, to_id: int):
		# heavily penalise moving out of opponent's controlled zones (since players cannot normally do this)
		var from_cell := ArenaTileMap._astar_id_to_cell(from_id)
		if control_zones.cell_controlled_by_team(from_cell, Constants.other_team(moving_team)):
			return 100000
		# otherwise just use the distance between the tiles
		var from_vec := get_point_position(from_id)
		var to_vec := get_point_position(to_id)
		return from_vec.distance_to(to_vec)

func _build_astar() -> void:
	var cells := get_used_cells(GROUND_LAYER)
	astar = ZoneRespectingAStar2D.new(control_zones)
	astar.reserve_space(cells.size())
	var tile_scale := Vector2(tile_set.tile_size.x, tile_set.tile_size.y)
	for cell in cells:
		astar.add_point(_cell_to_astar_id(cell), map_to_local(cell) / tile_scale)
		print(_cell_to_astar_id(cell), ' ', map_to_local(cell) / tile_scale)
	for cell in cells:
		var cell_id := _cell_to_astar_id(cell)
		var surrounding_cells := get_surrounding_cells(cell)
		for surrounding_cell in surrounding_cells:
			var surrounding_cell_id := _cell_to_astar_id(surrounding_cell)
			if astar.has_point(surrounding_cell_id):
				astar.connect_points(cell_id, surrounding_cell_id)

## Converts a Vector2i into a single int (mirroring `_astar_id_to_cell`).
## Depends on the grid not exceeding 50x50.
static func _cell_to_astar_id(cell: Vector2i) -> int:
	# Need to add 10000 to ensure the id is not negative
	# (AStar2D rejects negative ids)
	return 10000 + cell.x + cell.y * 100

## Converts a single int into a Vector2i (mirroring `_cell_to_astar_id`).
static func _astar_id_to_cell(id: int) -> Vector2i:
	var without_const := id - 10000
	var y = roundi(without_const / 100.0)
	return Vector2i(without_const - y * 100, y)

## Gets the shortest path of cells from start to end, or an empty array if there is no such path.
func get_cell_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var start_id := _cell_to_astar_id(start)
	var end_id := _cell_to_astar_id(end)
	if not astar.has_point(start_id) or not astar.has_point(end_id):
		return cells
	var id_path := Array(astar.get_id_path(start_id, end_id))
	for id in id_path:
		var cell := _astar_id_to_cell(id)
		# if the cell isn't the final cell and the opposing team controls it,
		# there is no valid path (ZoneRespectingAStar2D will only path through
		# such a cell if there is no other option)
		if id != id_path[-1] and control_zones.cell_controlled_by_team(cell, Constants.other_team(astar.moving_team)):
			cells = []
			return cells
		cells.append(_astar_id_to_cell(id))
	return cells.slice(1)

## Returns true if the cell contains ground (even if there's an obstacle).
func is_cell_pathable(cell: Vector2i) -> bool:
	var id := _cell_to_astar_id(cell)
	return astar.has_point(id)

## Returns true if the cell contains a wall (that players hit rather than fall into)
func is_cell_wall(cell: Vector2i) -> bool:
	return get_cell_source_id(WALL_LAYER, cell) != -1

## Get the cell for the mouse position of an InputEventMouse.
func get_hovered_cell(event: InputEventMouse) -> Vector2i:
	return local_to_map(make_input_local(event).position)
	
const hex_cell_neighbors: Array[TileSet.CellNeighbor] = [
	TileSet.CELL_NEIGHBOR_TOP_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE
]

func get_aligned_cells_by_direction(center_cell: Vector2i) -> Dictionary: # Dictionary[TileSet.CellNeighbor, Array[Vector2i]]
	var aligned_cells_by_direction := {}
	for hex_cell_neighbor in hex_cell_neighbors:
		var aligned_cells: Array[Vector2i] = []
		var current_cell := center_cell
		while true:
			current_cell = get_neighbor_cell(current_cell, hex_cell_neighbor)
			if get_cell_source_id(GROUND_LAYER, current_cell) == -1:
				break
			aligned_cells.append(current_cell)
		aligned_cells_by_direction[hex_cell_neighbor] = aligned_cells
	return aligned_cells_by_direction

## Returns the cells in the lines in the six directions from `center_cell`.
## Lines are blocked only by non-pathable tiles (i.e. walls but not players).
func get_aligned_cells(center_cell: Vector2i) -> Array[Vector2i]:
	var aligned_cells: Array[Vector2i] = [center_cell]
	for hex_cell_neighbor in hex_cell_neighbors:
		var current_cell := center_cell
		while true:
			current_cell = get_neighbor_cell(current_cell, hex_cell_neighbor)
			if get_cell_source_id(GROUND_LAYER, current_cell) == -1:
				break
			aligned_cells.append(current_cell)
	return aligned_cells

## Returns the cells `range` away in the six directions from `center_cell`.
## Keys are directions (as `TileSet.CellNeighbor`), values are cell positions.
## Cells for directions that are, or are blocked by, non-pathable tiles are not returned.
func get_aligned_cells_at_range(center_cell: Vector2i, distance: int) -> Dictionary:
	var aligned_cells: Dictionary = {} # Dictionary[TileSet.CellNeighbor, Vector2i]
	for hex_cell_neighbor in hex_cell_neighbors:
		var current_cell := center_cell
		var obstructed := false
		for n in distance:
			current_cell = get_neighbor_cell(current_cell, hex_cell_neighbor)
			if get_cell_source_id(GROUND_LAYER, current_cell) == -1:
				obstructed = true
				break
		if not obstructed:
			aligned_cells[hex_cell_neighbor] = current_cell
	return aligned_cells

func are_cells_aligned(first: Vector2i, second: Vector2i) -> bool:
	return first.x == second.x or first.y == second.y or first.x - first.y == second.x - second.y

## Returns the distance in tiles to travel from the halfway line to `cell`.
## Negative distances are towards team one's starting positions.
## Positive distances are towards team two's starting positions.
func distance_from_halfway_line(cell: Vector2i) -> int:
	return cell.x - cell.y

## Remove all existing pathfinding obstacles and create up-to-date ones.
## TODO do this incrementally instead?
func update_obstacles(players: Array[Player]):
	if not astar:
		return
	
	for disabled_point_id in disabled_point_ids:
		astar.set_point_disabled(disabled_point_id, false)
	disabled_point_ids = []

	for player in players:
		var astar_id := _cell_to_astar_id(player.tile_position)
		if astar.has_point(astar_id): # not true for out-of-arena players
			astar.set_point_disabled(astar_id, true)
		disabled_point_ids.append(astar_id)


func _on_players_changed(players: Players):
	update_obstacles(players.all_players)

func _on_turn_state_new_turn_started(state: TurnState):
	astar.moving_team = state.active_team
