using Godot;

namespace conduit.scripts;

public partial class BeaconIndicator : RichTextLabel
{
    private void _onPlayerIsBeaconChanged(Player _, bool isBeacon)
    {
        Visible = isBeacon;
    }
}