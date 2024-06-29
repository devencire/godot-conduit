class_name EndTurnEffect

extends AttackEffect

var turn_state: TurnState

func _init(init_turn_state: TurnState) -> void:
    turn_state = init_turn_state

func display_text() -> String:
    return 'end the turn'

func enact() -> int:
    turn_state.end_turn.call_deferred()
    return 0
