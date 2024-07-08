using Godot;

namespace conduit.scripts.attack_effects;

public class FixedPushEffect : AttackEffect
{
    private readonly Player _attacker;
    private readonly TileSet.CellNeighbor _direction;
    private readonly int _force;
    private readonly Player? _target;
    
    public FixedPushEffect(Player attacker, int force, TileSet.CellNeighbor direction, Player? target)
    {
        _attacker = attacker;
        _direction = direction;
        _force = force;
        _target = target;
    }

    public override string DisplayText => $"push the target {_force} spaces";

    public override int Enact()
    {
        _attacker.ResolvePush(_target!, _direction, _force);
        return 0;
    }
}