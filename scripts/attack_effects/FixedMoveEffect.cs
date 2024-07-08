using System.Collections.Generic;
using Godot;

namespace conduit.scripts.attack_effects;

public class FixedMoveEffect : AttackEffect
{
    private readonly Player _attacker;
    private readonly int _distance;
    private readonly TileSet.CellNeighbor _direction;
    private readonly string _directionDescription;

    public FixedMoveEffect(Player attacker, int distance, TileSet.CellNeighbor direction, string directionDescription)
    {
        _attacker = attacker;
        _distance = distance;
        _direction = direction;
        _directionDescription = directionDescription;
    }

    public override string DisplayText => $"move self {_distance} spaces {_directionDescription}";

    private Vector2I _findDestinationCell()
    {
        var cell = _attacker.Cell;
        for (var i = 0; i < _distance; i++)
        {
            cell = ArenaTileMap.AdjacentCellInDirection(cell, _direction);
        }

        return cell;
    }

    public override bool Enabled => _attacker.ArenaTileMap.CellIsPathable(_findDestinationCell());

    public override int Enact()
    {
        var destinationCell = _findDestinationCell();
        if (_attacker.ArenaTileMap.CellIsPathable(destinationCell) && destinationCell != _attacker.Cell)
        {
            _attacker.WalkPath(new List<Player.WalkStep> { new(destinationCell, 0) });
        }

        return 0;
    }
}