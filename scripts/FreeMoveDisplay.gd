extends RichTextLabel

var free_moves_per_turn: int
var free_moves_remaining: int
var dashes_used: int

func _on_player_initialized(player: Player):
	free_moves_per_turn = player.stats.free_moves_per_turn
	_update_visual()

func _update_visual():
	print(free_moves_remaining, ' ', dashes_used)
	clear()
	push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	push_bold()
	push_outline_size(8)
	push_outline_color(Color.BLACK)
	for i in range(free_moves_per_turn):
		if i < dashes_used:
			push_outline_color(Color.RED)
			add_text('>')
			pop()
		elif i < free_moves_remaining:
			add_text('>')
		else:
			push_color(Color(1, 1, 1, 0.4))
			add_text('>')
			pop()


func _on_player_free_moves_remaining_changed(new_remaining: int):
	free_moves_remaining = new_remaining
	_update_visual()


func _on_player_dashes_used_changed(new_dashes_used: int):
	dashes_used = new_dashes_used
	_update_visual()


func _on_player_is_beacon_changed(new_is_beacon: bool):
	visible = not new_is_beacon
