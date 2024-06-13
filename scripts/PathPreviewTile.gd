class_name PathPreviewTile

extends Node2D

@export var power_cost: int = 1
@export var success_chance: float = 1.0 # between 0 and 1

func _ready():
	BB.set_centered_outlined_text($PowerCostLabel, '%s⚡' % power_cost)
	BB.set_centered_outlined_text($SuccessChanceLabel, '%s%%' % roundi(success_chance * 100), Constants.success_chance_color(success_chance))
