using Godot;
using System;
using conduit.scripts;

public partial class DebugShowTileLabel : Label
{
    [Export] private ArenaTileMap _arenaTileMap;
    
    public override void _UnhandledInput(InputEvent @event)
    {
        if (@event is InputEventMouseMotion motion)
        {
            var cell = _arenaTileMap.GetHoveredCell(motion);
            Text = $"hovered tile: {cell} ({ArenaTileMap.DistanceFromHalfwayLine(cell)})";
        }
    }
}
