class_name AttackDialog

extends PanelContainer

signal set_overcharge(toggled_on: bool)

@export var power_cost: int = 1
@export var max_power_cost: int = -1 # not used unless set to other than -1
@export var direct_damage: int = 0
@export var success_chance: float = 1.0 # between 0 and 1
@export var overcharge_activated: bool:
	set(on):
		overcharge_activated = on
		%OverchargeToggle.set_pressed_no_signal(on)

# Called when the node enters the scene tree for the first time.
func _ready():
	if max_power_cost == -1:
		%PowerCostLabel.text = str(power_cost) + '⚡'
	else:
		%PowerCostLabel.text = str(power_cost) + '-' + str(max_power_cost) + '⚡'
	%SuccessChanceLabel.text = str(roundi(success_chance * 100)) + '% chance'
	%SuccessChanceLabel.modulate = Constants.success_chance_color(success_chance)
	if direct_damage == 0:
		%DirectDamageLabel.visible = false
	else:
		%DirectDamageLabel.visible = true
		%DirectDamageLabel.text = '%s damage' % direct_damage


func _on_overcharge_toggle_toggled(toggled_on):
	set_overcharge.emit(toggled_on)
	%OverchargeToggle.set_pressed_no_signal(toggled_on)
