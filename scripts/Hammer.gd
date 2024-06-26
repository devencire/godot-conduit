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

func _clear_selected_target() -> void:
	selected_target = null
	player.moving = true
	_draw_target_selection_preview()

func _unhandled_input(event):
	if not player.selected or not player.is_powered:
		return
	
	if event is InputEventMouseButton:
		if not event.pressed or not event.button_index == MOUSE_BUTTON_RIGHT:
			return
		var clicked_cell := player.arena_tilemap.get_hovered_cell(event)
		if not selected_target:
			# they may have clicked an opposing player to target them
			var valid_targets := get_valid_targets()
			for target in valid_targets:
				if target.tile_position == clicked_cell:
					selected_target = target
					_draw_attack_dialog()
					_draw_hit_direction_selection_preview()
					player.moving = false
		else:
			# they may have clicked their target again to deselect them
			if selected_target.tile_position == clicked_cell:
				_clear_selected_target()
				return
			
		
func _draw_target_selection_preview():
	# TODO retain and re-use the preview tiles for performance?
	_clear_target_preview()
	if not player.is_powered:
		return
	target_preview = Node2D.new()
	var valid_targets := get_valid_targets()
	for target in valid_targets:
		var preview_tile: TargetPreviewTile = target_preview_tile_scene.instantiate()
		preview_tile.position = player.arena_tilemap.map_to_local(target.tile_position)
		preview_tile.team = player.team
		preview_tile.type = TargetPreviewTile.PreviewTileType.TEAM_CIRCLE
		target_preview.add_child(preview_tile)
	add_child(target_preview)

func _draw_hit_direction_selection_preview():
	_clear_target_preview()
	# show the opponent player as targeted
	target_preview = Node2D.new()
	var selected_target_tile: TargetPreviewTile = target_preview_tile_scene.instantiate()
	selected_target_tile.position = player.arena_tilemap.map_to_local(selected_target.tile_position)
	selected_target_tile.team = player.team
	selected_target_tile.type = TargetPreviewTile.PreviewTileType.SELECTED_CIRCLE
	target_preview.add_child(selected_target_tile)
	# show push directions
	selected_option.display_directions(player, selected_target, target_preview, try_push)
	# show attack dialog
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

func try_push(direction: TileSet.CellNeighbor):
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
