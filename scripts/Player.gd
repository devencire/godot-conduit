class_name Player

extends Node

var arena_tilemap: ArenaTileMap
@onready var sprite: AnimatedSprite2D = $Sprite

# Where the Player is in the ArenaTileMap, in tile coordinates.
@export var tile_position: Vector2i:
	set(new_tile_position):
		tile_position = new_tile_position
		move_sprite_to_tile_position()
		if arena_tilemap:
			arena_tilemap.update_obstacles()
		

func _ready():
	arena_tilemap = find_parent('ArenaTileMap')
	move_sprite_to_tile_position()
	
func move_sprite_to_tile_position():
	if arena_tilemap and sprite:
		sprite.position = arena_tilemap.map_to_local(tile_position)

func on_select():
	print(self, ' has been selected')

func on_deselect():
	print(self, ' has been deselected')
