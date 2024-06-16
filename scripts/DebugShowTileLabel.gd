extends Label

@export var arena_tilemap: ArenaTileMap

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		text = 'Hovered tile: %s' % arena_tilemap.get_hovered_cell(event)
