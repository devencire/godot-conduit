class_name ResourcePopup

extends CenterContainer

@onready var label: RichTextLabel = $RichTextLabel
@export var text: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	BB.set_centered_outlined_text(label, text, Color.WHITE, Color.BLACK, 8)
	
	var starting_pos := position
	var tween := create_tween()
	tween.tween_property(self, "position", starting_pos - Vector2(0, 40), 1.2)
	tween.tween_property(self, "position", starting_pos - Vector2(0, 60), 0.6)
	tween.parallel().tween_property(self, "modulate", Color(Color.WHITE, 0), 0.6)
	tween.tween_callback(queue_free)
	
	print(self, ' ', starting_pos)
