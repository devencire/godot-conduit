namespace conduit.scripts.attack_effects;

public partial class OverchargedVariableDirectDamageEffect : AttackEffect
{
    private readonly Player _attacker;
    private readonly string _attackName;
    private readonly int _baseDamage;
    private readonly int _basePowerCost;
    private readonly int _powerPerDamage;
    private readonly Player? _target;

    public OverchargedVariableDirectDamageEffect(Player attacker, string attackName, int baseDamage, int basePowerCost, int powerPerDamage,
        Player? target)
    {
        _attacker = attacker;
        _attackName = attackName;
        _target = target;
        _baseDamage = baseDamage;
        _basePowerCost = basePowerCost;
        _powerPerDamage = powerPerDamage;
    }

    private int _calcMaxDamage(int maxRemainingPower)
    {
        return _baseDamage + (maxRemainingPower - _basePowerCost) / _powerPerDamage;
    }

    public override string DisplayText
    {
        get
        {
            var maxDamage = _calcMaxDamage(_attacker.TurnState.MaxRemainingPower);
            return maxDamage == _baseDamage
                ? $"deal {_baseDamage} damage to the target"
                : $"deal {_baseDamage}-{maxDamage} damage to the target ({_powerPerDamage} per extra damage)";
        }
    }

    public override int Enact()
    {
        var extraDamage = _attacker.TurnState.ActualRemainingPower / _powerPerDamage;
        var damage = _baseDamage + extraDamage;
        if (damage == 0) return 0;
        var extraPowerSpent = extraDamage * _powerPerDamage;
        _target!.TakeDamage(new DamageSource.DirectAttack(_attacker, _attackName, damage));
        return extraPowerSpent;
    }
}