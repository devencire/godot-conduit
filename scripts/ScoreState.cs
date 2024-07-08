using Godot;
using Godot.Collections;

namespace conduit.scripts;

public partial class ScoreState : Node
{
    [Signal]
    public delegate void ChangedEventHandler(ScoreState scoreState);

    [Export] private EventLog _eventLog;

    [Export] private RoundRoot _roundRoot;
    private readonly int[] _travelScores = new int[2];
    public int[] TravelScores => _travelScores;

    private void _onPlayersChanged(Players players)
    {
        foreach (var team in Constants.Teams) _checkForTravelScoring(team, players.BeaconForTeam(team));
    }

    private void _checkForTravelScoring(Team team, Player? beaconPlayer)
    {
        if (beaconPlayer == null) return;
        var travelScoresIdx = team == Constants.TeamOne ? 0 : 1;
        var scoringDirection = team == Constants.TeamOne ? 1 : -1;
        var progress = ArenaTileMap.DistanceFromHalfwayLine(beaconPlayer.Cell) * scoringDirection;
        var newProgress = progress - _travelScores[travelScoresIdx];
        if (newProgress > 0)
        {
            _travelScores[travelScoresIdx] += newProgress;
            ScorePoints(team, newProgress);
            if (_travelScores[travelScoresIdx] == Constants.MaxTravelPoints) _roundRoot.EndRound();
        }
    }

    public void ScorePoints(Team team, int points)
    {
        _roundRoot.ScorePoints(team, points);
        _eventLog.LogDeferred($"[b]{BB.TeamName(team)} scored {points} points![/b]");
        EmitSignal(SignalName.Changed, this);
    }
}