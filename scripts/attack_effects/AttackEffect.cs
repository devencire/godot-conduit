namespace conduit.scripts.attack_effects;

public abstract class AttackEffect
{
    public virtual string DisplayText => "Missing name";
    public virtual bool Enabled => true;

    /**
     * <summary>
     *     Is passed the maximum power the attack can be overcharged by
     *     (or 0 if the attack was not overcharged).
     *     Returns the excess power that was used.
     * </summary>
     */
    public virtual int Enact()
    {
        return 0;
    }
}