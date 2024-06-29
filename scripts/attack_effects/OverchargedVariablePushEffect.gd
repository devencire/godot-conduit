class_name OverchargedVariablePushEffect

extends AttackEffect

var attacker: Player
var target: Player
var base_force: int
var base_power_cost: int
var power_per_force: int
var direction: TileSet.CellNeighbor

func _init(init_attacker: Player, init_target: Player, init_base_force: int, init_base_power_cost: int, init_power_per_force: int, init_direction: TileSet.CellNeighbor) -> void:
	attacker = init_attacker
	target = init_target
	base_force = init_base_force
	base_power_cost = init_base_power_cost
	power_per_force = init_power_per_force
	direction = init_direction

func _calc_max_force(max_remaining_power: int) -> int:
	@warning_ignore("integer_division")
	return base_force + (max_remaining_power - base_power_cost) / power_per_force

func display_text() -> String:
	var max_force := _calc_max_force(attacker.turn_state.max_remaining_power)
	if max_force == base_force:
		return 'push the target %s tile%s' % [base_force, 's' if base_force > 1 else '']
	return 'push the target %s-%s tile%s (%s⚡ per extra tile)' % [base_force, max_force, 's' if max_force > 1 else '', power_per_force]

func enact() -> int:
	@warning_ignore("integer_division")
	var extra_force := attacker.turn_state.actual_remaining_power / power_per_force
	var force := base_force + extra_force
	if force == 0:
		return 0
	var extra_power_spent := extra_force * power_per_force
	attacker.resolve_push(target, direction, force)
	return extra_power_spent
