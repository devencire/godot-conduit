using System;
using System.Collections.Generic;
using conduit.scripts.attack_effects;
using Godot;

namespace conduit.scripts.attack_options;

public partial class HammerOverchargedPushAttackOption : HammerPushAttackOption
{
    private const int PowerPerForce = 2;
    
    public override string DisplayName => "Overcharged Bludgeon";

    public override int BasePowerCost => 2;

    public override void DisplayDirections(Player attacker, Player target, Node2D parentNode, Action<TileSet.CellNeighbor> doAttack)
    {
        var validDirections = GetValidDirections(attacker, target);
        foreach (var direction in validDirections)
        {
            parentNode.AddChild(CreateClickableDirectionNode(attacker, target, direction, BasePowerCost, doAttack));
            var cell = ArenaTileMap.AdjacentCellInDirection(target.Cell, direction);
            for (var totalCost = BasePowerCost; totalCost <= attacker.TurnState.MaxRemainingPower; totalCost += PowerPerForce)
            {
                cell = ArenaTileMap.AdjacentCellInDirection(cell, direction);
                var tile = TargetPreviewTileScene.Instantiate<TargetPreviewTile>();
                tile.Position = attacker.ArenaTileMapPosition(cell);
                tile.Direction = direction;
                tile.Team = attacker.Team;
                tile.Type = TargetPreviewTile.PreviewTileType.FadedArrow;
                tile.SuccessChance = attacker.TurnState.ChanceThatPowerAvailable(totalCost);
                parentNode.AddChild(tile);
                if (!attacker.ArenaTileMap.CellIsPathable(cell)) break;
            }
        }
    }

    public override IEnumerable<AttackEffect> GetEffects(Player attacker, Player? target, TileSet.CellNeighbor direction)
    {
        return new AttackEffect[]
        {
            new TargetNotPoweredMetaEffect(new DazeTargetEffect(attacker, DisplayName, target), target),
            new DirectDamageEffect(attacker, DisplayName, 1, target),
            new OverchargedVariablePushEffect(attacker, DisplayName, 1, BasePowerCost, PowerPerForce, direction,
                target),
            new EndTurnEffect(attacker.TurnState),
        };
    }
}