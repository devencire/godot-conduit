extends Node

@export var player: Player

var target_preview_tile_scene := preload("res://scenes/target_preview_tile.tscn")
var target_preview: Node

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
	if not player.selected:
		return
	
	if event is InputEventMouseButton:
		if not event.pressed:
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
					try_push(push_target)
			
		
func _draw_target_selection_preview():
	# TODO retain and re-use the preview tiles for performance?
	_clear_target_preview()
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
	var valid_targets := get_valid_push_targets()
	for target in valid_targets:
		var preview_tile: TargetPreviewTile = target_preview_tile_scene.instantiate()
		preview_tile.position = player.arena_tilemap.map_to_local(target.cell)
		preview_tile.direction = target.direction
		preview_tile.team = player.team
		preview_tile.type = TargetPreviewTile.PreviewTileType.ARROW
		target_preview.add_child(preview_tile)
	add_child(target_preview)

func _clear_target_preview():
	if target_preview:
		target_preview.queue_free()
	target_preview = null

class ValidTarget:
	var direction: TileSet.CellNeighbor
	var cell: Vector2i
	var player: Player

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

func try_push(push_target: ValidTarget):
	if not player.turn_state.try_spend_power(2):
		player.event_log.log('[b][color=%s]%s[/color] tried to push [color=%s]%s[/color] but ran out of power![/b]' % [Constants.team_color(player.team), player.debug_name, Constants.team_color(push_target.player.team), push_target.player.debug_name])
		player.selected = false
		return
	if not player.arena_tilemap.is_cell_pathable(push_target.cell):
		# obviously this will want to be something else eventually
		push_target.player.tile_position = Constants.OFF_ARENA
		push_target.player.queue_free()
		
		player.event_log.log('[color=%s]%s[/color] pushed [color=%s]%s[/color] off the arena' % [Constants.team_color(player.team), player.debug_name, Constants.team_color(push_target.player.team), push_target.player.debug_name])
		_clear_selected_target()
		return
	push_target.player.tile_position = push_target.cell
	player.event_log.log('[color=%s]%s[/color] pushed [color=%s]%s[/color] into %s' % [Constants.team_color(player.team), player.debug_name, Constants.team_color(push_target.player.team), push_target.player.debug_name, push_target.cell])
	_clear_selected_target()
