class_name DazeTargetEffect

extends AttackEffect

var target: Player

func _init(init_target: Player) -> void:
    target = init_target

func display_text() -> String:
    return 'daze the target'

func enact() -> int:
    if target.status == Player.Status.OK:
        target.event_log.log('%s was dazed' % [BB.player_name(target)])
        target.status = Player.Status.DAZED
    return 0
