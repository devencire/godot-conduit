class_name Blade

extends Weapon

static var base := new()

func get_display_name() -> String:
    return 'Blade'

var attack_options: Array[AttackOption] = [
    BladeCloseSlashAttackOption.new(),
    BladeDashSlashAttackOption.new(),
    BladeOverchargedDashSlashAttackOption.new()
]

func get_attack_options() -> Array[AttackOption]:
    return attack_options
