using Godot;

namespace conduit.scripts;

public partial class StatusIndicator : RichTextLabel
{
    [Export] private Player.Status _visibleStatus;

    private void _OnPlayerStatusChanged(Player player, Player.Status newStatus)
    {
        Visible = newStatus == _visibleStatus;
    }
}