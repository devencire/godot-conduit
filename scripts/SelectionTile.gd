class_name SelectionTile

extends Node2D

enum Mode { DEFAULT, THICK }

@export var mode: Mode:
	set(new_mode):
		mode = new_mode
		match mode:
			Mode.DEFAULT:
				$Sprite.animation = 'default'
			Mode.THICK:
				$Sprite.animation = 'thick'
