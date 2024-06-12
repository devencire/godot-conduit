class_name AttackDialog

extends PanelContainer

signal set_overcharge(toggled_on: bool)

@export var power_cost: int = 1
@export var success_chance: float = 1.0 # between 0 and 1
@export var overcharge_activated: bool:
	set(on):
		overcharge_activated = on
		%OverchargeToggle.set_pressed_no_signal(on)

# Called when the node enters the scene tree for the first time.
func _ready():
	%PowerCostLabel.text = str(power_cost) + '⚡'
	%SuccessChanceLabel.text = str(roundi(success_chance * 100)) + '% chance'
	%SuccessChanceLabel.modulate = Constants.success_chance_color(success_chance)


func _on_overcharge_toggle_toggled(toggled_on):
	set_overcharge.emit(toggled_on)
	%OverchargeToggle.set_pressed_no_signal(toggled_on)
