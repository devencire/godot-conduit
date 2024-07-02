class_name DirectDamageEffect

extends AttackEffect

var attacker: Player
var target: Player
var damage: int
var attack_name: String

func _init(init_attacker: Player, init_target: Player, init_damage: int, init_attack_name: String) -> void:
    attacker = init_attacker
    target = init_target
    damage = init_damage
    attack_name = init_attack_name

func display_text() -> String:
    return 'deal %s damage to the target' % damage

func enact() -> int:
    target.take_damage(DamageSource.DirectAttack.new(attacker, attack_name, damage))
    return 0
