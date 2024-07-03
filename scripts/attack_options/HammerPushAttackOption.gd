class_name HammerPushAttackOption
extends AttackOption

const POWER_COST := 1
const PUSH_FORCE := 1

func get_display_name() -> String:
    return 'Bludgeon'

func get_base_power_cost() -> int:
    return POWER_COST

func get_valid_targets(attacker: Player) -> Array[Player]:
    return AttackOption.get_adjacent_opponents(attacker)

func get_valid_directions(attacker: Player, target: Player) -> Array[TileSet.CellNeighbor]:
    # fan-of-three
    var relative_direction = attacker.arena_tilemap.direction_of_cell(attacker.tile_position, target.tile_position)
    var directions := Constants.adjacent_directions(relative_direction)
    directions.append(relative_direction)
    return directions

func get_effects(attacker: Player, target: Player, direction: TileSet.CellNeighbor) -> Array[AttackEffect]:
    return [
        TargetNotPoweredMetaEffect.new(DazeTargetEffect.new(attacker, target, get_display_name()), target),
        FixedPushEffect.new(attacker, target, PUSH_FORCE, direction),
    ]
