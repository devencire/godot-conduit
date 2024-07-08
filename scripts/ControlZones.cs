using System.Linq;
using Godot;

namespace conduit.scripts;

public partial class ControlZones : Node2D
{
    private const int ZoneSource = 1;
    private static readonly Vector2I ZoneAtlasCoords = new(0, 1);

    [Export] private ArenaTileMap _arenaTileMap;

    private TileMap _teamOneZones;
    private TileMap _teamTwoZones;
    [Export] private TurnState _turnState;
    [Export] private Players players;


    public override void _Ready()
    {
        base._Ready();
        _teamOneZones = GetNode<TileMap>("TeamOneZones");
        _teamTwoZones = GetNode<TileMap>("TeamTwoZones");
    }

    private TileMap _zonesMapForTeam(Team team)
    {
        if (team == Constants.TeamOne) return _teamOneZones;
        return _teamTwoZones;
    }

    private void _setControlZones()
    {
        if (!IsInsideTree()) return;

        foreach (var team in Constants.Teams) _setControlZonesForTeam(team);
    }

    private void _setControlZonesForTeam(Team team)
    {
        var zonesMap = _zonesMapForTeam(team);
        zonesMap.Clear();

        var threateningPlayers =
            players.PlayersOnTeam(team).Where(p => p.IsPowered && p.CurrentStatus == Player.Status.Ok);
        foreach (var player in threateningPlayers)
        {
            var zoneCellsByDirection = _arenaTileMap.AlignedCellsAtRange(player.Cell, 1);
            var zoneCells = zoneCellsByDirection.Values.ToList();
            zoneCells.Add(player.Cell);
            foreach (var cell in zoneCells) zonesMap.SetCell(0, cell, ZoneSource, ZoneAtlasCoords);
        }

        zonesMap.Modulate = team.ZoneColor;
        if (team == _turnState.ActiveTeam)
            zonesMap.Modulate = zonesMap.Modulate with { A = zonesMap.Modulate.A * 0.8f };
        else
            MoveChild(zonesMap, 1);
    }

    public bool CellControlledByTeam(Vector2I cell, Team team)
    {
        return _zonesMapForTeam(team).GetCellSourceId(0, cell) != -1;
    }
}