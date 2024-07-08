using Godot;

namespace conduit.scripts;

public partial class PlayerStats : Resource
{
    [Export] public int DashesBeforeCostIncrease = 2;
    [Export] public int DazedReviveCost = 1;
    [Export] public int FreeMovesPerTurn = 2;
    [Export] public int MaxResolve = 3;
    [Export] public int PassCost = 3;

    [Export] public int StartingResolve = 2;
}