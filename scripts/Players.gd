class_name Players

extends Node

signal changed(players: Array[Player])

func _on_child_order_changed():
	send_changed_signal()

func player_moved():
	send_changed_signal()

func send_changed_signal():
	var players: Array[Player] = []
	for node in get_children():
		players.append(node)
	changed.emit(players)
