namespace conduit.scripts.attack_effects;

public class DazeTargetEffect : AttackEffect
{
    private readonly Player _attacker;
    private readonly string _attackName;
    private readonly Player? _target;
    
    public DazeTargetEffect(Player attacker, string attackName, Player? target)
    {
        _attacker = attacker;
        _attackName = attackName;
        _target = target;
    }

    public override string DisplayText => "daze the target";

    public override bool Enabled => _target == null || _target.CurrentStatus == Player.Status.Ok;

    public override int Enact()
    {
        _target!.EventLog.Log($"{BB.PlayerName(_target)} was dazed by {BB.PlayerName(_attacker)}'s {_attackName}");
        _target.CurrentStatus = Player.Status.Dazed;
        return 0;
    }
}