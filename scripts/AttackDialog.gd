class_name AttackDialog

extends CanvasLayer

signal option_selected(option: AttackOption)

@export var attack_options: Array[AttackOption]
@export var attacker: Player

@export var target: Player:
	set(new_target):
		target = new_target
		if is_inside_tree():
			_regenerate_attack_option_tabs()

var selected_option: AttackOption

@onready var tab_container: TabContainer = %TabContainer

var attack_option_description_scene := preload("res://scenes/attack_option_description.tscn")

func _ready():
	_regenerate_attack_option_tabs()

# Used to suppress option_selected signals when tabs are recreated on target change.
var regenerating := false

func _regenerate_attack_option_tabs():
	regenerating = true
	
	for child in tab_container.get_children():
		tab_container.remove_child(child)
		child.queue_free()
	
	var original_selected_option := selected_option
	for option in attack_options:
		var is_selected := false
		if original_selected_option:
			is_selected = option == original_selected_option
		var description_node: AttackOptionDescription = attack_option_description_scene.instantiate()
		description_node.attack_option = option
		description_node.attacker = attacker
		description_node.target = target
		tab_container.add_child(description_node)
		var tab_index := tab_container.get_child_count() - 1
		tab_container.set_tab_title(tab_index, option.get_display_name())
		if is_selected:
			tab_container.current_tab = tab_index
	
	regenerating = false

func _on_tab_container_tab_changed(tab_index: int) -> void:
	if regenerating:
		return
	selected_option = attack_options[tab_index]
	option_selected.emit(attack_options[tab_index])
