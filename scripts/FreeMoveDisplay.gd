extends RichTextLabel

var free_moves_per_turn: int

func _on_player_initialized(player: Player):
	free_moves_per_turn = player.stats.free_moves_per_turn
	_update_visual(player.free_moves_remaining)

func _update_visual(free_moves_remaining: int):
	clear()
	push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	push_bold()
	push_outline_size(8)
	push_outline_color(Color.BLACK)
	for i in range(free_moves_per_turn):
		if i < free_moves_remaining:
			add_text('>')
		else:
			push_color(Color(1, 1, 1, 0.4))
			add_text('>')
			pop()


func _on_player_free_moves_remaining_changed(new_remaining):
	_update_visual(new_remaining)


func _on_player_is_beacon_changed(new_is_beacon: bool):
	visible = not new_is_beacon
