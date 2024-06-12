extends Node

@export var player: Player

const ATTACK_COST := 2
const OVERCHARGED_EXTRA_TILE_COST := 2

var target_preview_tile_scene := preload("res://scenes/target_preview_tile.tscn")
var target_preview: Node

var attack_dialog_scene := preload("res://scenes/attack_dialog.tscn")

var selected_target: ValidTarget

func _ready():
	player.was_selected.connect(_player_was_selected)
	player.was_deselected.connect(_player_was_deselected)
	player.was_moved.connect(_player_was_moved)

func _player_was_selected(_player: Player) -> void:
	_draw_target_selection_preview()

func _player_was_deselected(_player: Player) -> void:
	_clear_selected_target()
	_clear_target_preview()

func _player_was_moved(_player: Player) -> void:
	if player.selected:
		_clear_selected_target()

func _clear_selected_target() -> void:
	selected_target = null
	player.moving = true
	_draw_target_selection_preview()

func _unhandled_input(event):
	if not player.selected or not player.is_powered_by_team_beacon():
		return
	
	if event is InputEventMouseButton:
		if not event.pressed or not event.button_index == MOUSE_BUTTON_LEFT:
			return
		var clicked_cell := player.arena_tilemap.get_hovered_cell(event)
		if not selected_target:
			# they may have clicked an opposing player to target them
			var valid_targets := get_valid_targets()
			for target in valid_targets:
				if target.cell == clicked_cell:
					selected_target = target
					_draw_hit_direction_selection_preview()
					player.moving = false
		else:
			# they may have clicked their target again to deselect them
			if selected_target.cell == clicked_cell:
				_clear_selected_target()
				return
			# they may have clicked a direction to push their target in
			var valid_push_targets = get_valid_push_targets()
			for push_target in valid_push_targets:
				if push_target.cell == clicked_cell:
					try_push(push_target, selected_target.overcharged)
					get_viewport().set_input_as_handled()
			
		
func _draw_target_selection_preview():
	# TODO retain and re-use the preview tiles for performance?
	_clear_target_preview()
	if not player.is_powered_by_team_beacon():
		return
	target_preview = Node.new()
	var valid_targets := get_valid_targets()
	for target in valid_targets:
		var preview_tile: TargetPreviewTile = target_preview_tile_scene.instantiate()
		preview_tile.position = player.arena_tilemap.map_to_local(target.cell)
		preview_tile.team = player.team
		target_preview.add_child(preview_tile)
	add_child(target_preview)

func _draw_hit_direction_selection_preview():
	_clear_target_preview()
	# show the opponent player as targeted
	target_preview = Node.new()
	var selected_target_tile: TargetPreviewTile = target_preview_tile_scene.instantiate()
	selected_target_tile.position = player.arena_tilemap.map_to_local(selected_target.cell)
	selected_target_tile.team = player.team
	target_preview.add_child(selected_target_tile)
	# show push directions
	var base_attack_cost := ATTACK_COST
	var base_attack_chance := player.turn_state.chance_that_power_available(base_attack_cost)
	var valid_targets := get_valid_push_targets()
	for target in valid_targets:
		var preview_tile: TargetPreviewTile = target_preview_tile_scene.instantiate()
		preview_tile.position = player.arena_tilemap.map_to_local(target.cell)
		preview_tile.direction = target.direction
		preview_tile.team = player.team
		preview_tile.type = TargetPreviewTile.PreviewTileType.ARROW
		preview_tile.success_chance = base_attack_chance
		target_preview.add_child(preview_tile)
		if selected_target.overcharged:
			var further_push_cost := base_attack_cost
			var further_push_chance := base_attack_chance
			var further_push_cell := target.cell
			while true:
				further_push_cost += OVERCHARGED_EXTRA_TILE_COST
				further_push_chance = player.turn_state.chance_that_power_available(further_push_cost)
				if further_push_chance == 0:
					break
				further_push_cell = player.arena_tilemap.get_neighbor_cell(further_push_cell, target.direction)
				var cell_pathable := player.arena_tilemap.is_cell_pathable(further_push_cell)
				var further_push_preview_tile: TargetPreviewTile = target_preview_tile_scene.instantiate()
				further_push_preview_tile.position = player.arena_tilemap.map_to_local(further_push_cell)
				further_push_preview_tile.direction = target.direction
				further_push_preview_tile.team = player.team
				further_push_preview_tile.type = TargetPreviewTile.PreviewTileType.FADED_ARROW
				further_push_preview_tile.success_chance = further_push_chance
				target_preview.add_child(further_push_preview_tile)
				# if we just previewed knocking the target off the arena, don't show any further-out previews
				if not cell_pathable:
					break
	# show attack dialog
	var attack_dialog: AttackDialog = attack_dialog_scene.instantiate()
	# TODO not just use a constant vector, or who am I kidding, all this UI code must be burned later
	match selected_target.direction:
		TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE, TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE:
			attack_dialog.position = player.arena_tilemap.map_to_local(player.tile_position) + Vector2(0, 150)
		_:
			attack_dialog.position = player.arena_tilemap.map_to_local(player.tile_position) - Vector2(0, 150)
	attack_dialog.power_cost = base_attack_cost
	attack_dialog.success_chance = base_attack_chance
	attack_dialog.overcharge_activated = selected_target.overcharged
	attack_dialog.set_overcharge.connect(_set_overcharge)
	target_preview.add_child(attack_dialog)
	add_child(target_preview)

func _set_overcharge(toggled_on: bool):
	if selected_target:
		selected_target.overcharged = toggled_on
		_draw_hit_direction_selection_preview()

