class_name Popups

extends Node2D

var resource_popup_scene := preload("res://scenes/resource_popup.tscn")

func spawn_resource_popup(text: String, position: Vector2) -> void:
	var popup: ResourcePopup = resource_popup_scene.instantiate()
	popup.position = position
	popup.text = text
	add_child(popup)
