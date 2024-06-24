class_name SelectionTile

extends Node2D

enum Mode { DEFAULT, THICK, CANNOT_ACT }

@onready var sprite: AnimatedSprite2D = $Sprite

@export var mode: Mode:
	set(new_mode):
		mode = new_mode
		$Sprite.modulate = Color.WHITE
		match mode:
			Mode.DEFAULT:
				$Sprite.animation = 'default'
			Mode.THICK:
				$Sprite.animation = 'thick'
			Mode.CANNOT_ACT:
				$Sprite.animation = 'default'
				$Sprite.modulate = Color.RED


func _on_player_is_on_active_team_changed(now_active: bool):
	visible = now_active

func _on_player_acted_this_turn_changed(player: Player, _now_acted: bool):
	_update_sprite(player)

func _on_player_status_changed(player: Player, _new_status: Player.Status):
	_update_sprite(player)

func _on_player_was_selected(player: Player):
	_update_sprite(player)

func _on_player_was_deselected(player: Player):
	_update_sprite(player)

func _update_sprite(player: Player) -> void:
	sprite.modulate = Color.WHITE
	if not player.can_act:
		sprite.animation = 'default'
		sprite.modulate = Color.RED
	elif player.selected:
		sprite.animation = 'thick'
	else:
		sprite.animation = 'default'
