using Godot;

namespace conduit.scripts.attack_effects;

public class OverchargedVariablePushEffect : AttackEffect
{
    private readonly Player _attacker;
    private readonly string _attackName;
    private readonly int _baseForce;
    private readonly int _basePowerCost;
    private readonly int _powerPerForce;
    private readonly TileSet.CellNeighbor _direction;
    private readonly Player? _target;

    public OverchargedVariablePushEffect(Player attacker, string attackName, int baseForce, int basePowerCost,
        int powerPerForce, TileSet.CellNeighbor direction, Player? target)
    {
        _attacker = attacker;
        _attackName = attackName;
        _target = target;
        _baseForce = baseForce;
        _basePowerCost = basePowerCost;
        _powerPerForce = powerPerForce;
        _direction = direction;
    }

    private int _calcMaxForce(int maxRemainingPower)
    {
        return _baseForce + (maxRemainingPower - _basePowerCost) / _powerPerForce;
    }

    public override string DisplayText
    {
        get
        {
            var maxForce = _calcMaxForce(_attacker.TurnState.MaxRemainingPower);
            return maxForce == _baseForce
                ? $"push the target {_baseForce} spaces"
                : $"push the target {_baseForce}-{maxForce} spaces ({_powerPerForce} per extra space)";
        }
    }

    public override int Enact()
    {
        var extraForce = _attacker.TurnState.ActualRemainingPower / _powerPerForce;
        var force = _baseForce + extraForce;
        if (force == 0) return 0;
        var extraPowerSpent = extraForce * _powerPerForce;
        _attacker.ResolvePush(_target!, _direction, force);
        return extraPowerSpent;
    }
}