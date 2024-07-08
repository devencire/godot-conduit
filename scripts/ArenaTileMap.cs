using System.Collections.Generic;
using System.Data;
using System.Linq;
using Godot;

namespace conduit.scripts;

public partial class ArenaTileMap : TileMap
{
    private const int GroundLayer = 0;
    private const int WallLayer = 1;

    public static readonly TileSet.CellNeighbor[] HexCellNeighbors =
    {
        TileSet.CellNeighbor.TopSide, TileSet.CellNeighbor.TopRightSide, TileSet.CellNeighbor.BottomRightSide,
        TileSet.CellNeighbor.BottomSide, TileSet.CellNeighbor.BottomLeftSide, TileSet.CellNeighbor.TopLeftSide
    };

    private static readonly Dictionary<Vector2I, TileSet.CellNeighbor> DirectionForCellDelta = new()
    {
        { new Vector2I(-1, -1), TileSet.CellNeighbor.TopSide },
        { new Vector2I(0, -1), TileSet.CellNeighbor.TopRightSide },
        { new Vector2I(1, 0), TileSet.CellNeighbor.BottomRightSide },
        { new Vector2I(1, 1), TileSet.CellNeighbor.BottomSide },
        { new Vector2I(0, 1), TileSet.CellNeighbor.BottomLeftSide },
        { new Vector2I(-1, 0), TileSet.CellNeighbor.TopLeftSide }
    };

    private static readonly Dictionary<TileSet.CellNeighbor, Vector2I>
        CellDeltaForDirection = DirectionForCellDelta.ToDictionary(x => x.Value, x => x.Key);

    private ZoneRespectingAStar2D? _aStar;
    [Export] private ControlZones _controlZones;
    private List<int> _disabledPointIds = new();

    public static Vector2I AdjacentCellInDirection(Vector2I cell, TileSet.CellNeighbor direction)
    {
        return cell + CellDeltaForDirection[direction];
    }

    public override void _Ready()
    {
        _aStar = _buildAStar();
    }

    private ZoneRespectingAStar2D _buildAStar()
    {
        var cells = GetUsedCells(GroundLayer);
        var aStar = new ZoneRespectingAStar2D(_controlZones);
        aStar.ReserveSpace(cells.Count);
        var tileScale = new Vector2(TileSet.TileSize.X, TileSet.TileSize.Y);
        foreach (var cell in cells) aStar.AddPoint(_cellToAStarId(cell), MapToLocal(cell) / tileScale);
        foreach (var cell in cells)
        {
            var cellId = _cellToAStarId(cell);
            foreach (var surroundingCell in GetSurroundingCells(cell))
            {
                var surroundingCellId = _cellToAStarId(surroundingCell);
                if (aStar.HasPoint(surroundingCellId)) aStar.ConnectPoints(cellId, surroundingCellId);
            }
        }

        return aStar;
    }

    /**
     * <summary>
     *     Gets the shortest path of cells from start to end, or an empty array if there is no such path.
     * </summary>
     */
    public IEnumerable<Vector2I>? GetCellPath(Vector2I start, Vector2I end)
    {
        var startId = _cellToAStarId(start);
        var endId = _cellToAStarId(end);
        if (!_aStar.HasPoint(startId) || !_aStar.HasPoint(endId) || _aStar.IsPointDisabled(endId)) return null;
        var idPath = _aStar.GetIdPath(startId, endId);
        var otherTeam = Constants.OtherTeam(_aStar.MovingTeam);
        var cells = new List<Vector2I>();
        foreach (var id in idPath)
        {
            var cell = _aStarIdToCell(id);
            if (id != idPath.Last() && _controlZones.CellControlledByTeam(cell, otherTeam)) return null;
            cells.Add(cell);
        }

        return cells.Skip(1);
    }

    private static int _cellToAStarId(Vector2I cell)
    {
        return 10000 + cell.X + cell.Y * 100;
    }

    private static Vector2I _aStarIdToCell(long id)
    {
        var withoutConst = (int)id - 10000;
        var y = Mathf.RoundToInt(withoutConst / 100.0);
        return new Vector2I(withoutConst - y * 100, y);
    }

    public static bool CellsAreAligned(Vector2I first, Vector2I second)
    {
        return first.X == second.X || first.Y == second.Y || first.X - first.Y == second.X - second.Y;
    }

    public Vector2I GetHoveredCell(InputEventMouse evt)
    {
        var localEvt = (InputEventMouse)MakeInputLocal(evt);
        return LocalToMap(localEvt.Position);
    }

