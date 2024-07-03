class_name DazeTargetEffect

extends AttackEffect

var attacker: Player
var target: Player
var attack_name: String

func _init(init_attacker: Player, init_target: Player, init_attack_name: String) -> void:
    attacker = init_attacker
    target = init_target
    attack_name = init_attack_name

func display_text() -> String:
    return 'daze the target'

func enact() -> int:
    if target.status == Player.Status.OK:
        target.event_log.log('%s was dazed by %s\'s %s' % [BB.player_name(target), BB.player_name(attacker), attack_name])
        target.status = Player.Status.DAZED
    return 0
