extends Node2D

@onready var health_remaining_rect: ColorRect = $HealthRemainingRect
@onready var health_back_rect: ColorRect = $HealthBackRect
var player: Player

func _draw():
	if not player:
		return
	for notch in range(1, player.stats.max_resolve):
		var x_pos: int = health_back_rect.position.x + lerp(0, int(health_back_rect.size.x), float(notch) / player.stats.max_resolve)
		var from := Vector2(x_pos, health_back_rect.position.y)
		var to := Vector2(x_pos, health_back_rect.position.y + health_back_rect.size.y / 2)
		draw_line(from, to, Color.BLACK, 2, false)


func _on_player_initialized(new_player: Player):
	player = new_player
	_update_health_remaining()
	queue_redraw()

func _on_player_taken_damage(_player: Player, _damage: int):
	_update_health_remaining()

func _update_health_remaining():
	health_remaining_rect.size.x = 60 * float(player.resolve) / player.stats.max_resolve
	health_remaining_rect.color = Constants.success_chance_color(float(player.resolve) / player.stats.max_resolve)
