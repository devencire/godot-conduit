class_name SelectionTile

extends Node2D

enum Mode { DEFAULT, THICK, CANNOT_ACT }

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
				
