class_name Player

extends Node

var arena_tilemap: ArenaTileMap
var players: Players
@onready var sprite: AnimatedSprite2D = $Sprite

# Which team the player is a member of.
@export var team: Constants.Team

# Where the Player is in the ArenaTileMap, in tile coordinates.
@export var tile_position: Vector2i:
	set(new_tile_position):
		tile_position = new_tile_position
		move_sprite_to_tile_position()
		if players:
			players.player_moved()

# Whether the Player is the Beacon, powering all aligned tiles.
@export var is_beacon: bool

func _ready():
	sprite.modulate = Constants.team_color(team)

	players = get_parent()
	arena_tilemap = find_parent('ArenaTileMap')
	move_sprite_to_tile_position()
	
func move_sprite_to_tile_position():
	if arena_tilemap and sprite:
		sprite.position = arena_tilemap.map_to_local(tile_position)

func on_select():
	print(self, ' has been selected')

func on_deselect():
	print(self, ' has been deselected')
