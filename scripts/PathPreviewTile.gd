class_name PathPreviewTile

extends Node2D

@export var power_cost: int = 1
@export var success_chance: float = 1.0 # between 0 and 1

func _ready():
	$EnergyCostLabel.text = str(power_cost) + '⚡'
	$SuccessChanceLabel.text = str(roundi(success_chance * 100)) + '%'
	var green := maxf(0, 1 + (success_chance - 0.5) * 2)
	var red := maxf(0, 1 - (success_chance - 0.5) * 2)
	var color := Color(red, green, 0)
	print(green, ' ', red, ' ', color)
	$SuccessChanceLabel.modulate = color
