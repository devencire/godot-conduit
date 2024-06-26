extends Node

@export var player: Player

const ATTACK_COST := 1
const ATTACK_FORCE := 1

const OVERCHARGED_ATTACK_BASE_COST := 2
const OVERCHARGED_EXTRA_TILE_COST := 2
const OVERCHARGED_DIRECT_DAMAGE := 1

const CLASH_DAMAGE := 1

var target_preview_tile_scene := preload("res://scenes/target_preview_tile.tscn")
var target_preview: Node2D

var attack_dialog_scene := preload("res://scenes/attack_dialog.tscn")
var attack_dialog: CanvasLayer

var selected_target: Player

var attack_options: Array[AttackOption] = [
	HammerPushAttackOption.new(),
	HammerOverchargedPushAttackOption.new()
]

var selected_option := attack_options[0]

func _ready():
	player.was_selected.connect(_player_was_selected)
	player.was_deselected.connect(_player_was_deselected)
	player.was_moved.connect(_player_was_moved)

func _player_was_selected(_player: Player) -> void:
	_draw_target_selection_preview()

func _player_was_deselected(_player: Player) -> void:
	_clear_selected_target()
	_clear_target_preview()
	_clear_attack_dialog()

func _player_was_moved(_player: Player) -> void:
	if player.selected:
		_clear_selected_target()
		
func _draw_target_selection_preview():
	_clear_target_preview()
	# TODO replace this when unpowered attacks are possible
	if not player.is_powered:
		return
	target_preview = Node2D.new()
	# show valid targets for the currently selected option
	var valid_targets := get_valid_targets()
	for target in valid_targets:
		var preview_tile: TargetPreviewTile = target_preview_tile_scene.instantiate()
		preview_tile.position = player.arena_tilemap.map_to_local(target.tile_position)
		preview_tile.team = player.team
		preview_tile.type = TargetPreviewTile.PreviewTileType.TEAM_CIRCLE
		preview_tile.right_clicked.connect(func(): _select_target(target))
		target_preview.add_child(preview_tile)
	add_child(target_preview)

func _select_target(target: Player) -> void:
	selected_target = target
	_draw_attack_dialog()
	_draw_hit_direction_selection_preview()
	player.moving = false

func _clear_selected_target() -> void:
	selected_target = null
	player.moving = true
	_draw_target_selection_preview()

func _draw_hit_direction_selection_preview():
	_clear_target_preview()
	target_preview = Node2D.new()
	# show the opponent player as targeted
	var selected_target_tile: TargetPreviewTile = target_preview_tile_scene.instantiate()
	selected_target_tile.position = player.arena_tilemap.map_to_local(selected_target.tile_position)
	selected_target_tile.team = player.team
	selected_target_tile.type = TargetPreviewTile.PreviewTileType.SELECTED_CIRCLE
	selected_target_tile.right_clicked.connect(_clear_selected_target)
	target_preview.add_child(selected_target_tile)
	# show push directions for the currently selected option
	selected_option.display_directions(player, selected_target, target_preview, try_enacting_selected_option)
	add_child(target_preview)

func _draw_attack_dialog():
	_clear_attack_dialog()
	attack_dialog = attack_dialog_scene.instantiate()
	attack_dialog.attacker = player
	attack_dialog.target = selected_target
	attack_dialog.attack_options = attack_options
	attack_dialog.option_selected.connect(_set_attack_option)
	add_child(attack_dialog)

func _clear_attack_dialog():
	if attack_dialog:
		attack_dialog.queue_free()
	attack_dialog = null

func _set_attack_option(option: AttackOption):
	selected_option = option
	_draw_hit_direction_selection_preview()

func _clear_target_preview():
	if target_preview:
		target_preview.queue_free()
	target_preview = null

func get_valid_targets() -> Array[Player]:
	return selected_option.get_valid_targets(player)

func try_enacting_selected_option(direction: TileSet.CellNeighbor):
	var attack_cost := selected_option.get_base_power_cost()
	if not player.turn_state.try_spend_power(attack_cost):
		player.event_log.log('%s tried to %s but didn\'t have %s⚡!' % [BB.player_name(player), selected_option.get_display_name(), attack_cost])
		player.selected = false
		return
	
	player.event_log.log('%s spent %s⚡ to %s' % [BB.player_name(player), attack_cost, selected_option.get_display_name()])
	
	var excess_power_used := 0
	for effect in selected_option.get_effects(player, selected_target, direction):
		if effect.is_enabled():
			excess_power_used = maxi(excess_power_used, effect.enact())
	
	player.acted_this_turn = true
