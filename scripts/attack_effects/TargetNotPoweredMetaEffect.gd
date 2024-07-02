class_name TargetNotPoweredMetaEffect

extends AttackEffect

var base_effect: AttackEffect
var target: Player

func _init(init_base_effect: AttackEffect, init_target: Player) -> void:
    base_effect = init_base_effect
    target = init_target

func display_text() -> String:
    return 'if target is not [color=yellow]powered[/color], %s' % base_effect.display_text()

func is_enabled() -> bool:
    if not target:
        return base_effect.is_enabled()
    return not target.is_powered and base_effect.is_enabled()

func enact() -> int:
    return base_effect.enact()