func _clear_target_preview():
	if target_preview:
		target_preview.queue_free()
	target_preview = null

class ValidTarget:
	var direction: TileSet.CellNeighbor
	var cell: Vector2i
	var player: Player
	var overcharged: bool

func get_valid_targets() -> Array[ValidTarget]:
	var valid_targets: Array[ValidTarget] = []
	var possible_cells := player.arena_tilemap.get_aligned_cells_at_range(player.tile_position, 1)
	for direction in possible_cells:
		var cell: Vector2i = possible_cells[direction]
		var player_in_cell := player.players.player_in_cell(cell, Constants.other_team(player.team))
		if player_in_cell:
			var target := ValidTarget.new()
			target.direction = direction
			target.cell = cell
			target.player = player_in_cell
			valid_targets.append(target)
	return valid_targets

# this is kinda a mis-reuse of ValidTarget but whatever
func get_valid_push_targets() -> Array[ValidTarget]:
	var valid_directions := Constants.adjacent_directions(selected_target.direction)
	valid_directions.append(selected_target.direction)
	var valid_targets: Array[ValidTarget] = []
	for direction in valid_directions:
		var target := ValidTarget.new()
		target.direction = direction
		target.cell = player.arena_tilemap.get_neighbor_cell(selected_target.cell, direction)
		target.player = selected_target.player
		valid_targets.append(target)
	return valid_targets

class PushAction:
	var player: Player
	var direction: TileSet.CellNeighbor
	var force: int # this is just a number of tiles for now

func try_push(push_target: ValidTarget, overcharged: bool):
	var attack_cost := ATTACK_COST
	if not player.turn_state.try_spend_power(attack_cost):
		player.event_log.log('[b][color=%s]%s[/color] tried to push [color=%s]%s[/color] but didn\'t have %s⚡![/b]' % [Constants.team_color(player.team).to_html(), player.debug_name, Constants.team_color(push_target.player.team).to_html(), push_target.player.debug_name, attack_cost])
		player.selected = false
		return
	var push_action := PushAction.new()
	push_action.player = push_target.player
	push_action.direction = push_target.direction
	push_action.force = 1
	if overcharged:
		while player.turn_state.try_spend_power(OVERCHARGED_EXTRA_TILE_COST):
			push_action.force += 1
			attack_cost += OVERCHARGED_EXTRA_TILE_COST
	var push_outcomes := resolve_push(push_action)
	if overcharged:
		player.event_log.log('[b][color=%s]%s[/color] spent %s⚡ on an overcharged push![/b]' % [Constants.team_color(player.team).to_html(), player.debug_name, attack_cost])
	else:
		player.event_log.log('[color=%s]%s[/color] spent %s⚡ on a push' % [Constants.team_color(player.team).to_html(), player.debug_name, attack_cost])
	for outcome in push_outcomes:
		match outcome.type:
			PushOutcomeType.MOVED_TO:
				player.event_log.log('[color=%s]%s[/color] pushed [color=%s]%s[/color] into %s' % [Constants.team_color(player.team).to_html(), player.debug_name, Constants.team_color(outcome.player.team).to_html(), outcome.player.debug_name, outcome.player.tile_position])
			PushOutcomeType.OUT_OF_ARENA:
				player.event_log.log('[color=%s]%s[/color] pushed [color=%s]%s[/color] off the arena!' % [Constants.team_color(player.team).to_html(), player.debug_name, Constants.team_color(outcome.player.team).to_html(), outcome.player.debug_name])
	if overcharged:
		player.selected = false
		return
	_clear_selected_target()

enum PushOutcomeType { MOVED_TO, OUT_OF_ARENA }

class PushOutcome:
	var player: Player
	var type: PushOutcomeType

# TODO move this out of this specific weapon, it's a generic mechanic
func resolve_push(push_action: PushAction) -> Array[PushOutcome]:
	var new_push_results: Array[PushOutcome] = []
	while push_action.force > 0:
		var next_cell := player.arena_tilemap.get_neighbor_cell(push_action.player.tile_position, push_action.direction)
		if not player.arena_tilemap.is_cell_pathable(next_cell):
			# obviously this will want to be something else eventually
			push_action.player.tile_position = Constants.OFF_ARENA
			push_action.player.queue_free()
			var push_outcome := PushOutcome.new()
			push_outcome.player = push_action.player
			push_outcome.type = PushOutcomeType.OUT_OF_ARENA
			return [push_outcome]
		var player_in_next_cell := player.players.player_in_cell(next_cell)
		if player_in_next_cell:
			# finish pushing `push_action.player`, so they end in the cell about to be vacated
			push_action.player.tile_position = next_cell
			# now also push the player already in that cell, transferring all remaining force to them
			var new_push_action := PushAction.new()
			new_push_action.player = player_in_next_cell
			new_push_action.direction = push_action.direction
			# use up an extra force (absorbed by the impact?) so that the preview is accurate to the final victim's final location
			new_push_action.force = push_action.force - 1
			new_push_results = resolve_push(new_push_action)
			break
		# push `push_action.player` one tile
		push_action.player.tile_position = next_cell
		# we've used up some force, we'll loop to push further if force remains
		push_action.force -= 1
	var push_outcome := PushOutcome.new()
	push_outcome.player = push_action.player
	push_outcome.type = PushOutcomeType.MOVED_TO
	# if this player was pushed into another player,
	# prepend this result so it gets listed first
	new_push_results.push_front(push_outcome)
	return new_push_results
