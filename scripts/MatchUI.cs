using Godot;

namespace conduit.scripts;

public partial class MatchUI : CanvasLayer
{
    private void _onMatchRootTeamScoreChanged(MatchRoot matchRoot, Team team, int score)
    {
        var label = GetNode<RichTextLabel>("VBoxContainer/Score");
        if (label == null) return;
        label.Clear();
        label.PushParagraph(HorizontalAlignment.Center);
        label.PushOutlineSize(8);
        label.PushOutlineColor(Colors.Black);
        label.PushColor(Constants.TeamOne.Color);
        label.AddText(matchRoot.ScoreForTeam(Constants.TeamOne).ToString());
        label.Pop();
        label.AddText(" - ");
        label.PushColor(Constants.TeamTwo.Color);
        label.AddText(matchRoot.ScoreForTeam(Constants.TeamTwo).ToString());
    }
}