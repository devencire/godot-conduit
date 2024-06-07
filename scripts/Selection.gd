class_name Selection

extends Node

@onready var arena_tilemap: ArenaTileMap = %ArenaTileMap
@onready var turn_state: TurnState = %TurnState

var selected_player: Player

func _unhandled_input(event):
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
