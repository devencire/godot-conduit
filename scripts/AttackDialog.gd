class_name AttackDialog

extends CanvasLayer

signal option_selected(option: AttackOption)

@export var attack_options: Array[AttackOption]
@export var attacker: Player
@export var target: Player

@onready var tab_container: TabContainer = %TabContainer

var attack_option_description_scene := preload("res://scenes/attack_option_description.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	for option in attack_options:
		var description_node: AttackOptionDescription = attack_option_description_scene.instantiate()
		description_node.attack_option = option
		description_node.attacker = attacker
		description_node.target = target
		tab_container.add_child(description_node)
		tab_container.set_tab_title(tab_container.get_child_count() - 1, option.get_display_name())

	#if max_power_cost == -1:
		#%PowerCostLabel.text = str(power_cost) + '⚡'
	#else:
		#%PowerCostLabel.text = str(power_cost) + '-' + str(max_power_cost) + '⚡'
	#%SuccessChanceLabel.text = str(roundi(success_chance * 100)) + '% chance'
	#%SuccessChanceLabel.modulate = Constants.success_chance_color(success_chance)
	#if not target_is_unpowered:
		#%TargetNotPoweredEffectLabel.modulate = Color(Color.WHITE, 0.5)
	#if direct_damage == 0:
		#%OverchargeDamageLabel.visible = false
	#else:
		#%OverchargeDamageLabel.visible = true
		#%OverchargeDamageLabel.text = '%s damage' % direct_damage

func _on_tab_container_tab_changed(tab_index: int) -> void:
	option_selected.emit(attack_options[tab_index])
