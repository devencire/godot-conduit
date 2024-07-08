using Godot;

namespace conduit.scripts;

public partial class Popups : Node2D
{
    private PackedScene _resourcePopupScene = GD.Load<PackedScene>("res://scenes/resource_popup.tscn");

    public void SpawnResourcePopup(string text, Vector2 popupPosition)
    {
        var popup = _resourcePopupScene.Instantiate<ResourcePopup>();
        popup.Position = popupPosition;
        popup.Text = text;
        AddChild(popup);
    }
}