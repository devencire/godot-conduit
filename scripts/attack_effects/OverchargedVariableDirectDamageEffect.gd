class_name OverchargedVariableDirectDamageEffect

extends AttackEffect

var attacker: Player
var target: Player
var base_damage: int
var base_power_cost: int
var power_per_damage: int
var attack_name: String

func _init(init_attacker: Player, init_target: Player, init_base_damage: int, init_base_power_cost: int, init_power_per_damage: int, init_attack_name: String) -> void:
    attacker = init_attacker
    target = init_target
    base_damage = init_base_damage
    base_power_cost = init_base_power_cost
    power_per_damage = init_power_per_damage
    attack_name = init_attack_name

func _calc_max_damage(max_remaining_power: int) -> int:
    @warning_ignore("integer_division")
    return base_damage + (max_remaining_power - base_power_cost) / power_per_damage

func display_text() -> String:
    var max_damage := _calc_max_damage(attacker.turn_state.max_remaining_power)
    if max_damage == base_damage:
        return 'deal %s damage to the target' % [base_damage]
    return 'deal %s-%s damage to the target (%s⚡ per extra damage)' % [base_damage, max_damage, power_per_damage]

func enact() -> int:
    @warning_ignore("integer_division")
    var extra_damage := attacker.turn_state.actual_remaining_power / power_per_damage
    var damage := base_damage + extra_damage
    if damage == 0:
        return 0
    var extra_power_spent := extra_damage * power_per_damage
    target.take_damage(DamageSource.DirectAttack.new(attacker, attack_name, damage))
    return extra_power_spent
