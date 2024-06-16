class_name Player

extends Node

signal was_moved(player: Player)
signal was_selected(player: Player)
signal was_deselected(player: Player)

signal initialized(player: Player)
signal taken_damage(player: Player, damage: int)

var players: Players

@export var round_root: RoundRoot
var arena_tilemap: ArenaTileMap
var turn_state: TurnState
var event_log: EventLog

@onready var graphic: Node2D = $Graphic
@onready var sprite: AnimatedSprite2D = $Graphic/Sprite
@onready var selection_tile: SelectionTile = $SelectionTile

var hovered_cell: Vector2i
var path_preview_tile_scene := preload("res://scenes/path_preview_tile.tscn")
var path_preview: Node2D

# Which team the player is a member of.
@export var team: Constants.Team

# Where the Player is in the ArenaTileMap, in tile coordinates.
@export var tile_position: Vector2i:
	set(new_tile_position):
		tile_position = new_tile_position
		was_moved.emit(self)

# Whether the Player is the Beacon, powering all aligned tiles.
@export var is_beacon: bool

# A name, just used for debugging for now
@export var debug_name: String
static var next_id := 1

@export var selected: bool:
	set(new_selected):
		selected = new_selected
		moving = true
		_update_selection_tile()
		if selected:
			was_selected.emit(self)
		else:
			_clear_path_preview()
			was_deselected.emit(self)

@export var moving: bool

@export var max_health: int = 4
@export var health: int
@export var can_act: bool:
	get:
		return health > 0


func _ready():
	arena_tilemap = round_root.arena_tilemap
	turn_state = round_root.turn_state
	event_log = round_root.event_log
	
	players = get_parent()

	debug_name = 'Player %s' % next_id
	next_id += 1
	sprite.self_modulate = Constants.team_color(team)
	_move_graphic_to_tile_position()
	
	health = max_health
	initialized.emit(self)

func _unhandled_input(event):
	if not selected or not moving:
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
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var clicked_cell := arena_tilemap.get_hovered_cell(event)
			_try_move_selected_player(clicked_cell)

# TODO replace this once move costs are worked out
const MOVE_COST := 1

func _update_path_preview(cell_path: Array[Vector2i]):
	# TODO retain and re-use the preview tiles for performance?
	_clear_path_preview()
	path_preview = Node2D.new()
	var total_power_cost := 0
	for cell in cell_path:
		total_power_cost += MOVE_COST
		var preview_tile: PathPreviewTile = path_preview_tile_scene.instantiate()
		preview_tile.position = arena_tilemap.map_to_local(cell)
		preview_tile.power_cost = total_power_cost
		preview_tile.success_chance = turn_state.chance_that_power_available(total_power_cost)
		path_preview.add_child(preview_tile)
	add_child(path_preview)

func _clear_path_preview():
	if path_preview:
		path_preview.queue_free()
	path_preview = null

func _move_graphic_to_tile_position():
	if arena_tilemap and graphic:
		graphic.position = arena_tilemap.map_to_local(tile_position)

const BASE_MOVE_COST := 1

## Try to move the selected player to `destination_cell`.
## May move the player less tiles, or zero tiles, if power runs out during the move.
## Ends the turn if power runs out.
func _try_move_selected_player(destination_cell: Vector2i):
	var cell_path := arena_tilemap.get_cell_path(tile_position, destination_cell)
	if cell_path.size() == 0:
		return # there is no valid path
	var walked_path: Array[Vector2i] = []
	var power_spent := 0
	while cell_path.size() > 0:
		if not turn_state.try_spend_power(BASE_MOVE_COST):
			if walked_path.size() == 0:
				event_log.log('%s tried to move but ran out of power!' % Constants.bbcode_player_name(self))
			else:
				event_log.log('%s ran out of power after spending %s⚡ to move %s spaces!' % [Constants.bbcode_player_name(self), power_spent, walked_path.size()])
			selected = false
			break
		power_spent += BASE_MOVE_COST
		walked_path.push_back(cell_path[0])
		cell_path = cell_path.slice(1)
	if walked_path.size() > 0:
		walk_path(walked_path)
	if selected:
		event_log.log('%s spent %s⚡ to move %s spaces' % [Constants.bbcode_player_name(self), power_spent, walked_path.size()])
		_update_selection_tile()
		_clear_path_preview()

func _update_selection_tile():
	selection_tile.visible = selected
	selection_tile.team = turn_state.active_team
	if selected:
		selection_tile.position = arena_tilemap.map_to_local(tile_position)

func is_powered_by_team_beacon() -> bool:
	if is_beacon:
		return true
	var beacon_player := players.beacon_for_team(team)
	if not beacon_player:
		return false
	return arena_tilemap.are_cells_aligned(tile_position, beacon_player.tile_position)

var tween: Tween

const WALK_DURATION_PER_TILE := 0.2

func walk_path(cell_path: Array[Vector2i]) -> void:
	# TEMP: reset the position so we're always animating from the last true location
	_move_graphic_to_tile_position()
	if tween:
		tween.kill()
	tween = create_tween()
	for cell in cell_path:
		var position := arena_tilemap.map_to_local(cell)
		tween.tween_property(graphic, 'position', position, WALK_DURATION_PER_TILE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tile_position = cell_path.back()

const PUSH_DURATION := 0.2

func push_to(cell: Vector2i) -> void:
	# TEMP: reset the position so we're always animating from the last true location
	_move_graphic_to_tile_position()
	if tween:
		tween.kill()
	tween = create_tween()
	var position := arena_tilemap.map_to_local(cell)
	tween.tween_property(graphic, 'position', position, PUSH_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if arena_tilemap.is_cell_pathable(cell):
		tile_position = cell
	else:
		tile_position = Constants.OFF_ARENA
		take_damage(health)

func take_damage(damage: int) -> void:
	health = maxi(0, health - damage)
	taken_damage.emit(self, damage)
	if health == 0:
		event_log.log.call_deferred('%s was knocked unconscious!' % [Constants.bbcode_player_name(self)])
