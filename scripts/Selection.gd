class_name Selection

extends Node

var arena_tilemap: ArenaTileMap
@onready var selection_tile: SelectionTile = $SelectionTile
@onready var turn_state: TurnState = %TurnState

var selected_player: Player
var hovered_cell: Vector2i

var path_preview_tile_scene := preload("res://scenes/path_preview_tile.tscn")
var path_preview: Node

func _ready():
	arena_tilemap = find_parent('ArenaTileMap') as ArenaTileMap

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if not selected_player:
			return
		var new_hovered_cell := arena_tilemap.get_hovered_cell(event)
		if hovered_cell == new_hovered_cell:
			return
		hovered_cell = new_hovered_cell
		if not selected_player:
			return
		
		var cell_path := arena_tilemap.get_cell_path(selected_player.tile_position, hovered_cell)
		if cell_path.size() > 0:
			_update_path_preview(cell_path)
		else:
			_clear_path_preview()

	if event is InputEventMouseButton:
		if not event.pressed:
			return
		var clicked_cell := arena_tilemap.get_hovered_cell(event)
		var players := get_tree().get_nodes_in_group('players')
		for player in players:
			if player is Player:
				if player.team == turn_state.active_team and player.tile_position == clicked_cell:
					_select_player(player)
					return

		if selected_player:
			_try_move_selected_player(clicked_cell)

func _update_path_preview(cell_path: Array[Vector2i]):
	# TODO retain and re-use the preview tiles for performance?
	_clear_path_preview()
	path_preview = Node.new()
	for cell in cell_path:
		var preview_tile = path_preview_tile_scene.instantiate()
		preview_tile.position = arena_tilemap.map_to_local(cell)
		path_preview.add_child(preview_tile)
	add_child(path_preview)

func _clear_path_preview():
	if path_preview:
		path_preview.queue_free()
	path_preview = null

func _select_player(player: Player):
	if player == selected_player:
		return # already selected, nothing to do
	_deselect_player()
	selected_player = player
	selected_player.on_select()
	_update_selection_tile()
	
func _deselect_player():
	if not selected_player:
		return
	selected_player.on_deselect()
	selected_player = null
	_clear_path_preview()
	_update_selection_tile()

func _update_selection_tile():
	selection_tile.visible = selected_player != null
	selection_tile.team = turn_state.active_team
	if selected_player:
		selection_tile.position = arena_tilemap.map_to_local(selected_player.tile_position)

## Try to move the selected player to `destination_cell`.
## May move the player less tiles, or zero tiles, if power runs out during the move.
## Ends the turn if power runs out.
func _try_move_selected_player(destination_cell: Vector2i):
	var cell_path := arena_tilemap.get_cell_path(selected_player.tile_position, destination_cell)
	if cell_path.size() == 0:
		return # there is no valid path
	while cell_path.size() > 0:
		if not turn_state.try_spend_power(1):
			%EventLog.log('[b][color=%s]%s[/color] tried to move to %s but ran out of power![/b]' % [Constants.team_color(selected_player.team), selected_player.debug_name, cell_path[0]])
			_deselect_player()
			return # couldn't afford it, turn has ended
		selected_player.tile_position = cell_path[0]
		%EventLog.log('[color=%s]%s[/color] moved to %s' % [Constants.team_color(selected_player.team), selected_player.debug_name, cell_path[0]])
		cell_path = cell_path.slice(1)
	_update_selection_tile()
	_clear_path_preview()
