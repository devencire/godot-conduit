class_name ArenaTileMap

extends TileMap

const GROUND_LAYER := 0

var astar: AStar2D
var disabled_point_ids: Array[int] = []

func _ready():
	astar = _build_astar()
	update_obstacles()
	print(astar.get_point_ids())
	print(disabled_point_ids)

func _build_astar() -> AStar2D:
	var cells := get_used_cells(GROUND_LAYER)
	var astar := AStar2D.new()
	astar.reserve_space(cells.size())
	for cell in cells:
		print(cell, map_to_local(cell), _cell_to_astar_id(cell))
		astar.add_point(_cell_to_astar_id(cell), map_to_local(cell))
	for cell in cells:
		var cell_id := _cell_to_astar_id(cell)
		var surrounding_cells := get_surrounding_cells(cell)
		for surrounding_cell in surrounding_cells:
			astar.connect_points(cell_id, _cell_to_astar_id(surrounding_cell))
	return astar

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

### Remove all existing pathfinding obstacles and create up-to-date ones.
### TODO do this incrementally instead?
### TODO do this with signals or something instead?
func update_obstacles():
	if not astar:
		return
	
	for disabled_point_id in disabled_point_ids:
		astar.set_point_disabled(disabled_point_id, false)
	disabled_point_ids = []
		
	var players := find_children("*", "Player")
	for player in players:
		if player is Player:
			var astar_id := _cell_to_astar_id(player.tile_position)
			astar.set_point_disabled(astar_id, true)
			disabled_point_ids.append(astar_id)
