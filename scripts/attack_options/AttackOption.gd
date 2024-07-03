class_name AttackOption
extends Resource

func get_display_name() -> String:
    return 'Missing name'

func get_base_power_cost() -> int:
    return 0

func get_valid_targets(_attacker: Player) -> Array[Player]:
    return []

func get_valid_directions(_attacker: Player, _target: Player) -> Array[TileSet.CellNeighbor]:
    return []

func display_directions(attacker: Player, target: Player, display_node: Node2D, attack_callback: Callable) -> void:
    var valid_directions := get_valid_directions(attacker, target)
    var power_cost := get_base_power_cost()
    for direction in valid_directions:
        var preview_tile := create_clickable_direction_node(attacker, target, direction, power_cost, attack_callback)
        display_node.add_child(preview_tile)

static var target_preview_tile_scene := preload("res://scenes/target_preview_tile.tscn")

static func create_clickable_direction_node(attacker: Player, target: Player, direction: TileSet.CellNeighbor, power_cost: int, attack_callback: Callable) -> TargetPreviewTile:
    var cell := attacker.arena_tilemap.get_neighbor_cell(target.tile_position, direction)
    var preview_tile: TargetPreviewTile = target_preview_tile_scene.instantiate()
    preview_tile.position = attacker.arena_tilemap.map_to_local(cell)
    preview_tile.direction = direction
    preview_tile.team = attacker.team
    preview_tile.type = TargetPreviewTile.PreviewTileType.ARROW
    preview_tile.success_chance = attacker.turn_state.chance_that_power_available(power_cost)
    preview_tile.right_clicked.connect(func(): attack_callback.call(direction))
    return preview_tile

func get_effects(_attacker: Player, _target: Player, _direction: TileSet.CellNeighbor) -> Array[AttackEffect]:
    return []

## Common functions

static func get_opponents_at_range(attacker: Player, distance: int) -> Array[Player]:
    var valid_targets: Array[Player] = []
    var possible_cells := attacker.arena_tilemap.get_aligned_cells_at_range(attacker.tile_position, distance)
    for direction in possible_cells:
        var cell: Vector2i = possible_cells[direction]
        var player_in_cell := attacker.players.player_in_cell(cell, Constants.other_team(attacker.team))
        if player_in_cell:
            valid_targets.append(player_in_cell)
    return valid_targets

static func get_adjacent_opponents(attacker: Player) -> Array[Player]:
    return get_opponents_at_range(attacker, 1)
