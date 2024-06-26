class_name FixedPushEffect

extends AttackEffect

var attacker: Player
var target: Player
var force: int
var direction: TileSet.CellNeighbor

func _init(init_attacker: Player, init_target: Player, init_force: int, init_direction: TileSet.CellNeighbor) -> void:
    attacker = init_attacker
    target = init_target
    force = init_force
    direction = init_direction

func display_text() -> String:
    return 'push the target %s tile%s' % [force, 's' if force > 1 else '']

func enact() -> int:
    attacker.resolve_push(target, direction, force)
    return 0
