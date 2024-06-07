class_name ArenaTileMap

extends TileMap

const GROUND_LAYER := 0

var astar: AStar2D
var disabled_point_ids: Array[int] = []

func _ready():
	_build_astar()

func _build_astar() -> void:
	var cells := get_used_cells(GROUND_LAYER)
	astar = AStar2D.new()
	astar.reserve_space(cells.size())
	for cell in cells:
		astar.add_point(_cell_to_astar_id(cell), map_to_local(cell))
	for cell in cells:
		var cell_id := _cell_to_astar_id(cell)
		var surrounding_cells := get_surrounding_cells(cell)
		for surrounding_cell in surrounding_cells:
			var surrounding_cell_id := _cell_to_astar_id(surrounding_cell)
			if astar.has_point(surrounding_cell_id):
				astar.connect_points(cell_id, surrounding_cell_id)

## Converts a Vector2i into a single int (mirroring `_astar_id_to_cell`).
## Depends on the grid not exceeding 50x50.
func _cell_to_astar_id(cell: Vector2i) -> int:
	# Need to add 10000 to ensure the id is not negative
	# (AStar2D rejects negative ids)
	return 10000 + cell.x + cell.y * 100

## Converts a single int into a Vector2i (mirroring `_cell_to_astar_id`).
func _astar_id_to_cell(id: int) -> Vector2i:
	var without_const := id - 10000
	var y = roundi(without_const / 100.0)
	return Vector2i(without_const - y * 100, y)

## Gets the shortest path of cells from start to end, or an empty array if there is no such path.
func get_cell_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var id_path := Array(astar.get_id_path(_cell_to_astar_id(start), _cell_to_astar_id(end)))
	var cells: Array[Vector2i] = []
	for id in id_path:
		cells.append(_astar_id_to_cell(id))
	return cells.slice(1)

## Get the cell for the mouse position of an InputEventMouse.
func get_hovered_cell(event: InputEventMouse) -> Vector2i:
	return local_to_map(make_input_local(event).position)
	
const hex_cell_neighbors := [
	TileSet.CELL_NEIGHBOR_TOP_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE
]

func get_aligned_cells(center_cell: Vector2i) -> Array[Vector2i]:
	var aligned_cells: Array[Vector2i] = [center_cell]
	for hex_cell_neighbor in hex_cell_neighbors:
		print(hex_cell_neighbor)
		var current_cell := center_cell
		while true:
			current_cell = get_neighbor_cell(current_cell, hex_cell_neighbor)
			print(current_cell, get_cell_source_id(GROUND_LAYER, current_cell))
			if get_cell_source_id(GROUND_LAYER, current_cell) == -1:
				break
			aligned_cells.append(current_cell)
	return aligned_cells

### Remove all existing pathfinding obstacles and create up-to-date ones.
### TODO do this incrementally instead?
func update_obstacles(players: Array[Player]):
	if not astar:
		return
	
	for disabled_point_id in disabled_point_ids:
		astar.set_point_disabled(disabled_point_id, false)
	disabled_point_ids = []

	for player in players:
		var astar_id := _cell_to_astar_id(player.tile_position)
		astar.set_point_disabled(astar_id, true)
		disabled_point_ids.append(astar_id)


func _on_players_changed(players: Array[Player]):
	update_obstacles(players)

