class_name Selection

extends Node

var arena_tilemap: ArenaTileMap
@onready var selection_tile: SelectionTile = $SelectionTile

var selected_player: Player
var hovered_cell: Vector2i

var path_preview_tile_scene := preload("res://scenes/path_preview_tile.tscn")
var path_preview: Node

func _ready():
	arena_tilemap = find_parent('ArenaTileMap')

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
			update_path_preview(cell_path)
		else:
			clear_path_preview()

	if event is InputEventMouseButton:
		var clicked_cell := arena_tilemap.get_hovered_cell(event)
		var players := get_tree().get_nodes_in_group('players')
		for player in players:
			if player is Player:
				if player.team == Constants.CONTROLLED_TEAM and player.tile_position == clicked_cell:
					select_player(player)
					return

		if selected_player:
			move_selected_player(clicked_cell)
			clear_path_preview()

func update_path_preview(cell_path: Array[Vector2i]):
	# TODO retain and re-use the preview tiles for performance?
	clear_path_preview()
	path_preview = Node.new()
	for cell in cell_path:
		var preview_tile := path_preview_tile_scene.instantiate()
		preview_tile.position = arena_tilemap.map_to_local(cell)
		path_preview.add_child(preview_tile)
	add_child(path_preview)

func clear_path_preview():
	if path_preview:
		path_preview.queue_free()
	path_preview = null

func select_player(player: Player):
	if player == selected_player:
		return # already selected, nothing to do
	if selected_player:
		selected_player.on_deselect()
	selected_player = player
	selected_player.on_select()
	clear_path_preview()
	update_selection_tile()
	
func update_selection_tile():
	selection_tile.visible = selected_player != null
	if selected_player:
		selection_tile.position = arena_tilemap.map_to_local(selected_player.tile_position)

func move_selected_player(destination_cell: Vector2i):
	var cell_path := arena_tilemap.get_cell_path(selected_player.tile_position, destination_cell)
	if cell_path.size() == 0:
		return # there is no valid path
	selected_player.tile_position = destination_cell
	update_selection_tile()

