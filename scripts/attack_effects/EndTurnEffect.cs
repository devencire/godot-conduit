namespace conduit.scripts.attack_effects;

public class EndTurnEffect : AttackEffect
{
    private readonly TurnState _turnState;
    
    public EndTurnEffect(TurnState turnState)
    {
        _turnState = turnState;
    }

    public override string DisplayText => $"end the turn";

    public override int Enact()
    {
        _turnState.EndTurn();
        return 0;
    }
}