extends Button

@onready var turn_state: TurnState = %TurnState

func _on_pressed():
	turn_state.end_turn()
