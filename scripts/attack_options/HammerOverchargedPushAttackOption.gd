class_name HammerOverchargedPushAttackOption
extends HammerPushAttackOption

const OC_POWER_COST := 2
const OC_DIRECT_DAMAGE := 1
const OC_POWER_PER_TILE := 2

func get_display_name() -> String:
	return 'Overcharged Bludgeon'

func get_base_power_cost() -> int:
	return OC_POWER_COST

func display_directions(attacker: Player, target: Player, display_node: Node2D, attack_callback: Callable) -> void:
	var valid_directions := get_valid_directions(attacker, target)
	for direction in valid_directions:
		var preview_tile := create_clickable_direction_node(attacker, target, direction, attack_callback)
		display_node.add_child(preview_tile)
		var further_push_cost := OC_POWER_COST
		var further_push_cell := attacker.arena_tilemap.get_neighbor_cell(target.tile_position, direction)
		while true:
			further_push_cost += OC_POWER_PER_TILE
			var further_push_chance := attacker.turn_state.chance_that_power_available(further_push_cost)
			if further_push_chance == 0:
				break
			further_push_cell = attacker.arena_tilemap.get_neighbor_cell(further_push_cell, direction)
			var cell_pathable := attacker.arena_tilemap.is_cell_pathable(further_push_cell)
			var further_push_preview_tile: TargetPreviewTile = target_preview_tile_scene.instantiate()
			further_push_preview_tile.position = attacker.arena_tilemap.map_to_local(further_push_cell)
			further_push_preview_tile.direction = direction
			further_push_preview_tile.team = attacker.team
			further_push_preview_tile.type = TargetPreviewTile.PreviewTileType.FADED_ARROW
			further_push_preview_tile.success_chance = further_push_chance
			display_node.add_child(further_push_preview_tile)
			# if we just previewed knocking the target off the arena, don't show any further-out previews
			if not cell_pathable:
				break

func get_effects(attacker: Player, target: Player, direction: TileSet.CellNeighbor) -> Array[AttackEffect]:
	return [
		DazeUnpoweredTargetEffect.new(target),
		DirectDamageEffect.new(target, OC_DIRECT_DAMAGE),
		OverchargedVariablePushEffect.new(attacker, target, PUSH_FORCE, OC_POWER_COST, OC_POWER_PER_TILE, direction),
		EndTurnEffect.new(attacker.turn_state)
	]
