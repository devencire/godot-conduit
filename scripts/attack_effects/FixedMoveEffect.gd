class_name FixedMoveEffect

extends AttackEffect

var attacker: Player
var distance: int
var direction: TileSet.CellNeighbor
var direction_description: String

func _init(init_attacker: Player, init_distance: int, init_direction: TileSet.CellNeighbor, init_direction_description: String) -> void:
    attacker = init_attacker
    distance = init_distance
    direction = init_direction
    direction_description = init_direction_description

func display_text() -> String:
    return 'move self %s tile%s %s' % [distance, 's' if distance > 1 else '', direction_description]

func _find_destination_cell() -> Vector2i:
    var destination_cell := attacker.tile_position
    for _idx in range(distance):
        destination_cell = attacker.arena_tilemap.get_neighbor_cell(destination_cell, direction)
    return destination_cell

func is_enabled() -> bool:
    var destination_cell := _find_destination_cell()
    return attacker.arena_tilemap.is_cell_pathable(destination_cell) and destination_cell != attacker.tile_position

func enact() -> int:
    var destination_cell := _find_destination_cell()
    if attacker.arena_tilemap.is_cell_pathable(destination_cell) and destination_cell != attacker.tile_position:
        attacker.walk_path([destination_cell], [0])
    return 0
