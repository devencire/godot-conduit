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
var popups: Popups

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
        if is_beacon:
            free_moves_remaining = 0
        is_beacon_changed.emit(self, is_beacon)

signal is_powered_changed(player: Player, new_is_powered: bool)

@export var is_powered: bool:
    set(new_is_powered):
        is_powered = new_is_powered
        is_powered_changed.emit(self, is_powered)

# A name, just used for debugging for now
@export var debug_name: String
static var next_id := 1

@export var selected: bool:
    set(new_selected):
        selected = new_selected
        moving = new_selected
        if selected:
            was_selected.emit(self)
        else:
            _clear_path_preview()
            was_deselected.emit(self)

@export var moving: bool

@export var weapon: Weapon
@export var stats := PlayerStats.new()

@export var resolve: int
@export var can_act: bool:
    get:
        return status == Status.OK and not acted_this_turn

@export var conscious: bool:
    get:
        return status != Status.KNOCKED_OUT

signal acted_this_turn_changed(player: Player, now_acted: bool)
@export var acted_this_turn: bool:
    set(new_acted_this_turn):
        acted_this_turn = new_acted_this_turn
        acted_this_turn_changed.emit(self, new_acted_this_turn)
        if acted_this_turn:
            selected = false

signal is_on_active_team_changed(now_active: bool)
@export var is_on_active_team: bool:
    set(now_active):
        is_on_active_team = now_active
        is_on_active_team_changed.emit(now_active)

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

signal status_changed(player: Player, new_status: Status)
@export var status := Status.OK:
    set(new_status):
        status = new_status
        status_changed.emit(self, new_status)


func _ready():
    arena_tilemap = round_root.arena_tilemap
    turn_state = round_root.turn_state
    event_log = round_root.event_log
    score_state = round_root.score_state
    control_zones = round_root.control_zones
    popups = round_root.popups

    players = get_parent()

    debug_name = 'Player %s' % next_id
    next_id += 1
    sprite.self_modulate = Constants.team_color(team)
    _move_graphic_to_tile_position()

    resolve = stats.starting_resolve

    turn_state.new_turn_started.connect(_turn_state_new_turn_started)

    initialized.emit(self)

func _turn_state_new_turn_started(_turn_state: TurnState) -> void:
    if turn_state.active_team == team:
        acted_this_turn = false
        if can_act:
            if not is_beacon:
                free_moves_remaining = stats.free_moves_per_turn
        dashes_used = 0
    else:
        free_moves_remaining = 0
        dashes_used = 0
        if status == Status.DAZED:
            status = Status.OK
            event_log.log('%s recovered from being dazed' % BB.player_name(self))
    is_on_active_team = turn_state.active_team == team

func _unhandled_input(event: InputEvent):
    if event is InputEventMouseMotion:
        var new_hovered_cell := arena_tilemap.get_hovered_cell(event)
        if hovered_cell == new_hovered_cell:
            return
        hovered_cell = new_hovered_cell

        if not selected or not moving:
            if status == Status.DAZED:
                if team == turn_state.active_team and tile_position == hovered_cell and is_powered:
                    _update_revive_preview()
                else:
                    _clear_path_preview()
            return

        if is_beacon and tile_position != hovered_cell and arena_tilemap.are_cells_aligned(tile_position, hovered_cell):
            var hovered_player := players.player_in_cell(hovered_cell)
            if hovered_player and hovered_player.team == team and hovered_player.status == Status.OK:
                _update_pass_preview(hovered_player)
                return

        var cell_path := arena_tilemap.get_cell_path(tile_position, hovered_cell)
        if cell_path.size() > 0:
            _update_path_preview(cell_path)
        else:
            _clear_path_preview()

    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
            _handle_right_click(event)

func _handle_right_click(event: InputEventMouseButton) -> void:
    var clicked_cell := arena_tilemap.get_hovered_cell(event)

    if not selected or not moving:
        if team == turn_state.active_team and status == Status.DAZED and is_powered and clicked_cell == tile_position:
            _try_revive_player()
            get_viewport().set_input_as_handled()
            return
        return

    if tile_position == clicked_cell:
        selected = false
        get_viewport().set_input_as_handled()
        return
    if is_beacon and arena_tilemap.are_cells_aligned(tile_position, clicked_cell):
        var clicked_player := players.player_in_cell(clicked_cell)
        if clicked_player and clicked_player.team == team and clicked_player.status == Status.OK:
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

