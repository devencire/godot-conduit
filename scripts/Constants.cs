using System;
using System.Collections.Generic;
using Godot;
using static Godot.TileSet.CellNeighbor;

namespace conduit.scripts;

public abstract class Constants
{
    public const int BaseTurnPower = 3;
    public const int MaxExcessPower = 6;
    public const int MaxTravelPoints = 6;
    public const int PointsForDroppingBeacon = 3;
    public const int PointsForSackingBeacon = 3;
    public const int DashCost = 1;
    public const int IncreasedDashCost = 2;
    public static readonly Team TeamOne = new("Blue", new Color(0, 0, 1), new Color(0, 0, 1, 0.2f));
    public static readonly Team TeamTwo = new("Orange", new Color(1, 0.55f, 0), new Color(0.6f, 0.3f, 0, 0.3f));
    public static readonly Team[] Teams = { TeamOne, TeamTwo };

    public static Team OtherTeam(Team team)
    {
        return team == TeamOne ? TeamTwo : TeamOne;
    }

    public static Color SuccessChanceColor(float chance)
    {
        var green = Math.Max(0.0f, 1 + (chance - 0.5f) * 2);
        var red = Math.Max(0.0f, 1 - (chance - 0.5f) * 2);
        return new Color(red, green, 0);
    }

    public static Dictionary<TileSet.CellNeighbor, TileSet.CellNeighbor[]> AdjacentDirections = new()
    {
        { TopSide, new[] { TopLeftSide, TopRightSide } },
        { TopRightSide, new[] { TopSide, BottomRightSide } },
        { BottomRightSide, new[] { TopRightSide, BottomSide } },
        { BottomSide, new[] { BottomRightSide, BottomLeftSide } },
        { BottomLeftSide, new[] { BottomSide, TopLeftSide } },
        { TopLeftSide, new[] { BottomLeftSide, TopSide } }
    };
}