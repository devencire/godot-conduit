class_name DazeUnpoweredTargetEffect

extends AttackEffect

var target: Player

func _init(init_target: Player) -> void:
    target = init_target

func display_text() -> String:
    return 'if target is not [color=yellow]powered[/color], daze them'

func is_enabled() -> bool:
    return not target.is_powered

func enact() -> int:
    target.status = Player.Status.DAZED
    return 0
