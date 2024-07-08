using Godot;

namespace conduit.scripts;

public partial class MatchRoot : Node
{
    private static readonly PackedScene RoundRootScene = GD.Load<PackedScene>("res://scenes/round_root.tscn");
    
    [Signal]
    public delegate void TeamScoreChangedEventHandler(MatchRoot matchRoot, Team team, int score);

    private int[] _teamScores = new int[2];

    private int _teamScoresIdx(Team team)
    {
        return team == Constants.TeamOne ? 0 : 1;
    }
    
    public int ScoreForTeam(Team team)
    {
        return _teamScores[_teamScoresIdx(team)];
    }

    public void ScorePoints(Team team, int points)
    {
        _teamScores[_teamScoresIdx(team)] += points;
        EmitSignal(SignalName.TeamScoreChanged, this, team, ScoreForTeam(team));
    }

    public override void _Ready()
    {
        EmitSignal(SignalName.TeamScoreChanged, this, Constants.TeamOne, 0);
        EmitSignal(SignalName.TeamScoreChanged, this, Constants.TeamTwo, 0);
        _startNewRound();
    }

    private void _startNewRound()
    {
        var roundRoot = RoundRootScene.Instantiate<RoundRoot>();
        roundRoot.PointsScored += ScorePoints;
        roundRoot.NextRoundRequested += _roundRootOnNextRoundRequested;
        AddChild(roundRoot);
    }

    private void _roundRootOnNextRoundRequested(RoundRoot roundRoot)
    {
        roundRoot.QueueFree();
        Callable.From(_startNewRound).CallDeferred();
    }
}