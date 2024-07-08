using System.Collections.Generic;
using conduit.scripts.attack_options;
using Godot;

namespace conduit.scripts.weapons;

public abstract partial class Weapon : Resource
{
    public virtual string DisplayName => "Unnamed Weapon";
    public virtual AttackOption[] AttackOptions => System.Array.Empty<AttackOption>();
}
