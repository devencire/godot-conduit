using System.Collections.Generic;
using System.Linq;
using conduit.scripts.weapons;
using Godot;

namespace conduit.scripts;

public partial class Players : Node
{
    [Signal]
    public delegate void ChangedEventHandler(Players players);

    private PackedScene _playerScene = GD.Load<PackedScene>("res://scenes/player.tscn");

    private bool _willUpdate;

    [Export] private RoundRoot _roundRoot;
    
    public List<Player> AllPlayers
    {
        get
        {
            var players = new List<Player>();
            foreach (var child in GetChildren()) players.Add((Player)child);
            ;
            return players;
        }
    }

    public override void _EnterTree()
    {
        ChildOrderChanged += _updatePlayers;
    }

    public override void _ExitTree()
    {
        ChildOrderChanged -= _updatePlayers;
    }

    public void AddPlayer(Team team, Vector2I cell, Weapon weapon, bool isBeacon = false)
    {
        var player = _playerScene.Instantiate<Player>();
        player.RoundRoot = _roundRoot;
        player.Setup(team, cell, weapon, isBeacon);
        player.CellChanged += (_, _) => _updatePlayers();
        player.IsBeaconChanged += (_, _) => _updatePlayers();
        player.CurrentStatusChanged += (_, _) => _updatePlayers();
        AddChild(player);
    }

    public Player? PlayerInCell(Vector2I cell, Team? team = null)
    {
        return AllPlayers.Find(p => p.Cell == cell && (team == null || p.Team == team));
    }

    public IEnumerable<Player> PlayersOnTeam(Team team)
    {
        return AllPlayers.Where(p => p.Team == team);
    }

    public Player? BeaconForTeam(Team team)
    {
        return AllPlayers.Find(p => p.Team == team && p.IsBeacon);
    }

    private void _updatePlayers()
    {
        if (!_willUpdate)
        {
            Callable.From(_performUpdate).CallDeferred();
            _willUpdate = true;
        }
    }

    private void _performUpdate()
    {
        _willUpdate = false;
        _setIsPoweredOnPlayers();
        EmitSignal(SignalName.Changed, this);
    }

    private void _setIsPoweredOnPlayers()
    {
        foreach (var team in Constants.Teams) _setIsPoweredOnPlayersOfTeam(team);
    }

    private void _setIsPoweredOnPlayersOfTeam(Team team)
    {
        var teamPlayers = new List<Player>(PlayersOnTeam(team));
        foreach (var player in teamPlayers) player.IsPowered = player.Conscious && player.IsBeacon;

        var beaconPlayer = BeaconForTeam(team);
        if (beaconPlayer == null) return;

        var newlyPoweredPlayers = new Queue<Player>();
        newlyPoweredPlayers.Enqueue(beaconPlayer);
        while (newlyPoweredPlayers.Count > 0)
        {
            var castingPlayer = newlyPoweredPlayers.Dequeue();
            foreach (var player in teamPlayers)
                if (player.Conscious && !player.IsPowered &&
                    ArenaTileMap.CellsAreAligned(player.Cell, castingPlayer.Cell))
                {
                    player.IsPowered = true;
                    newlyPoweredPlayers.Enqueue(player);
                }
        }
    }
}