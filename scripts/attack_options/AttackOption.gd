class_name AttackOption
extends Resource

func get_display_name() -> String:
	return 'Missing name'

func get_base_power_cost() -> int:
	return 0

func get_valid_targets(_attacker: Player) -> Array[Player]:
	return []

func get_valid_directions(_attacker: Player, _target: Player) -> Array[TileSet.CellNeighbor]:
	return []

func display_directions(
	_attacker: Player,
	_target: Player,
	_display_node: Node2D,
	_attack_callback: Callable # Callable[[TileSet.CellNeighbor], void]
) -> void:
	pass

func get_effects(_attacker: Player, _target: Player, _direction: TileSet.CellNeighbor) -> Array[AttackEffect]:
	return []

## Common functions

static func get_adjacent_opponents(attacker: Player) -> Array[Player]:
	var valid_targets: Array[Player] = []
	var possible_cells := attacker.arena_tilemap.get_aligned_cells_at_range(attacker.tile_position, 1)
	for direction in possible_cells:
		var cell: Vector2i = possible_cells[direction]
		var player_in_cell := attacker.players.player_in_cell(cell, Constants.other_team(attacker.team))
		if player_in_cell:
			valid_targets.append(player_in_cell)
	return valid_targets
