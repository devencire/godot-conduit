class_name Player

extends Node

signal was_moved(player: Player)
signal was_selected(player: Player)
signal was_deselected(player: Player)

var arena_tilemap: ArenaTileMap
var players: Players
var turn_state: TurnState
var event_log: EventLog

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var selection_tile: SelectionTile = $SelectionTile

var hovered_cell: Vector2i
var path_preview_tile_scene := preload("res://scenes/path_preview_tile.tscn")
var path_preview: Node

# Which team the player is a member of.
@export var team: Constants.Team

# Where the Player is in the ArenaTileMap, in tile coordinates.
@export var tile_position: Vector2i:
	set(new_tile_position):
		tile_position = new_tile_position
		_move_sprite_to_tile_position()
		was_moved.emit(self)

# Whether the Player is the Beacon, powering all aligned tiles.
@export var is_beacon: bool

# A name, just used for debugging for now
@export var debug_name: String
static var next_id := 1

@export var selected: bool:
	set(new_selected):
		selected = new_selected
		_update_selection_tile()
		if selected:
			was_selected.emit(self)
		else:
			_clear_path_preview()
			was_deselected.emit(self)

func _ready():
	# TODO there's got to be a better way of sharing these?
	# at least we only use `match_root` directly in `_ready`
	var match_root: MatchRoot = find_parent('MatchRoot')
	arena_tilemap = match_root.arena_tilemap
	turn_state = match_root.turn_state
	event_log = match_root.event_log
	
	players = get_parent()

	debug_name = 'Player %s' % next_id
	next_id += 1
	sprite.modulate = Constants.team_color(team)
	_move_sprite_to_tile_position()

func _unhandled_input(event):
	if not selected:
		return

	if event is InputEventMouseMotion:
		var new_hovered_cell := arena_tilemap.get_hovered_cell(event)
		if hovered_cell == new_hovered_cell:
			return
		hovered_cell = new_hovered_cell
		
		var cell_path := arena_tilemap.get_cell_path(tile_position, hovered_cell)
		if cell_path.size() > 0:
			_update_path_preview(cell_path)
		else:
			_clear_path_preview()
	
	if event is InputEventMouseButton:
		if not event.pressed:
			return
		var clicked_cell := arena_tilemap.get_hovered_cell(event)
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

func _move_sprite_to_tile_position():
	if arena_tilemap and sprite:
		sprite.position = arena_tilemap.map_to_local(tile_position)

## Try to move the selected player to `destination_cell`.
## May move the player less tiles, or zero tiles, if power runs out during the move.
## Ends the turn if power runs out.
func _try_move_selected_player(destination_cell: Vector2i):
	var cell_path := arena_tilemap.get_cell_path(tile_position, destination_cell)
	if cell_path.size() == 0:
		return # there is no valid path
	while cell_path.size() > 0:
		if not turn_state.try_spend_power(1):
			event_log.log('[b][color=%s]%s[/color] tried to move to %s but ran out of power![/b]' % [Constants.team_color(team), debug_name, cell_path[0]])
			selected = false
			return # couldn't afford it, turn has ended
		tile_position = cell_path[0]
		event_log.log('[color=%s]%s[/color] moved to %s' % [Constants.team_color(team), debug_name, cell_path[0]])
		cell_path = cell_path.slice(1)
	_update_selection_tile()
	_clear_path_preview()

func _update_selection_tile():
	selection_tile.visible = selected
	selection_tile.team = turn_state.active_team
	if selected:
		selection_tile.position = arena_tilemap.map_to_local(tile_position)
