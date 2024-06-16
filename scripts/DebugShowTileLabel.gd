extends Label

@export var arena_tilemap: ArenaTileMap

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		var cell := arena_tilemap.get_hovered_cell(event)
		text = 'Hovered tile: %s (%s)' % [cell, arena_tilemap.distance_from_halfway_line(cell)]
