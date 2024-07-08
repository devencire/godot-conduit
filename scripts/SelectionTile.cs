using Godot;

namespace conduit.scripts;

public partial class SelectionTile : Node2D
{
    private StringName _animDefault = new("default");
    private StringName _animThick = new("thick");
    private AnimatedSprite2D _sprite;

    public override void _Ready()
    {
        _sprite = GetNode<AnimatedSprite2D>("Sprite");
    }

    private void _UpdateSprite(Player player)
    {
        Visible = player.IsOnActiveTeam;
        if (!player.CanAct)
        {
            _sprite.Modulate = Colors.Red;
            _sprite.Animation = _animDefault;
        }
        else if (player.Selected)
        {
            _sprite.Modulate = Colors.White;
            _sprite.Animation = _animThick;
        }
        else
        {
            _sprite.Modulate = Colors.White;
            _sprite.Animation = _animDefault;
        }
    }
}