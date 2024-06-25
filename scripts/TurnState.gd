class_name TurnState

extends Node

signal changed(state: TurnState)
signal new_turn_started(state: TurnState)

@export var active_team: Constants.Team

@export var power_used: int = 0
@export var total_available_power: int
@export var copied_excess_power: int
@export var base_turn_power: int

@export var known_remaining_power: int:
	get:
		return copied_excess_power + base_turn_power - power_used

@export var max_remaining_power: int:
	get:
		return known_remaining_power + Constants.MAX_EXCESS_POWER

@export var actual_remaining_power: int:
	get:
		return total_available_power - power_used

var round_is_over: bool

## Starts a new turn for the given `team`.
func start_turn(team: Constants.Team) -> void:
	if round_is_over:
		return
	
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
	
	%EventLog.log('[b]%s starts their turn with %s-%s⚡ available[/b]' % [BB.team_name(team), known_remaining_power, max_remaining_power])
	
	changed.emit(self)
	new_turn_started.emit(self)

## Spends the `amount` of power and returns `true`,
## or if there's not enough power, starts the opposing team's turn and returns `false`.
func try_spend_power(amount: int) -> bool:
	if power_used + amount > total_available_power:
		# TODO: using call_deferred to time this is very very dodgy, do something better
		start_turn.call_deferred(Constants.other_team(active_team))
		return false
	else:
		power_used += amount
		changed.emit(self)
		return true

# Returns the probability of the turn containing enough power for an action costing `power_cost`, between 0 and 1.
func chance_that_power_available(power_cost: int) -> float:
	var unknown_power_use := power_cost - known_remaining_power
	if unknown_power_use <= 0:
		return 1.0
	if max_remaining_power < power_cost:
		return 0.0
	return 1.0 - (float(power_cost - maxi(0, known_remaining_power)) / (mini(Constants.MAX_EXCESS_POWER, max_remaining_power) + 1))

## Ends the current turn and starts the opposing team's turn.
func end_turn() -> void:
	start_turn(Constants.other_team(active_team))

func _on_round_root_round_ended(_round_root: RoundRoot):
	round_is_over = true
