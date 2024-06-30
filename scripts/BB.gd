class_name BB

const OUTLINE_SIZE := 8 # pixels

static func set_centered_outlined_text(node: RichTextLabel, text: String, color: Color = Color.WHITE, outline_color: Color = Color.BLACK, outline_size: int = OUTLINE_SIZE) -> void:
	node.clear()
	node.text = ''
	node.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	node.push_outline_size(outline_size)
	node.push_outline_color(outline_color)
	if color != Color.WHITE:
		node.push_color(color)
	node.append_text(text)
	node.pop_all()

static func team_name(team: Constants.Team) -> String:
	return '[color=%s]Team %s[/color]' % [Constants.team_color(team).to_html(), Constants.team_name(team)]

static func player_name(player: Player) -> String:
	return '[color=%s]%s[/color]' % [Constants.team_color(player.team).to_html(), player.debug_name]
