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

static func team_color(team: Team) -> String:
	if team == Constants.Team.ONE:
		return '#0000ff'
	elif team == Constants.Team.TWO:
		return '#ff0000'
	return '#ff00ff'

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
