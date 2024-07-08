using System.Collections.Generic;
using System.Linq;
using conduit.scripts.attack_effects;
using Godot;

namespace conduit.scripts.attack_options;

public partial class BladeCloseSlashAttackOption : AttackOption
{
    public override string DisplayName => "Close Slash";
    public override int BasePowerCost => 1;

    public override IEnumerable<Player> GetValidTargets(Player attacker)
    {
        return GetAdjacentOpponents(attacker);
    }

    public override IEnumerable<TileSet.CellNeighbor> GetValidDirections(Player attacker, Player target)
    {
        // only directly back
        return new[] { ArenaTileMap.DirectionOfCell(attacker.Cell, target.Cell) };
    }

    public override IEnumerable<AttackEffect> GetEffects(Player attacker, Player? target,
        TileSet.CellNeighbor direction)
    {
        return new AttackEffect[]
        {
            new TargetNotPoweredMetaEffect(new DirectDamageEffect(attacker, DisplayName, 1, target), target),
            new FixedPushEffect(attacker, 1, direction, target),
        };
    }
}