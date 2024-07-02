class_name HammerPushAttackOption
extends AttackOption

const POWER_COST := 1
const PUSH_FORCE := 1

static var target_preview_tile_scene := preload("res://scenes/target_preview_tile.tscn")

func get_display_name() -> String:
    return 'Bludgeon'

func get_base_power_cost() -> int:
    return POWER_COST

func get_valid_targets(attacker: Player) -> Array[Player]:
    return AttackOption.get_adjacent_opponents(attacker)

func display_directions(attacker: Player, target: Player, display_node: Node2D, attack_callback: Callable) -> void:
    var valid_directions := get_valid_directions(attacker, target)
    for direction in valid_directions:
        var preview_tile := create_clickable_direction_node(attacker, target, direction, attack_callback)
        display_node.add_child(preview_tile)

static func create_clickable_direction_node(attacker: Player, target: Player, direction: TileSet.CellNeighbor, attack_callback: Callable) -> TargetPreviewTile:
    var cell := attacker.arena_tilemap.get_neighbor_cell(target.tile_position, direction)
    var preview_tile: TargetPreviewTile = target_preview_tile_scene.instantiate()
    preview_tile.position = attacker.arena_tilemap.map_to_local(cell)
    preview_tile.direction = direction
    preview_tile.team = attacker.team
    preview_tile.type = TargetPreviewTile.PreviewTileType.ARROW
    preview_tile.success_chance = attacker.turn_state.chance_that_power_available(POWER_COST)
    preview_tile.right_clicked.connect(func(): attack_callback.call(direction))
    return preview_tile

func get_valid_directions(attacker: Player, target: Player) -> Array[TileSet.CellNeighbor]:
    # fan-of-three
    var relative_direction = attacker.arena_tilemap.direction_of_cell(attacker.tile_position, target.tile_position)
    var directions := Constants.adjacent_directions(relative_direction)
    directions.append(relative_direction)
    return directions

func get_effects(attacker: Player, target: Player, direction: TileSet.CellNeighbor) -> Array[AttackEffect]:
    return [
        TargetNotPoweredMetaEffect.new(DazeTargetEffect.new(target), target),
        FixedPushEffect.new(attacker, target, PUSH_FORCE, direction),
    ]
