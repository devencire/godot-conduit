class_name PoweredTiles

extends Node

var arena_tilemap: ArenaTileMap

var powered_tile_scene := preload("res://scenes/powered_tile.tscn")
var powered_tile_container: Node

func _ready():
	arena_tilemap = find_parent('ArenaTileMap') as ArenaTileMap

func _on_players_changed(players: Array[Player]):
	draw_powered_tiles(players)

func draw_powered_tiles(players: Array[Player]):
	var powered_cell_teams := {}  # Dictionary[Vector2i, Constants.Team]
	for player in players:
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
		
	powered_tile_container = Node.new()
	for cell in powered_cell_teams:
		var powered_tile: PoweredTile = powered_tile_scene.instantiate()
		powered_tile.position = arena_tilemap.map_to_local(cell)
		powered_tile.team = powered_cell_teams[cell]
		powered_tile_container.add_child(powered_tile)
	add_child(powered_tile_container)
