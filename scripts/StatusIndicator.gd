extends RichTextLabel

@export var visible_status: Player.Status

func _on_player_status_changed(_player: Player, new_status: Player.Status) -> void:
	visible = new_status == visible_status
