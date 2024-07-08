using System.Linq;
using Godot;

namespace conduit.scripts;

public partial class PowerLines : Node2D
{
    private static readonly PackedScene TileMapLayerScene =
        GD.Load<PackedScene>("res://scenes/power_line_tile_map_layer.tscn");

    [Export] private ArenaTileMap _arenaTileMap;
    [Export] private Players _players;
    [Export] private TurnState _turnState;

    private record TeamLayersRef(
        System.Collections.Generic.Dictionary<TileSet.CellNeighbor, TileMapLayer> Active,
        System.Collections.Generic.Dictionary<TileSet.CellNeighbor, TileMapLayer> Inactive);

    private System.Collections.Generic.Dictionary<Team, TeamLayersRef> _refsByTeam;

    private static readonly System.Collections.Generic.Dictionary<TileSet.CellNeighbor, Vector2I>
        AtlasCoordsForDirection = new()
        {
            { TileSet.CellNeighbor.TopSide, new Vector2I(0, 0) },
            { TileSet.CellNeighbor.TopRightSide, new Vector2I(1, 0) },
            { TileSet.CellNeighbor.BottomRightSide, new Vector2I(2, 1) },
            { TileSet.CellNeighbor.BottomSide, new Vector2I(0, 1) },
            { TileSet.CellNeighbor.BottomLeftSide, new Vector2I(1, 1) },
            { TileSet.CellNeighbor.TopLeftSide, new Vector2I(2, 0) }
        };

    private static readonly System.Collections.Generic.Dictionary<TileSet.CellNeighbor, TileSet.CellNeighbor>
        OppositeDirection = new()
        {
            { TileSet.CellNeighbor.TopSide, TileSet.CellNeighbor.BottomSide },
            { TileSet.CellNeighbor.TopRightSide, TileSet.CellNeighbor.BottomLeftSide },
            { TileSet.CellNeighbor.BottomRightSide, TileSet.CellNeighbor.TopLeftSide },
            { TileSet.CellNeighbor.BottomSide, TileSet.CellNeighbor.TopSide },
            { TileSet.CellNeighbor.BottomLeftSide, TileSet.CellNeighbor.TopRightSide },
            { TileSet.CellNeighbor.TopLeftSide, TileSet.CellNeighbor.BottomRightSide }
        };

    public override void _Ready()
    {
        // forgive me universe for I have sinned
        _refsByTeam = new System.Collections.Generic.Dictionary<Team, TeamLayersRef>()
        {
            { Constants.TeamOne, _instantiateTeamLayers(Constants.TeamOne, GetNode<Node2D>("TeamOne")) },
            { Constants.TeamTwo, _instantiateTeamLayers(Constants.TeamTwo, GetNode<Node2D>("TeamTwo")) }
        };
    }

    private TeamLayersRef _instantiateTeamLayers(Team team, Node2D teamRoot)
    {
        teamRoot.Modulate = team.Color;
        var activeParent = (Node2D)teamRoot.FindChild("Active");
        var inactiveParent = (Node2D)teamRoot.FindChild("Inactive");
        var tlRef = new TeamLayersRef(new System.Collections.Generic.Dictionary<TileSet.CellNeighbor, TileMapLayer>(),
            new System.Collections.Generic.Dictionary<TileSet.CellNeighbor, TileMapLayer>());
        foreach (var (direction, _) in AtlasCoordsForDirection)
        {
            tlRef.Active[direction] = _instantiateTileMapLayer(activeParent);
            tlRef.Inactive[direction] = _instantiateTileMapLayer(inactiveParent);
        }

        return tlRef;
    }

    private TileMapLayer _instantiateTileMapLayer(Node2D parent)
    {
        var layer = TileMapLayerScene.Instantiate<TileMapLayer>();
        parent.AddChild(layer);
        return layer;
    }

    private void _setPowerLines()
    {
        foreach (var team in Constants.Teams)
        {
            _setPowerLinesForTeam(team);
        }
    }

    private void _setPowerLinesForTeam(Team team)
    {
        var tlRef = _refsByTeam[team];
        foreach (var layer in tlRef.Active.Values) layer.Clear();
        foreach (var layer in tlRef.Inactive.Values) layer.Clear();
        foreach (var player in _players.AllPlayers.Where(p => p.Team == team && p.IsPowered))
        {
            _floodActivePowerLinesFromPlayer(player, tlRef);
            _setInactivePowerLinesFromPlayer(player, tlRef);
        }
    }

    private void _floodActivePowerLinesFromPlayer(Player caster, TeamLayersRef tlRef)
    {
        foreach (var player in _players.AllPlayers.Where(p =>
                     p.Team == caster.Team && p.IsPowered && p != caster &&
                     ArenaTileMap.CellsAreAligned(p.Cell, caster.Cell)))
        {
            var direction = ArenaTileMap.DirectionOfCell(caster.Cell, player.Cell);
            var oppositeDirection = OppositeDirection[direction];
            var activeLayer = tlRef.Active[direction];
            var oppositeActiveLayer = tlRef.Active[oppositeDirection];
            var atlasCoords = AtlasCoordsForDirection[direction];
            var oppositeAtlasCoords = AtlasCoordsForDirection[oppositeDirection];
            var currentCell = caster.Cell;
            activeLayer.SetCell(currentCell, 0, atlasCoords);
            while (currentCell != player.Cell)
            {
                currentCell = ArenaTileMap.AdjacentCellInDirection(currentCell, direction);
                oppositeActiveLayer.SetCell(currentCell, 0, oppositeAtlasCoords);
                if (currentCell != player.Cell)
                {
                    activeLayer.SetCell(currentCell, 0, atlasCoords);
                }
            }
        }
    }

    private void _setInactivePowerLinesFromPlayer(Player caster, TeamLayersRef tlRef)
    {
        var alignedCellsByDirection = _arenaTileMap.AlignedCells(caster.Cell);
        foreach (var (direction, alignedCells) in alignedCellsByDirection)
        {
            var oppositeDirection = OppositeDirection[direction];
            var inactiveLayer = tlRef.Inactive[direction];
            var oppositeInactiveLayer = tlRef.Inactive[oppositeDirection];
            var atlasCoords = AtlasCoordsForDirection[direction];
            var oppositeAtlasCoords = AtlasCoordsForDirection[oppositeDirection];
            inactiveLayer.SetCell(caster.Cell, 0, atlasCoords);
            foreach (var cell in alignedCells)
            {
                inactiveLayer.SetCell(cell, 0, atlasCoords);
                oppositeInactiveLayer.SetCell(cell, 0, oppositeAtlasCoords);
            }
        }
    }
}