using conduit.scripts.weapons;
using Godot;

namespace conduit.scripts;

public partial class RoundRoot : Node
{
    [Signal]
    public delegate void NextRoundRequestedEventHandler(RoundRoot roundRoot);

    [Signal]
    public delegate void PointsScoredEventHandler(Team team, int points);

    [Signal]
    public delegate void RoundEndedEventHandler(RoundRoot roundRoot);

    private Players _players;

    [Export] private bool _roundComplete;
    private CanvasLayer _roundOverUI;
    public ArenaTileMap ArenaTileMap;
    public ControlZones ControlZones;
    public EventLog EventLog;
    public Popups Popups;
    public ScoreState ScoreState;

    public TurnState TurnState;

    public override void _Ready()
    {
        TurnState = GetNode<TurnState>("%TurnState");
        ArenaTileMap = GetNode<ArenaTileMap>("%ArenaTileMap");
        EventLog = GetNode<EventLog>("%EventLog");
        ControlZones = GetNode<ControlZones>("%ControlZones");
        _players = GetNode<Players>("%Players");
        Popups = GetNode<Popups>("%Popups");
        ScoreState = GetNode<ScoreState>("%ScoreState");
        _roundOverUI = GetNode<CanvasLayer>("%RoundOverUI");
        
        _players.AddPlayer(Constants.TeamOne, new Vector2I(-3, 2), Hammer.Base, true);
        _players.AddPlayer(Constants.TeamOne, new Vector2I(-3, 0), Hammer.Base);
        _players.AddPlayer(Constants.TeamOne, new Vector2I(-1, 2), Blade.Base);
        _players.AddPlayer(Constants.TeamOne, new Vector2I(-1, 0), Blade.Base);
        
        _players.AddPlayer(Constants.TeamTwo, new Vector2I(0, -1), Hammer.Base);
        _players.AddPlayer(Constants.TeamTwo, new Vector2I(0, -3), Hammer.Base);
        _players.AddPlayer(Constants.TeamTwo, new Vector2I(2, -1), Blade.Base);
        _players.AddPlayer(Constants.TeamTwo, new Vector2I(2, -3), Blade.Base, true);

        TurnState.StartTurn(Constants.TeamOne);
    }

    public void ScorePoints(Team team, int points)
    {
        EmitSignal(SignalName.PointsScored, team, points);
    }

    public void EndRound()
    {
        _roundOverUI.Visible = true;
        EmitSignal(SignalName.RoundEnded, this);
    }

    private void _onNextRoundButtonPressed()
    {
        EmitSignal(SignalName.NextRoundRequested, this);
    }
}