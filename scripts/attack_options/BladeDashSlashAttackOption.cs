using System.Collections.Generic;
using System.Linq;
using conduit.scripts.attack_effects;
using Godot;

namespace conduit.scripts.attack_options;

public partial class BladeDashSlashAttackOption : AttackOption
{
    public override string DisplayName => "Dash Slash";
    public override int BasePowerCost => 2;

    public override IEnumerable<Player> GetValidTargets(Player attacker)
    {
        return GetOpponentsAtRange(attacker, 2);
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
            new FixedMoveEffect(attacker, 1, direction, "towards the target"),
            new DirectDamageEffect(attacker, DisplayName, 1, target),
            new FixedPushEffect(attacker, 1, direction, target),
        };
    }
}