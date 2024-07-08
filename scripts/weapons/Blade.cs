using conduit.scripts.attack_options;

namespace conduit.scripts.weapons;

public partial class Blade : Weapon
{
    public static readonly Blade Base = new();
    
    public override string DisplayName => "Blade";

    public override AttackOption[] AttackOptions { get; } =
    {
        new BladeCloseSlashAttackOption(), new BladeDashSlashAttackOption(),
        new BladeOverchargedDashSlashAttackOption()
    };
}