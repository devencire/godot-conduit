using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using conduit.scripts.attack_effects;
using Godot;

namespace conduit.scripts.attack_options;

public abstract partial class AttackOption : Resource
{
    protected static readonly PackedScene TargetPreviewTileScene =
        GD.Load<PackedScene>("res://scenes/target_preview_tile.tscn");

    public virtual string DisplayName => "Missing name";
    public virtual int BasePowerCost => 0;
    public abstract IEnumerable<Player> GetValidTargets(Player attacker);
    public abstract IEnumerable<TileSet.CellNeighbor> GetValidDirections(Player attacker, Player target);

    public abstract IEnumerable<AttackEffect> GetEffects(Player attacker, Player? target,
        TileSet.CellNeighbor direction);

    public virtual void DisplayDirections(Player attacker, Player target, Node2D parentNode,
        Action<TileSet.CellNeighbor> doAttack)
    {
        foreach (var direction in GetValidDirections(attacker, target))
            parentNode.AddChild(CreateClickableDirectionNode(attacker, target, direction, BasePowerCost, doAttack));
    }

    protected static TargetPreviewTile CreateClickableDirectionNode(Player attacker, Player target,
        TileSet.CellNeighbor direction, int powerCost, Action<TileSet.CellNeighbor> doAttack)
    {
        var cell = ArenaTileMap.AdjacentCellInDirection(target.Cell, direction);
        var previewTile = TargetPreviewTileScene.Instantiate<TargetPreviewTile>();
        previewTile.Position = attacker.ArenaTileMapPosition(cell);
        previewTile.Direction = direction;
        previewTile.Team = attacker.Team;
        previewTile.Type = TargetPreviewTile.PreviewTileType.Arrow;
        previewTile.SuccessChance = attacker.TurnState.ChanceThatPowerAvailable(powerCost);
        previewTile.RightClicked += () => doAttack(direction);
        return previewTile;
    }

    protected static IEnumerable<Player> GetOpponentsAtRange(Player attacker, int distance)
    {
        return attacker.ArenaTileMap.AlignedCellsAtRange(attacker.Cell, distance).Values
            .Select(cell => attacker.Players.PlayerInCell(cell, Constants.OtherTeam(attacker.Team)))
            .Where(player => player != null)!;
    }

    protected static IEnumerable<Player> GetAdjacentOpponents(Player attacker)
    {
        return GetOpponentsAtRange(attacker, 1);
    }
}