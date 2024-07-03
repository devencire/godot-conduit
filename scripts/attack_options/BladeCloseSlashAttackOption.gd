class_name BladeCloseSlashAttackOption
extends AttackOption

const POWER_COST := 1
const DIRECT_DAMAGE := 1
const UNPOWERED_PUSH_FORCE := 1

func get_display_name() -> String:
    return 'Close Slash'

func get_base_power_cost() -> int:
    return POWER_COST

func get_valid_targets(attacker: Player) -> Array[Player]:
    return AttackOption.get_adjacent_opponents(attacker)

func get_valid_directions(attacker: Player, target: Player) -> Array[TileSet.CellNeighbor]:
    # only directly back
    var relative_direction = attacker.arena_tilemap.direction_of_cell(attacker.tile_position, target.tile_position)
    return [relative_direction]

func get_effects(attacker: Player, target: Player, direction: TileSet.CellNeighbor) -> Array[AttackEffect]:
    return [
        TargetNotPoweredMetaEffect.new(DirectDamageEffect.new(attacker, target, DIRECT_DAMAGE, get_display_name()), target),
        FixedPushEffect.new(attacker, target, UNPOWERED_PUSH_FORCE, direction),
    ]
