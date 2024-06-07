class_name TurnState

extends Node

signal changed(state: TurnState)

@export var active_team: Constants.Team

@export var power_used: int = 0
@export var total_available_power: int
@export var copied_excess_power: int
@export var base_turn_power: int

func _ready():
	start_turn(Constants.Team.ONE)

func start_turn(team: Constants.Team) -> void:
	active_team = team
	
	# A team's available power for a turn is
	# the excess power their opponent used last turn
	var excess_power_used := power_used - copied_excess_power - base_turn_power
	copied_excess_power = excess_power_used
	# + a base, known amount of power
	base_turn_power = Constants.BASE_TURN_POWER # maybe this should increase each turn?
	# + a secret random amount of excess power (not shown on the UI)
	var secret_available_excess_power := randi_range(0, Constants.MAX_EXCESS_POWER)
	
	total_available_power = copied_excess_power + base_turn_power + secret_available_excess_power
	
	changed.emit(self)
