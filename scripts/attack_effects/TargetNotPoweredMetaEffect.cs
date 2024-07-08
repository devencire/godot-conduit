namespace conduit.scripts.attack_effects;

public class TargetNotPoweredMetaEffect : AttackEffect
{
    private readonly AttackEffect _baseEffect;
    private readonly Player? _target;

    public TargetNotPoweredMetaEffect(AttackEffect baseEffect, Player? target)
    {
        _baseEffect = baseEffect;
        _target = target;
    }

    public override string DisplayText => $"if target is not [color=yellow]powered[/color], {_baseEffect.DisplayText}";

    public override bool Enabled
    {
        get
        {
            if (_target == null) return _baseEffect.Enabled;
            return _baseEffect.Enabled && !_target.IsPowered;
        }
    }

    public override int Enact()
    {
        return _baseEffect.Enact();
    }
}