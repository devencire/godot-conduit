class_name PathPreviewTile

extends Node2D

@export var power_cost: int = 1
@export var success_chance: float = 1.0 # between 0 and 1
@export var increased_cost: bool = false # affects how the cost is displayed

func _ready():
	if power_cost > 0:
		$PowerCostLabel.visible = true
		BB.set_centered_outlined_text($PowerCostLabel, '%s⚡' % power_cost, Color.WHITE, Color.RED if increased_cost else Color.BLACK)
		$FreeMoveDisplay.visible = false
	else:
		$FreeMoveDisplay.visible = true
		$PowerCostLabel.visible = false
	BB.set_centered_outlined_text($SuccessChanceLabel, '%s%%' % roundi(success_chance * 100), Constants.success_chance_color(success_chance))
