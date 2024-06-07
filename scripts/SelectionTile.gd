class_name SelectionTile

extends Node2D

@export var team: Constants.Team:
	set(new_team):
		team = new_team
		update_color()

func _ready():
	pass

func update_color():
	$Sprite.modulate = Constants.team_color(team)
