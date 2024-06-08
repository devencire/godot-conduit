class_name TargetPreviewTile

extends Node2D

@onready var sprite: AnimatedSprite2D = $Sprite

enum PreviewTileType { BLANK, ARROW }

@export var team: Constants.Team:
	set(new_team):
		team = new_team
		update_color()

@export var type: PreviewTileType:
	set(new_type):
		type = new_type
		match new_type:
			PreviewTileType.BLANK:
				$Sprite.animation = 'blank'
			PreviewTileType.ARROW:
				$Sprite.animation = 'arrow'

@export var direction: TileSet.CellNeighbor:
	set(new_direction):
		direction = new_direction
		match new_direction:
			TileSet.CELL_NEIGHBOR_TOP_SIDE:
				$Sprite.rotation_degrees = 0
			TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE:
				$Sprite.rotation_degrees = 60
			TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE:
				$Sprite.rotation_degrees = 120
			TileSet.CELL_NEIGHBOR_BOTTOM_SIDE:
				$Sprite.rotation_degrees = 180
			TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE:
				$Sprite.rotation_degrees = 240
			TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE:
				$Sprite.rotation_degrees = 300

func update_color():
	$Sprite.modulate = Constants.team_color(team)
