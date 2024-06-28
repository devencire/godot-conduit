class_name DamageSource

var attacker: Player
var display_text: String
var amount: int
var pierces_resolve: bool

class DirectAttack extends DamageSource:
	func _init(init_attacker: Player, attack_name: String, init_amount: int) -> void:
		attacker = init_attacker
		display_text = "from %s's %s" % [BB.player_name(attacker), attack_name]
		amount = init_amount

const OFF_ARENA_DAMAGE := 2

class OutOfArena extends DamageSource:
	func _init(init_attacker: Player) -> void:
		attacker = init_attacker
		display_text = "from falling off the arena"
		amount = OFF_ARENA_DAMAGE
		pierces_resolve = true

class PushedIntoWall extends DamageSource:
	func _init(init_attacker: Player, excess_force: int) -> void:
		attacker = init_attacker
		display_text = "from being slammed into a wall"
		amount = excess_force

const CLASH_DAMAGE := 1

class PushedIntoPlayer extends DamageSource:
	func _init(init_attacker: Player, pushed_into: Player) -> void:
		attacker = init_attacker
		display_text = "from being slammed into %s" % [BB.player_name(pushed_into)]
		amount = CLASH_DAMAGE

class HitByPushedPlayer extends DamageSource:
	func _init(init_attacker: Player, hit_by: Player) -> void:
		attacker = init_attacker
		display_text = "from %s being slammed into them" % [BB.player_name(hit_by)]
		amount = CLASH_DAMAGE
