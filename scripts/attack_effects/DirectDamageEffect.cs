namespace conduit.scripts.attack_effects;

public class DirectDamageEffect : AttackEffect
{
    private readonly Player _attacker;
    private readonly string _attackName;
    private readonly int _damage;
    private readonly Player? _target;
    
    public DirectDamageEffect(Player attacker, string attackName, int damage, Player? target)
    {
        _attacker = attacker;
        _attackName = attackName;
        _damage = damage;
        _target = target;
    }

    public override string DisplayText => $"deal {_damage} damage to the target";

    public override int Enact()
    {
        _target!.TakeDamage(new DamageSource.DirectAttack(_attacker, _attackName, _damage));
        return 0;
    }
}