func _update_revive_preview() -> void:
    _clear_path_preview()
    path_preview = Node2D.new()
    var preview_tile: PathPreviewTile = path_preview_tile_scene.instantiate()
    preview_tile.position = arena_tilemap.map_to_local(tile_position)
    preview_tile.power_cost = stats.dazed_revive_cost
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
    var power_costs: Array[int] = []
    var power_spent := 0
    while cell_path.size() > 0:
        if free_moves_remaining > 0:
            free_moves_remaining -= 1
            power_costs.push_back(0)
        else:
            var dash_cost := DASH_COST if dashes_used < stats.dashes_before_cost_increase else INCREASED_DASH_COST
            power_costs.push_back(dash_cost)
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
        walk_path(walked_path, power_costs)
    if selected:
        event_log.log('%s spent %s⚡ to move %s spaces' % [BB.player_name(self), power_spent, walked_path.size()])
        _clear_path_preview()

var tween: Tween

const WALK_DURATION_PER_TILE := 0.2

func walk_path(cell_path: Array[Vector2i], power_costs: Array[int]) -> void:
    # TEMP: reset the position so we're always animating from the last true location
    _move_graphic_to_tile_position()
    if tween:
        tween.kill()
    tween = create_tween()
    for idx in range(cell_path.size()):
        var cell := cell_path[idx]
        var position := arena_tilemap.map_to_local(cell)
        tween.tween_property(graphic, 'position', position, WALK_DURATION_PER_TILE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        var power_cost := power_costs[idx]
        if power_cost > 0:
            tween.tween_callback(_spawn_popup_at_sprite.bind("-%s⚡" % power_cost))
    tile_position = cell_path.back()

func _spawn_popup_at_sprite(text: String) -> void:
    popups.spawn_resource_popup(text, graphic.position - Vector2(0, 60))

func _try_revive_player() -> void:
    var power_cost := stats.dazed_revive_cost
    if not turn_state.try_spend_power(power_cost):
        event_log.log('%s tried to recover from being dazed but ran out of power!' % [BB.player_name(self)])
        return
    revive()
    event_log.log('%s spent %s⚡ to recover from being dazed' % [BB.player_name(self), power_cost])
    _spawn_popup_at_sprite("-%s⚡" % power_cost)
    _clear_path_preview()

func _try_pass_to_player(receiving_player: Player) -> void:
    var power_cost := stats.pass_cost
    if not turn_state.try_spend_power(power_cost):
        event_log.log('%s tried to pass the beacon to %s but ran out of power and dropped it!' % [BB.player_name(self), BB.player_name(receiving_player)])
        round_root.end_round()
        score_state.score_points(Constants.other_team(team), Constants.POINTS_FOR_SACKING_BEACON)
        return
    is_beacon = false
    receiving_player.is_beacon = true
    event_log.log('%s spent %s⚡ to pass the beacon to %s' % [BB.player_name(self), power_cost, BB.player_name(receiving_player)])
    _spawn_popup_at_sprite("-%s⚡" % power_cost)
    acted_this_turn = true

const PUSH_DURATION := 0.2

func push_to(cell: Vector2i, pusher: Player) -> void:
    # TEMP: reset the position so we're always animating from the last true location
    _move_graphic_to_tile_position()
    if tween:
        tween.kill()
    tween = create_tween()
    var position := arena_tilemap.map_to_local(cell)
    tween.tween_property(graphic, 'position', position, PUSH_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    tile_position = cell
    if not arena_tilemap.is_cell_pathable(cell):
        take_damage(DamageSource.OutOfArena.new(pusher))

func daze_if_not_dazed() -> void:
    if status == Status.OK:
        status = Status.DAZED
        event_log.log('%s is dazed!' % [BB.player_name(self)])

func take_damage(source: DamageSource) -> void:
    var remaining_damage := source.amount
    if not source.pierces_resolve:
        var damage_absorbed_by_resolve := mini(resolve, remaining_damage)
        resolve -= damage_absorbed_by_resolve
        remaining_damage -= damage_absorbed_by_resolve

    event_log.log('%s took %s damage %s' % [BB.player_name(self), source.amount, source.display_text])
    taken_damage.emit(self, source.amount)

    var status_altered := false
    if remaining_damage > 0 and status == Status.OK:
        remaining_damage -= 1
        status = Status.DAZED
        status_altered = true
    if remaining_damage > 0 and status == Status.DAZED:
        remaining_damage -= 1
        status = Status.KNOCKED_OUT
        status_altered = true
    if remaining_damage > 0:
        # longer-term wounds
        pass

    if status_altered and status == Status.DAZED:
        event_log.log('%s is dazed by damage' % [BB.player_name(self)])
    elif status_altered and status == Status.KNOCKED_OUT:
        event_log.log('%s was knocked unconscious by damage!' % [BB.player_name(self)])
        if is_beacon:
            round_root.end_round()
            score_state.score_points(Constants.other_team(team), Constants.POINTS_FOR_SACKING_BEACON)

enum PushOutcomeType { MOVED_TO, INTO_WALL, CLASHED_WITH, OUT_OF_ARENA }

class PushOutcome:
    var player: Player
    var type: PushOutcomeType
    var distance: int
    var clashed_with: Player

func report_outcome(outcome: PushOutcome) -> void:
    match outcome.type:
        PushOutcomeType.MOVED_TO:
            event_log.log('%s pushed %s back %s spaces' % [BB.player_name(self), BB.player_name(outcome.player), outcome.distance])
        PushOutcomeType.INTO_WALL:
            if outcome.distance > 0:
                event_log.log('%s pushed %s back %s spaces into a wall' % [BB.player_name(self), BB.player_name(outcome.player), outcome.distance])
            else:
                event_log.log('%s pushed %s back into a wall' % [BB.player_name(self), BB.player_name(outcome.player)])
        PushOutcomeType.CLASHED_WITH:
            event_log.log('%s pushed %s back %s spaces into %s' % [BB.player_name(self), BB.player_name(outcome.player), outcome.distance, BB.player_name(outcome.clashed_with)])
        PushOutcomeType.OUT_OF_ARENA:
            event_log.log('%s pushed %s back %s spaces, off the arena!' % [BB.player_name(self), BB.player_name(outcome.player), outcome.distance])

func resolve_push(target: Player, direction: TileSet.CellNeighbor, force: int) -> void:
    var current_cell := target.tile_position
    var distance := 0
    var clashed_with: Player = null
    while force > 0:
        distance += 1
        var previous_cell := current_cell
        current_cell = arena_tilemap.get_neighbor_cell(current_cell, direction)
        if not arena_tilemap.is_cell_pathable(current_cell):
            if arena_tilemap.is_cell_wall(current_cell):
                target.push_to(previous_cell, self)
                var wall_push_outcome := PushOutcome.new()
                wall_push_outcome.player = target
                wall_push_outcome.type = PushOutcomeType.INTO_WALL
                wall_push_outcome.distance = distance - 1
                report_outcome(wall_push_outcome)
                target.take_damage(DamageSource.PushedIntoWall.new(self, force))
                return
            else:
                var ooa_push_outcome := PushOutcome.new()
                ooa_push_outcome.player = target
                ooa_push_outcome.type = PushOutcomeType.OUT_OF_ARENA
                ooa_push_outcome.distance = distance
                report_outcome(ooa_push_outcome)
                break
        var player_in_next_cell := players.player_in_cell(current_cell)
        if player_in_next_cell:
            # defer the damage until after we report the push
            clashed_with = player_in_next_cell
            break
        # we've used up some force, we'll loop to push further if force remains
        force -= 1

    target.push_to(current_cell, self)

    var push_outcome := PushOutcome.new()
    push_outcome.player = target
    if clashed_with:
        push_outcome.type = PushOutcomeType.CLASHED_WITH
        push_outcome.clashed_with = clashed_with
    else:
        push_outcome.type = PushOutcomeType.MOVED_TO
    push_outcome.distance = distance
    report_outcome(push_outcome)

    if clashed_with:
        # damage the original player now
        target.take_damage(DamageSource.PushedIntoPlayer.new(self, clashed_with))
        # also damage the player they clashed with
        clashed_with.take_damage(DamageSource.HitByPushedPlayer.new(self, target))
        # now also push the player already in that cell, transferring all remaining force to them
        # use up an extra force (absorbed by the impact?) so that the preview is accurate to the final victim's final location
        resolve_push(clashed_with, direction, maxi(force - 1, 1))

func revive() -> void:
    status = Status.OK
    free_moves_remaining = stats.free_moves_per_turn
