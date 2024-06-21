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
var score_state: ScoreState
var control_zones: ControlZones

@onready var graphic: Node2D = $Graphic
@onready var sprite: AnimatedSprite2D = $Graphic/Sprite
@onready var selection_tile: SelectionTile = $Graphic/SelectionTile
@onready var dazed_indicator: CanvasItem = $Graphic/DazedIndicator
@onready var knocked_out_indicator: CanvasItem = $Graphic/KnockedOutIndicator

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

signal is_beacon_changed(player: Player, new_is_beacon: bool)

# Whether the Player is the Beacon, powering all aligned tiles.
@export var is_beacon: bool:
	set(new_is_beacon):
		is_beacon = new_is_beacon
		is_beacon_changed.emit(self, is_beacon)

@export var is_powered: bool:
	get:
		if is_beacon:
			return true
		var beacon_player := players.beacon_for_team(team)
		if not beacon_player:
			return false
		return arena_tilemap.are_cells_aligned(tile_position, beacon_player.tile_position)

# A name, just used for debugging for now
@export var debug_name: String
static var next_id := 1

@export var selected: bool:
	set(new_selected):
		selected = new_selected
		moving = new_selected
		_update_selection_tile()
		if selected:
			was_selected.emit(self)
		else:
			_clear_path_preview()
			was_deselected.emit(self)

@export var moving: bool

var stats := PlayerStats.new()

@export var resolve: int
@export var can_act: bool:
	get:
		return status == Status.OK and not acted_this_turn

@export var acted_this_turn: bool:
	set(new_acted_this_turn):
		acted_this_turn = new_acted_this_turn
		if acted_this_turn:
			selected = false

signal free_moves_remaining_changed(new_remaining: int)
@export var free_moves_remaining := 0:
	set(new_remaining):
		free_moves_remaining = new_remaining
		free_moves_remaining_changed.emit(new_remaining)

signal dashes_used_changed(new_dashes_used: int)
@export var dashes_used := 0:
	set(new_dashes_used):
		dashes_used = new_dashes_used
		dashes_used_changed.emit(new_dashes_used)
		

enum Status { OK, DAZED, KNOCKED_OUT }

@export var status := Status.OK:
	set(new_status):
		status = new_status
		dazed_indicator.visible = new_status == Status.DAZED
		knocked_out_indicator.visible = new_status == Status.KNOCKED_OUT
		_update_selection_tile()


func _ready():
	arena_tilemap = round_root.arena_tilemap
	turn_state = round_root.turn_state
	event_log = round_root.event_log
	score_state = round_root.score_state
	control_zones = round_root.control_zones
	
	players = get_parent()

	debug_name = 'Player %s' % next_id
	next_id += 1
	sprite.self_modulate = Constants.team_color(team)
	_move_graphic_to_tile_position()
	
	resolve = stats.starting_resolve
	
	turn_state.new_turn_started.connect(_turn_state_new_turn_started)
	
	initialized.emit(self)

func _turn_state_new_turn_started(_turn_state: TurnState) -> void:
	_update_selection_tile()
	if turn_state.active_team != team:
		free_moves_remaining = 0
		if status == Status.DAZED:
			status = Status.OK
			event_log.log('%s recovered from being dazed' % BB.player_name(self))
		return
	if can_act:
		if not is_beacon:
			free_moves_remaining = stats.free_moves_per_turn
	dashes_used = 0
	acted_this_turn = false

func _unhandled_input(event):
	if not selected or not moving:
		return

	if event is InputEventMouseMotion:
		var new_hovered_cell := arena_tilemap.get_hovered_cell(event)
		if hovered_cell == new_hovered_cell:
			return
		hovered_cell = new_hovered_cell
		
		if is_beacon and tile_position != hovered_cell and arena_tilemap.are_cells_aligned(tile_position, hovered_cell):
			var hovered_player := players.player_in_cell(hovered_cell)
			if hovered_player and hovered_player.team == team:
				if hovered_player.status == Status.DAZED:
					_update_revive_preview(hovered_player)
				elif hovered_player.status == Status.OK:
					_update_pass_preview(hovered_player)
				return
		
		var cell_path := arena_tilemap.get_cell_path(tile_position, hovered_cell)
		if cell_path.size() > 0:
			_update_path_preview(cell_path)
		else:
			_clear_path_preview()
	
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var clicked_cell := arena_tilemap.get_hovered_cell(event)
			if tile_position == clicked_cell:
				selected = false
				get_viewport().set_input_as_handled()
				return
			if is_beacon and arena_tilemap.are_cells_aligned(tile_position, clicked_cell):
				var clicked_player := players.player_in_cell(clicked_cell)
				if clicked_player and clicked_player.team == team:
					if clicked_player.status == Status.DAZED:
						_try_revive_player(clicked_player)
						get_viewport().set_input_as_handled()
						return
					elif clicked_player.status == Status.OK:
						_try_pass_to_player(clicked_player)
						get_viewport().set_input_as_handled()
						return
			_try_move_selected_player(clicked_cell)

# TODO replace this once move costs are worked out
const DASH_COST := 1
const INCREASED_DASH_COST := 2

