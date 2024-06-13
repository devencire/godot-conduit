class_name BB

const OUTLINE_SIZE := 8 # pixels

static func set_centered_outlined_text(node: RichTextLabel, text: String, color: Color = Color.WHITE) -> void:
	node.text = ''
	node.push_context()
	node.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	node.push_outline_size(OUTLINE_SIZE)
	node.push_outline_color(Color.BLACK)
	if color != Color.WHITE:
		node.push_color(color)
	node.append_text(text)
	node.pop_context()
