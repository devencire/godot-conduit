extends RichTextLabel

func _on_player_is_beacon_changed(new_is_beacon: bool):
	visible = new_is_beacon
