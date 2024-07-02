class_name DazeUnpoweredTargetEffect

extends AttackEffect

var target: Player

func _init(init_target: Player) -> void:
    target = init_target

func display_text() -> String:
    return 'if target is not [color=yellow]powered[/color], daze them'

func is_enabled() -> bool:
    if not target:
        return true
    return not target.is_powered

func enact() -> int:
    if target.status == Player.Status.OK:
        target.event_log.log('%s was dazed' % [BB.player_name(target)])
        target.status = Player.Status.DAZED
    return 0
