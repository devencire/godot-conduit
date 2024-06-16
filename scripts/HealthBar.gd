extends Node2D

@onready var health_remaining_rect: ColorRect = $HealthRemainingRect
var player: Player

func _draw():
	if not player:
		return
	for notch in range(1, player.max_health):
		var x_pos: int = health_remaining_rect.position.x + lerp(0, int(health_remaining_rect.size.x), float(notch) / player.max_health)
		var from := Vector2(x_pos, health_remaining_rect.position.y)
		var to := Vector2(x_pos, health_remaining_rect.position.y + health_remaining_rect.size.y / 2)
		draw_line(from, to, Color.BLACK, 2, false)


func _on_player_initialized(new_player: Player):
	player = new_player
	queue_redraw()


func _on_player_taken_damage(_player: Player, _damage: int):
	health_remaining_rect.size.x = 60 * float(player.health) / player.max_health
	health_remaining_rect.color = Constants.success_chance_color(float(player.health) / player.max_health)
