extends Label

var arena_tilemap: ArenaTileMap

func _ready():
	arena_tilemap = get_parent()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		text = 'Hovered tile: %s' % arena_tilemap.get_hovered_cell(event)
