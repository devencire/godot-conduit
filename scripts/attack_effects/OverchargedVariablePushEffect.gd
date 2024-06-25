class_name OverchargedVariablePushEffect

extends AttackEffect

var attacker: Player
var target: Player
var power_per_force: int
var direction: TileSet.CellNeighbor

func _init(init_attacker: Player, init_target: Player, init_power_per_force: int, init_direction: TileSet.CellNeighbor) -> void:
    attacker = init_attacker
    target = init_target
    power_per_force = init_power_per_force
    direction = init_direction

func _calc_max_force(max_remaining_power: int) -> int:
    return max_remaining_power / power_per_force

func display_text() -> String:
    var max_force := _calc_max_force(attacker.turn_state.max_remaining_power)
    return 'push the target back up to %s more tile%s (' % [max_force, 's' if max_force > 1 else '']

func enact() -> int:
    var force := attacker.turn_state.actual_remaining_power / power_per_force
    if force == 0:
        return 0
    var power_spent := force * power_per_force
    attacker.resolve_push(target, direction, force)
    return power_spent
