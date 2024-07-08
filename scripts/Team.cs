using Godot;

namespace conduit.scripts;

public partial class Team : Resource
{
    [Export] public Color Color;
    [Export] public string Name;
    [Export] public Color ZoneColor;

    public Team()
    {
    }
    
    public Team(string name, Color color, Color zoneColor)
    {
        Name = name;
        Color = color;
        ZoneColor = zoneColor;
    }
}