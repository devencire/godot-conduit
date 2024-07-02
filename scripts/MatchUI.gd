class_name MatchUI

extends CanvasLayer

@onready var score: RichTextLabel = $VBoxContainer/Score

func _on_match_root_changed(match_root: MatchRoot):
    if not score:
        return
    BB.set_centered_outlined_text(score, '[color=%s]%s[/color] - [color=%s]%s[/color]' % [Constants.team_color(Constants.Team.ONE).to_html(), match_root.team_one_score, Constants.team_color(Constants.Team.TWO).to_html(), match_root.team_two_score])
