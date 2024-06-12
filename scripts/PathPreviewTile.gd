class_name PathPreviewTile

extends Node2D

@export var power_cost: int = 1
@export var success_chance: float = 1.0 # between 0 and 1

func _ready():
	$PowerCostLabel.text = str(power_cost) + '⚡'
	$SuccessChanceLabel.text = str(roundi(success_chance * 100)) + '%'
	$SuccessChanceLabel.modulate = Constants.success_chance_color(success_chance)
