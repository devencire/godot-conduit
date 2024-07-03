class_name Hammer

extends Weapon

static var base := new()

func get_display_name() -> String:
    return 'Hammer'

var attack_options: Array[AttackOption] = [
    HammerPushAttackOption.new(),
    HammerOverchargedPushAttackOption.new()
]

func get_attack_options() -> Array[AttackOption]:
    return attack_options
