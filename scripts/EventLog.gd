class_name EventLog

extends RichTextLabel

func log(new_text: String) -> void:
    append_text('\n' + new_text)
