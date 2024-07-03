class_name BladeOverchargedDashSlashAttackOption
extends BladeDashSlashAttackOption

const OC_POWER_COST := 2
const OC_POWER_PER_DAMAGE := 2

func get_display_name() -> String:
    return 'OC Dash Slash'

func get_base_power_cost() -> int:
    return OC_POWER_COST

func get_effects(attacker: Player, target: Player, direction: TileSet.CellNeighbor) -> Array[AttackEffect]:
    return [
        FixedMoveEffect.new(attacker, 1, direction, 'towards the target'),
        OverchargedVariableDirectDamageEffect.new(attacker, target, DIRECT_DAMAGE, get_base_power_cost(), OC_POWER_PER_DAMAGE, get_display_name()),
        FixedPushEffect.new(attacker, target, UNPOWERED_PUSH_FORCE, direction),
        EndTurnEffect.new(attacker.turn_state)
    ]
