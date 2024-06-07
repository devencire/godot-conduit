class_name Constants

enum Team {ONE, TWO}

const CONTROLLED_TEAM := Team.ONE

const BASE_TURN_POWER := 5
const MAX_EXCESS_POWER := 6

static func team_name(team: Team) -> String:
	if team == Constants.Team.ONE:
		return 'Blue'
	return 'Red'

static func team_color(team: Team) -> String:
	if team == Constants.Team.ONE:
		return '#0000ff'
	return '#ff0000'

static func other_team(team: Team) -> Team:
	if team == Team.ONE:
		return Team.TWO
	return Team.ONE
