using System;
using Godot;

namespace conduit.scripts;

public partial class TurnState : Node
{
    [Signal]
    public delegate void ChangedEventHandler(TurnState turnState);

    [Signal]
    public delegate void NewTurnStartedEventHandler(TurnState turnState);

    private readonly Random _random = new();

    private bool _roundIsOver;

    private bool _turnEnding;
    [Export] public Team ActiveTeam = Constants.TeamOne;
    [Export] public int BaseTurnPower;
    [Export] public int CopiedExcessPower;

    [Export] public int PowerUsed;
    [Export] public int TotalAvailablePower;
    public int KnownRemainingPower => CopiedExcessPower + BaseTurnPower - PowerUsed;
    public int MaxRemainingPower => KnownRemainingPower + Constants.MaxExcessPower;
    public int ActualRemainingPower => TotalAvailablePower - PowerUsed;

    public void StartTurn(Team team)
    {
        if (_roundIsOver) return;

        ActiveTeam = team;

        // A team's available power for a turn is
        // the excess power their opponent used last turn
        var excessPowerUsed = Mathf.Max(0, PowerUsed - CopiedExcessPower - BaseTurnPower);
        CopiedExcessPower = excessPowerUsed;
        // + a base, known amount of power
        BaseTurnPower = Constants.BaseTurnPower;
        // + a secret random amount of excess power (not shown on the UI)
        var secretAvailableExcessPower = _random.Next(0, Constants.MaxExcessPower);

        TotalAvailablePower = CopiedExcessPower + BaseTurnPower + secretAvailableExcessPower;
        PowerUsed = 0;

        GetNode<EventLog>("%EventLog")
            .Log(
                $"[b]{BB.TeamName(team)} starts their turn with {KnownRemainingPower}-{MaxRemainingPower}\u26a1 available[/b]");

        EmitSignal(SignalName.Changed, this);
        EmitSignal(SignalName.NewTurnStarted, this);
    }

    public bool TrySpendPower(int amount)
    {
        if (PowerUsed + amount > TotalAvailablePower)
        {
            EndTurn();
            return false;
        }

        PowerUsed += amount;
        EmitSignal(SignalName.Changed, this);
        return true;
    }

    public float ChanceThatPowerAvailable(int powerCost)
    {
        if (MaxRemainingPower < powerCost) return 0.0f;

        var unknownPowerUse = powerCost - KnownRemainingPower;
        if (unknownPowerUse <= 0) return 1.0f;

        return 1.0f - (float)(powerCost - Mathf.Max(0, KnownRemainingPower)) /
            (Mathf.Min(Constants.MaxExcessPower, MaxRemainingPower) + 1);
    }

    public void EndTurn()
    {
        if (!_turnEnding)
        {
            _turnEnding = true;
            Callable.From(_actuallyEndTurn).CallDeferred();
        }
    }

    private void _actuallyEndTurn()
    {
        _turnEnding = false;
        StartTurn(Constants.OtherTeam(ActiveTeam));
    }

    private void _onRoundRootRoundEnded(RoundRoot roundRoot)
    {
        _roundIsOver = true;
    }
}