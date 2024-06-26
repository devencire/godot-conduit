class_name AttackOptionDescription

extends MarginContainer

@export var attack_option: AttackOption
@export var attacker: Player
@export var target: Player

@onready var effect_container: VBoxContainer = %EffectContainer
@onready var power_cost_label: RichTextLabel = %PowerCostLabel
@onready var success_chance_label: RichTextLabel = %SuccessChanceLabel
@onready var attack_effect_label: RichTextLabel = %AttackEffectLabel

func _ready() -> void:
	var base_power_cost := attack_option.get_base_power_cost()
	#if max_power_cost == -1:
	power_cost_label.text = '%s⚡' % base_power_cost
	#else:
		#%PowerCostLabel.text = str(power_cost) + '-' + str(max_power_cost) + '⚡'
	var success_chance := attacker.turn_state.chance_that_power_available(base_power_cost)
	success_chance_label.text = str(roundi(success_chance * 100)) + '% chance'
	success_chance_label.modulate = Constants.success_chance_color(success_chance)
	
	var effects := attack_option.get_effects(attacker, target, TileSet.CELL_NEIGHBOR_TOP_SIDE)
	for effect in effects:
		var new_label: RichTextLabel = attack_effect_label.duplicate()
		if effect.is_enabled():
			new_label.text = effect.display_text()
		else:
			new_label.text = '[s]%s[/s]' % effect.display_text()
			new_label.modulate = Color(Color.WHITE, 0.6)
		new_label.visible = true
		effect_container.add_child(new_label)
