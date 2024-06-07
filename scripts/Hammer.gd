extends Node

@export var player: Player

var target_preview_tile_scene := preload("res://scenes/target_preview_tile.tscn")
var target_preview: Node

func _ready():
	player.was_selected.connect(_player_was_selected)
	player.was_deselected.connect(_player_was_deselected)
	player.was_moved.connect(_player_was_moved)

func _player_was_selected(player: Player) -> void:
	player.event_log.log("It's hammer time")
	_update_target_preview()

func _player_was_deselected(player: Player) -> void:
	player.event_log.log("It's no longer hammer time")
	_clear_target_preview()

func _player_was_moved(player: Player) -> void:
	if not player.selected:
		return
	player.event_log.log("It's hammer time somewhere new")
	_update_target_preview()

func _unhandled_input(event):
	if not player.selected:
		return
	
	if event is InputEventMouseButton:
		if not event.pressed:
			return
		var clicked_cell := player.arena_tilemap.get_hovered_cell(event)
		var player_in_cell := player.players.player_in_cell(clicked_cell, Constants.other_team(player.team))
		if player_in_cell:
			print("We'd hit ", player_in_cell, " now, if only it was implemented")
		
func _update_target_preview():
	# TODO retain and re-use the preview tiles for performance?
	_clear_target_preview()
	target_preview = Node.new()
	var possible_cells := player.arena_tilemap.get_aligned_cells_at_range(player.tile_position, 1)
	for cell in possible_cells:
		var player_in_cell := player.players.player_in_cell(cell, Constants.other_team(player.team))
		if player_in_cell:
			var preview_tile: TargetPreviewTile = target_preview_tile_scene.instantiate()
			preview_tile.position = player.arena_tilemap.map_to_local(cell)
			preview_tile.team = player_in_cell.team
			target_preview.add_child(preview_tile)
	add_child(target_preview)

func _clear_target_preview():
	if target_preview:
		target_preview.queue_free()
	target_preview = null
