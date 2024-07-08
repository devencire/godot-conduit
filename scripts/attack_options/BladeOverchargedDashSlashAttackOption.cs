using System.Collections.Generic;
using conduit.scripts.attack_effects;
using Godot;

namespace conduit.scripts.attack_options;

public partial class BladeOverchargedDashSlashAttackOption : BladeDashSlashAttackOption
{
    public override string DisplayName => "OC Dash Slash";

    public override int BasePowerCost => 2;

    public override IEnumerable<AttackEffect> GetEffects(Player attacker, Player? target, TileSet.CellNeighbor direction)
    {
        return new AttackEffect[]
        {
            new FixedMoveEffect(attacker, 1, direction, "towards the target"),
            new OverchargedVariableDirectDamageEffect(attacker, DisplayName, 1, BasePowerCost, 2, target),
            new FixedPushEffect(attacker, 1, direction, target),
            new EndTurnEffect(attacker.TurnState)
        };
    }
}