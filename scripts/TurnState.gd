class_name TurnState

extends Node

signal changed(state: TurnState)
signal new_turn_started(state: TurnState)

@export var active_team: Constants.Team

@export var power_used: int = 0
@export var total_available_power: int
@export var copied_excess_power: int
@export var base_turn_power: int

## Starts a new turn for the given `team`.
func start_turn(team: Constants.Team) -> void:
	active_team = team
	
	# A team's available power for a turn is
	# the excess power their opponent used last turn
	var excess_power_used := maxi(0, power_used - copied_excess_power - base_turn_power)
	copied_excess_power = excess_power_used
	# + a base, known amount of power
	base_turn_power = Constants.BASE_TURN_POWER # maybe this should increase each turn?
	# + a secret random amount of excess power (not shown on the UI)
	var secret_available_excess_power := randi_range(0, Constants.MAX_EXCESS_POWER)
	
	total_available_power = copied_excess_power + base_turn_power + secret_available_excess_power
	power_used = 0
	
	changed.emit(self)
	new_turn_started.emit(self)

## Spends the `amount` of power and returns `true`,
## or if there's not enough power, starts the opposing team's turn and returns `false`.
func try_spend_power(amount: int) -> bool:
	if power_used + amount > total_available_power:
		start_turn(Constants.other_team(active_team))
		return false
	else:
		power_used += amount
		changed.emit(self)
		return true

## Ends the current turn and starts the opposing team's turn.
func end_turn() -> void:
	start_turn(Constants.other_team(active_team))
