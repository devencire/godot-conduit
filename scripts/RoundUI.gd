class_name RoundUI

extends Node

@onready var team_indicator: Label = $VBoxContainer/TeamIndicator
@onready var copied_excess_power: Label = $VBoxContainer/CopiedExcessPower
@onready var base_turn_power: Label = $VBoxContainer/BaseTurnPower
@onready var maximum_random_power: Label = $VBoxContainer/MaximumRandomPower
@onready var known_remaining_power: Label = $VBoxContainer/KnownRemainingPower
@onready var maximum_remaining_power: Label = $VBoxContainer/MaximumRemainingPower
@onready var actual_remaining_power: Label = $VBoxContainer/ActualRemainingPower
@onready var end_turn_button: Button = $VBoxContainer/EndTurnButton

# hold a reference to the TurnState so we can send instructions back
# TODO something less bad
var turn_state: TurnState

func _on_turn_state_changed(state: TurnState):
	turn_state = state
		
	# we seem to get told about the first turn before we're ready, so just wait a tick
	if not team_indicator:
		_on_turn_state_changed.call_deferred(state)
		return
	
	team_indicator.text = "It is Team %s's turn" % Constants.team_name(state.active_team)
	team_indicator.label_settings.font_color = Constants.team_color(state.active_team)
	
	copied_excess_power.text = "Copied excess power: %s⚡" % state.copied_excess_power
	base_turn_power.text = "Base turn power: %s⚡" % state.base_turn_power
	maximum_random_power.text = "Maximum random power: %s⚡" % Constants.MAX_EXCESS_POWER
	
	known_remaining_power.text = "Known remaining power: %s⚡" % maxi(
		0,
		state.copied_excess_power + state.base_turn_power - state.power_used
	)
	maximum_remaining_power.text = "Maximum possible remaining power: %s⚡" % (
		state.copied_excess_power + state.base_turn_power + Constants.MAX_EXCESS_POWER - state.power_used
	)
	actual_remaining_power.text = "Actual remaining power: %s⚡" % (
		state.total_available_power - state.power_used
	)


func _on_end_turn_button_pressed():
	if turn_state:
		turn_state.end_turn()
