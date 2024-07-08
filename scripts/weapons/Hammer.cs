using conduit.scripts.attack_options;

namespace conduit.scripts.weapons;

public partial class Hammer : Weapon
{
    public static readonly Hammer Base = new();
    
    public override string DisplayName => "Hammer";

    public override AttackOption[] AttackOptions { get; } =
    {
        new HammerPushAttackOption(), new HammerOverchargedPushAttackOption(),
    };
}