    /**
     * <summary>
     *     Returns the cells in the lines in the six directions from `center_cell`.
     *     Lines are blocked only by non-pathable tiles (i.e. walls but not players).
     * </summary>
     */
    public Dictionary<TileSet.CellNeighbor, List<Vector2I>> AlignedCells(Vector2I centerCell)
    {
        var alignedCellsByDirection = new Dictionary<TileSet.CellNeighbor, List<Vector2I>>();
        foreach (var direction in HexCellNeighbors)
        {
            var cells = new List<Vector2I>();
            var currentCell = centerCell;
            while (true)
            {
                currentCell = GetNeighborCell(currentCell, direction);
                if (!CellIsGround(currentCell)) break;

                cells.Add(currentCell);
            }

            alignedCellsByDirection[direction] = cells;
        }

        return alignedCellsByDirection;
    }

    public Dictionary<TileSet.CellNeighbor, Vector2I> AlignedCellsAtRange(
        Vector2I centerCell, int distance)
    {
        var alignedCells = new Dictionary<TileSet.CellNeighbor, Vector2I>();
        foreach (var direction in HexCellNeighbors)
        {
            var currentCell = centerCell;
            var obstructed = false;
            for (var n = 0; n < distance; n++)
            {
                currentCell = GetNeighborCell(currentCell, direction);
                if (!CellIsGround(currentCell))
                {
                    obstructed = true;
                    break;
                }
            }

            if (!obstructed) alignedCells[direction] = currentCell;
        }

        return alignedCells;
    }

    public bool CellIsGround(Vector2I cell)
    {
        return GetCellSourceId(GroundLayer, cell) != -1;
    }

    public bool CellIsWall(Vector2I cell)
    {
        return GetCellSourceId(WallLayer, cell) != -1;
    }

    public bool CellIsPathable(Vector2I cell)
    {
        return _aStar.HasPoint(_cellToAStarId(cell));
    }

    public static int DistanceFromHalfwayLine(Vector2I cell)
    {
        return cell.X - cell.Y;
    }

    /**
     * <summary>Get which direction goes from <c>from</c> to <c>to</c>. Only valid for aligned cells.</summary>
     */
    public static TileSet.CellNeighbor DirectionOfCell(Vector2I from, Vector2I to)
    {
        var delta = to - from;
        if (delta.X != 0 && delta.Y != 0 && Mathf.Abs(delta.X) != Mathf.Abs(delta.Y)) throw new ConstraintException();

        delta /= Mathf.Max(Mathf.Abs(delta.X), Mathf.Abs(delta.Y));
        if (!DirectionForCellDelta.ContainsKey(delta)) throw new ConstraintException();

        return DirectionForCellDelta[delta];
    }

    /**
     * <summary>
     *     Remove all existing pathfinding obstacles and create up-to-date ones.
     *     TODO do this incrementally instead?
     * </summary>
     */
    private void _updateObstacles(IEnumerable<Player> players)
    {
        if (_aStar == null) return;
        foreach (var disabledPointId in _disabledPointIds) _aStar.SetPointDisabled(disabledPointId, false);

        _disabledPointIds = new List<int>();
        foreach (var player in players)
        {
            var astarId = _cellToAStarId(player.Cell);
            if (_aStar.HasPoint(astarId))
            {
                _aStar.SetPointDisabled(astarId);
                _disabledPointIds.Add(astarId);
            }
        }
    }

    private void _onPlayersChanged(Players players)
    {
        _updateObstacles(players.AllPlayers);
    }

    private void _onTurnStateNewTurnStarted(TurnState state)
    {
        _aStar.MovingTeam = state.ActiveTeam;
    }

    /**
     * <summary>
     *     A specialised <c>AStar2D</c> that knows the <c>MovingTeam</c> and heavily penalises moves
     *     that leave a tile controlled by the opposing team (since players cannot normally
     *     make such moves).
     * </summary>
     */
    private partial class ZoneRespectingAStar2D : AStar2D
    {
        private readonly ControlZones _controlZones;
        public Team MovingTeam = Constants.TeamOne;

        public ZoneRespectingAStar2D()
        {
        }

        public ZoneRespectingAStar2D(ControlZones controlZones)
        {
            _controlZones = controlZones;
        }

        public override float _ComputeCost(long fromId, long toId)
        {
            // heavily penalise moving out of opponent's controlled zones (since players cannot normally do this)
            var fromCell = _aStarIdToCell(fromId);
            if (_controlZones.CellControlledByTeam(fromCell, Constants.OtherTeam(MovingTeam))) return 100000;

            // return GetPointPosition(fromId).DistanceTo(GetPointPosition(toId));
            return base._ComputeCost(fromId, toId);
        }
    }
}