func _update_path_preview(cell_path: Array[Vector2i]):
	# TODO retain and re-use the preview tiles for performance?
	_clear_path_preview()
	path_preview = Node2D.new()
	var free_moves_used := 0
	var new_dashes_used := 0
	var total_power_cost := 0
	for cell in cell_path:
		var increased_cost := dashes_used + new_dashes_used >= stats.dashes_before_cost_increase
		if free_moves_used < free_moves_remaining:
			free_moves_used += 1
		else:
			total_power_cost += INCREASED_DASH_COST if increased_cost else DASH_COST
			new_dashes_used += 1
		var preview_tile: PathPreviewTile = path_preview_tile_scene.instantiate()
		preview_tile.position = arena_tilemap.map_to_local(cell)
		preview_tile.power_cost = total_power_cost
		preview_tile.increased_cost = increased_cost
		preview_tile.success_chance = turn_state.chance_that_power_available(total_power_cost)
		path_preview.add_child(preview_tile)
	add_child(path_preview)

func _update_revive_preview(revivable_player: Player) -> void:
	_clear_path_preview()
	path_preview = Node2D.new()
	var preview_tile: PathPreviewTile = path_preview_tile_scene.instantiate()
	preview_tile.position = arena_tilemap.map_to_local(revivable_player.tile_position)
	preview_tile.power_cost = revivable_player.stats.dazed_revive_cost
	preview_tile.success_chance = turn_state.chance_that_power_available(preview_tile.power_cost)
	path_preview.add_child(preview_tile)
	add_child(path_preview)

func _update_pass_preview(receiving_player: Player) -> void:
	_clear_path_preview()
	path_preview = Node2D.new()
	var preview_tile: PathPreviewTile = path_preview_tile_scene.instantiate()
	preview_tile.position = arena_tilemap.map_to_local(receiving_player.tile_position)
	preview_tile.power_cost = stats.pass_cost
	preview_tile.success_chance = turn_state.chance_that_power_available(preview_tile.power_cost)
	path_preview.add_child(preview_tile)
	add_child(path_preview)

func _clear_path_preview():
	if path_preview:
		path_preview.queue_free()
	path_preview = null

func _move_graphic_to_tile_position():
	if arena_tilemap and graphic:
		graphic.position = arena_tilemap.map_to_local(tile_position)

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
		if free_moves_remaining > 0:
			free_moves_remaining -= 1
		else:
			var dash_cost := DASH_COST if dashes_used < stats.dashes_before_cost_increase else INCREASED_DASH_COST
			if not turn_state.try_spend_power(dash_cost):
				if walked_path.size() == 0:
					event_log.log('%s tried to move but ran out of power!' % BB.player_name(self))
				else:
					event_log.log('%s ran out of power after spending %s⚡ to move %s spaces!' % [BB.player_name(self), power_spent, walked_path.size()])
				selected = false
				break
			power_spent += dash_cost
			dashes_used += 1
		walked_path.push_back(cell_path[0])
		cell_path = cell_path.slice(1)
	if walked_path.size() > 0:
		walk_path(walked_path)
	if selected:
		event_log.log('%s spent %s⚡ to move %s spaces' % [BB.player_name(self), power_spent, walked_path.size()])
		_update_selection_tile()
		_clear_path_preview()

func _update_selection_tile():
	if turn_state.active_team != team:
		selection_tile.visible = false
		return
	selection_tile.visible = true
	if not can_act:
		selection_tile.mode = SelectionTile.Mode.CANNOT_ACT
	elif selected:
		selection_tile.mode = SelectionTile.Mode.THICK
	else:
		selection_tile.mode = SelectionTile.Mode.DEFAULT

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

func _try_revive_player(revivable_player: Player) -> void:
	var power_cost := revivable_player.stats.dazed_revive_cost
	if not turn_state.try_spend_power(power_cost):
		event_log.log('%s tried to revive %s but ran out of power!' % [BB.player_name(self), BB.player_name(revivable_player)])
		return
	revivable_player.revive()
	event_log.log('%s spent %s⚡ to revive %s' % [BB.player_name(self), power_cost, BB.player_name(revivable_player)])
	_clear_path_preview()

func _try_pass_to_player(receiving_player: Player) -> void:
	var power_cost := stats.pass_cost
	if not turn_state.try_spend_power(power_cost):
		event_log.log('%s tried to pass the beacon to %s but ran out of power!' % [BB.player_name(self), BB.player_name(receiving_player)])
		return
	is_beacon = false
	receiving_player.is_beacon = true
	event_log.log('%s spent %s⚡ to pass the beacon to %s' % [BB.player_name(self), power_cost, BB.player_name(receiving_player)])
	# they probably don't want the old ball carrier still selected
	acted_this_turn = true

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
		take_damage(resolve)

func take_damage(damage: int) -> void:
	var damage_absorbed_by_resolve := mini(resolve, damage)
	resolve -= damage_absorbed_by_resolve
	
	taken_damage.emit(self, damage)
	
	var remaining_damage := damage - damage_absorbed_by_resolve
	var status_changed := false
	if remaining_damage > 0 and status == Status.OK:
		remaining_damage -= 1
		status = Status.DAZED
		status_changed = true
	if remaining_damage > 0 and status == Status.DAZED:
		remaining_damage -= 1
		status = Status.KNOCKED_OUT
		status_changed = true
	if remaining_damage > 0:
		# longer-term wounds
		pass
	
	if status_changed and status == Status.DAZED:
		event_log.log.call_deferred('%s is dazed!' % [BB.player_name(self)])
	elif status_changed and status == Status.KNOCKED_OUT:
		event_log.log.call_deferred('%s was knocked unconscious!' % [BB.player_name(self)])
		if is_beacon:
			score_state.score_points(Constants.other_team(team), Constants.POINTS_FOR_SACKING_BEACON)
			round_root.end_round()

func revive() -> void:
	status = Status.OK
	free_moves_remaining = stats.free_moves_per_turn
