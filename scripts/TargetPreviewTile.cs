using System;
using Godot;

namespace conduit.scripts;

public partial class TargetPreviewTile : Node2D
{
    [Signal]
    public delegate void RightClickedEventHandler();

    public enum PreviewTileType
    {
        TeamCircle,
        SelectedCircle,
        Arrow,
        FadedArrow
    }

    private TileSet.CellNeighbor? _direction;

    private AnimatedSprite2D? _spriteCached;

    private float? _successChance;

    private Team _team;

    private PreviewTileType _type;

    [Export]
    public Team Team
    {
        get => _team;
        set
        {
            _team = value;
            _updateColor();
        }
    }

    [Export]
    public PreviewTileType Type
    {
        get => _type;
        set
        {
            _type = value;
            Sprite.Animation = _type is PreviewTileType.Arrow or PreviewTileType.FadedArrow ? "arrow" : "circle";
            _updateColor();
        }
    }

    [Export]
    public TileSet.CellNeighbor Direction
    {
        get => _direction ?? TileSet.CellNeighbor.TopSide;
        set
        {
            _direction = value;
            Sprite.RotationDegrees = _direction switch
            {
                TileSet.CellNeighbor.TopSide => 0,
                TileSet.CellNeighbor.TopRightSide => 60,
                TileSet.CellNeighbor.BottomRightSide => 120,
                TileSet.CellNeighbor.BottomSide => 180,
                TileSet.CellNeighbor.BottomLeftSide => 240,
                TileSet.CellNeighbor.TopLeftSide => 300,
                _ => Sprite.RotationDegrees = 0
            };
        }
    }

    [Export]
    public float SuccessChance
    {
        get => _successChance ?? 0f;
        set
        {
            _successChance = value;
            var label = GetNode<RichTextLabel>("SuccessChanceLabel");
            label.Visible = _successChance != null;
            if (_successChance == null) return;
            label.Clear();
            label.Text = "";
            label.PushParagraph(HorizontalAlignment.Center);
            label.PushOutlineSize(8);
            label.PushOutlineColor(Colors.Black);
            label.PushColor(Constants.SuccessChanceColor(_successChance.Value));
            label.AppendText($"{Math.Round(_successChance.Value * 100)}%");
        }
    }

    private AnimatedSprite2D Sprite => _spriteCached ??= GetNode<AnimatedSprite2D>("Sprite");

    private void _updateColor()
    {
        if (Type == PreviewTileType.SelectedCircle)
        {
            Sprite.Modulate = Colors.White;
            return;
        }

        var color = Team.Color;
        if (Type == PreviewTileType.FadedArrow) color = color with { A = 0.4f };
        Sprite.Modulate = color;
    }

    private void _onMouseEntered()
    {
        if (Type is PreviewTileType.Arrow or PreviewTileType.TeamCircle) Sprite.Modulate = Colors.White;
    }

    private void _onMouseExited()
    {
        _updateColor();
    }

    private void _onMouseOverAreaInputEvent(Node viewport, InputEvent @event, int _)
    {
        if (@event is not InputEventMouseButton { Pressed: true, ButtonIndex: MouseButton.Right }) return;
        EmitSignal(SignalName.RightClicked);
        GetViewport().SetInputAsHandled();
    }
}