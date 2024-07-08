using System.Collections.Generic;
using System.Linq;
using conduit.scripts.attack_effects;
using Godot;

namespace conduit.scripts.attack_options;

public partial class HammerPushAttackOption : AttackOption
{
    public override string DisplayName => "Bludgeon";
    public override int BasePowerCost => 1;

    public override IEnumerable<Player> GetValidTargets(Player attacker)
    {
        return GetAdjacentOpponents(attacker);
    }

    public override IEnumerable<TileSet.CellNeighbor> GetValidDirections(Player attacker, Player target)
    {
        // fan-of-three
        var relativeDirection = ArenaTileMap.DirectionOfCell(attacker.Cell, target.Cell);
        return Constants.AdjacentDirections[relativeDirection].Append(relativeDirection);
    }

    public override IEnumerable<AttackEffect> GetEffects(Player attacker, Player? target, TileSet.CellNeighbor direction)
    {
        return new AttackEffect[]
        {
            new TargetNotPoweredMetaEffect(new DazeTargetEffect(attacker, DisplayName, target), target),
            new FixedPushEffect(attacker, 1, direction, target),
        };
    }
}