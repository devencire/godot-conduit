class_name Constants

enum Team {NONE, ONE, TWO}

const CONTROLLED_TEAM := Team.ONE

const BASE_TURN_POWER := 5
const MAX_EXCESS_POWER := 6

const OFF_ARENA := Vector2i(-40, -40)

static func team_name(team: Team) -> String:
	if team == Constants.Team.ONE:
		return 'Blue'
	elif team == Constants.Team.TWO:
		return 'Red'
	return 'None'

static func team_color(team: Team) -> Color:
	if team == Constants.Team.ONE:
		return Color(0, 0, 1)
	elif team == Constants.Team.TWO:
		return Color(1, 0, 0)
	return Color(1, 0, 1)

static func other_team(team: Team) -> Team:
	if team == Team.ONE:
		return Team.TWO
	return Team.ONE

static func adjacent_directions(direction: TileSet.CellNeighbor) -> Array[TileSet.CellNeighbor]:
	match direction:
		TileSet.CELL_NEIGHBOR_TOP_SIDE:
			return [TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE, TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE]
		TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE:
			return [TileSet.CELL_NEIGHBOR_TOP_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE]
		TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE:
			return [TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE]
		TileSet.CELL_NEIGHBOR_BOTTOM_SIDE:
			return [TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE, TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE]
		TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE:
			return [TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE]
		TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE:
			return [TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE, TileSet.CELL_NEIGHBOR_TOP_SIDE]
	return [] # this should never happen

static func success_chance_color(success_chance: float) -> Color:
	var green := maxf(0, 1 + (success_chance - 0.5) * 2)
	var red := maxf(0, 1 - (success_chance - 0.5) * 2)
	return Color(red, green, 0)
