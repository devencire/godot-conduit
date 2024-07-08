using System.Collections.Generic;
using Godot;

namespace conduit.scripts;

public partial class TravelBoundaries : Node2D
{
    private static readonly Vector2I TeamOneBoundaryTileAtlasCoords = new Vector2I(2, 0);
    private static readonly Vector2I TeamTwoBoundaryTileAtlasCoords = new Vector2I(3, 0);
    [Export] private ScoreState _scoreState;
    [Export] private ArenaTileMap _arenaTileMap;
    private Dictionary<Team, TileMap> _boundariesByTeam;

    public override void _Ready()
    {
        _boundariesByTeam = new Dictionary<Team, TileMap>()
        {
            { Constants.TeamOne, GetNode<TileMap>("TeamOneBoundary") },
            { Constants.TeamTwo, GetNode<TileMap>("TeamTwoBoundary") }
        };
        _setTravelBoundaries();
    }

    private void _setTravelBoundaries()
    {
        foreach (var team in Constants.Teams)
        {
            _setTravelBoundary(team);
        }
    }

    private void _setTravelBoundary(Team team)
    {
        var boundaryTileMap = _boundariesByTeam[team];
        Vector2I atlasCoords;
        Vector2I nextCell;
        if (team == Constants.TeamOne)
        {
            atlasCoords = TeamOneBoundaryTileAtlasCoords;
            nextCell = new Vector2I(0, -_scoreState.TravelScores[0]);
        }
        else
        {
            atlasCoords = TeamTwoBoundaryTileAtlasCoords;
            nextCell = new Vector2I(-_scoreState.TravelScores[1], 0);
        }

        boundaryTileMap.Clear();
        boundaryTileMap.Modulate = team.Color;
        while (_arenaTileMap.CellIsPathable(nextCell - new Vector2I(1, 1)))
        {
            nextCell -= new Vector2I(1, 1);
        }

        while (_arenaTileMap.CellIsPathable(nextCell))
        {
            boundaryTileMap.SetCell(0, nextCell, 0, atlasCoords);
            nextCell += new Vector2I(1, 1);
        }
    }

    private void _onScoreStateChanged(ScoreState _)
    {
        _setTravelBoundaries();
    }
}