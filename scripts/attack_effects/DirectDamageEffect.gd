class_name DirectDamageEffect

extends AttackEffect

var target: Player
var damage: int

func _init(init_target: Player, init_damage: int) -> void:
    target = init_target
    damage = init_damage

func display_text() -> String:
    return 'deal %s damage to the target' % damage

func enact() -> int:
    target.take_damage(damage)
    return 0
