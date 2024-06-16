class_name BB

const OUTLINE_SIZE := 8 # pixels

static func set_centered_outlined_text(node: RichTextLabel, text: String, color: Color = Color.WHITE) -> void:
	node.clear()
	node.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	node.push_outline_size(OUTLINE_SIZE)
	node.push_outline_color(Color.BLACK)
	if color != Color.WHITE:
		node.push_color(color)
	node.append_text(text)
	node.pop_all()

static func team_name(team: Constants.Team) -> String:
	return '[color=%s]Team %s[/color]' % [Constants.team_color(team).to_html(), Constants.team_name(team)]

static func player_name(player: Player) -> String:
	return '[color=%s]%s[/color]' % [Constants.team_color(player.team).to_html(), player.debug_name]
