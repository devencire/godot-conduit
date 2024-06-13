class_name Selection

extends Node

@onready var arena_tilemap: ArenaTileMap = %ArenaTileMap
@onready var turn_state: TurnState = %TurnState
@onready var players: Players = %Players

var selected_player: Player

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if not event.pressed:
			return
		var clicked_cell := arena_tilemap.get_hovered_cell(event)
		var player := players.player_in_cell(clicked_cell, turn_state.active_team)
		if player and player.can_act:
			_select_player(player)

func _select_player(player: Player):
	if player == selected_player:
		return # already selected, nothing to do
	_deselect_player()
	selected_player = player
	selected_player.selected = true
	
func _deselect_player():
	if not selected_player:
		return
	selected_player.selected = false
	selected_player = null


func _on_turn_state_new_turn_started(state):
	_deselect_player.call_deferred()
