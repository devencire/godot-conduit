namespace conduit.scripts;

public abstract class DamageSource
{
    public int Amount;
    public Player Attacker;
    public string DisplayText;
    public bool PiercesResolve;

    private DamageSource(Player attacker, string displayText, int amount, bool piercesResolve = false)
    {
        Attacker = attacker;
        DisplayText = displayText;
        Amount = amount;
        PiercesResolve = piercesResolve;
    }

    public class DirectAttack : DamageSource
    {
        public DirectAttack(Player attacker, string attackName, int damage) : base(attacker,
            $"from {BB.PlayerName(attacker)}'s {attackName}", damage)
        {
        }
    }
    
    public class OutOfArena : DamageSource
    {
        public OutOfArena(Player attacker) : base(attacker, "from falling off the arena", 2, true)
        {
        }
    }

    public class PushedIntoWall : DamageSource
    {
        public PushedIntoWall(Player attacker, int excessForce) : base(attacker, "from being slammed into a wall",
            excessForce)
        {
        }
    }

    public class PushedIntoPlayer : DamageSource
    {
        public PushedIntoPlayer(Player attacker, Player pushedInto) : base(attacker,
            $"from being slammed into {BB.PlayerName(pushedInto)}", 1)
        {
        }
    }

    public class HitByPushedPlayer : DamageSource
    {
        public HitByPushedPlayer(Player attacker, Player hitBy) : base(attacker,
            $"from {BB.PlayerName(hitBy)} being slammed into them", 1)
        {
        }
    }
}