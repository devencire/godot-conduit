using Godot;

namespace conduit.scripts;

public partial class FreeMoveDisplay : RichTextLabel
{
    private void _updateVisual(Player player)
    {
        Clear();
        PushParagraph(HorizontalAlignment.Center);
        PushBold();
        PushOutlineSize(8);
        PushOutlineColor(Colors.Black);
        for (var i = 0; i < player.Stats.FreeMovesPerTurn; i++)
        {
            if (i < player.DashesUsed)
            {
                PushOutlineColor(Colors.Red);
                AddText(">");
                Pop();
            } else if (i < player.FreeMovesRemaining)
            {
                AddText(">");
            }
            else
            {
                PushColor(Colors.White with { A = 0.4f });
                AddText(">");
                Pop();
            }
        }
    }

    private void _onPlayerIsBeaconChanged(Player player, bool isBeacon)
    {
        Visible = !isBeacon;
    }
}