extends Node

func _on_turn_state_changed(state: TurnState):
	$CopiedExcessPower.text = "Copied excess power: %s" % state.copied_excess_power
	$BaseTurnPower.text = "Base turn power: %s" % state.base_turn_power
	$MaximumRandomPower.text = "Maximum random power: %s" % Constants.MAX_EXCESS_POWER
	
	$KnownRemainingPower.text = "Known remaining power: %s" % (
		state.copied_excess_power + state.base_turn_power - state.power_used
	)
	$MaximumRemainingPower.text = "Maximum possible remaining power: %s" % (
		state.copied_excess_power + state.base_turn_power + Constants.MAX_EXCESS_POWER - state.power_used
	)
