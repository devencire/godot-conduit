class_name PoweredTiles

extends Node

@onready var arena_tilemap: ArenaTileMap = %ArenaTileMap
@onready var players: Players = %Players
@onready var turn_state: TurnState = %TurnState

var powered_tile_scene := preload("res://scenes/powered_tile.tscn")
var powered_tile_container: Node2D

var pulse_tween: Tween

func _on_players_changed(_players: Players):
	draw_powered_tiles()

func _on_turn_state_new_turn_started(_state: TurnState):
	draw_powered_tiles() # bleh probably shouldn't use % for this

func draw_powered_tiles():
	var powered_cell_teams := {}  # Dictionary[Vector2i, Constants.Team]
	for player in players.all_players:
		if player.is_beacon:
			var aligned_cells := arena_tilemap.get_aligned_cells(player.tile_position)
			for cell in aligned_cells:
				if powered_cell_teams.has(cell):
					# if a cell is powered by both teams, draw a mixed color
					powered_cell_teams[cell] = Constants.Team.NONE
				else:
					powered_cell_teams[cell] = player.team

	if powered_tile_container:
		powered_tile_container.queue_free()
		
	powered_tile_container = Node2D.new()
	var active_team_container := Node2D.new()
	var other_team_container := Node2D.new()
	for cell in powered_cell_teams:
		var powered_tile: PoweredTile = powered_tile_scene.instantiate()
		powered_tile.position = arena_tilemap.map_to_local(cell)
		powered_tile.team = powered_cell_teams[cell]
		if powered_tile.team == turn_state.active_team or powered_tile.team == Constants.Team.NONE:
			active_team_container.add_child(powered_tile)
		else:
			other_team_container.add_child(powered_tile)
	powered_tile_container.add_child(active_team_container)
	powered_tile_container.add_child(other_team_container)
	add_child(powered_tile_container)
	
	if pulse_tween:
		pulse_tween.kill() # I hope this means it gets freed
	
	pulse_tween = create_tween()
	pulse_tween.tween_property(active_team_container, 'modulate', Color.hex(0xffffffa0), 1).set_trans(Tween.TRANS_BOUNCE)
	pulse_tween.tween_property(active_team_container, 'modulate', Color.hex(0xffffffff), 1).set_trans(Tween.TRANS_BOUNCE)
	pulse_tween.set_loops()
	
	other_team_container.modulate = Color.hex(0xffffff80)
