using System.Collections.Generic;
using System.Linq;
using conduit.scripts.attack_options;
using Godot;
using Godot.Collections;

namespace conduit.scripts;

public partial class WeaponNode : Node
{
    private static readonly PackedScene TargetPreviewTileScene =
        GD.Load<PackedScene>("res://scenes/target_preview_tile.tscn");

    private static readonly PackedScene AttackDialogScene = GD.Load<PackedScene>("res://scenes/attack_dialog.tscn");
    private AttackDialog? _attackDialog;
    private AttackOption _selectedOption;
    private Player? _selectedTarget;

    private Node2D? _targetPreview;
    [Export] public Player Player;

    public override void _Ready()
    {
        Player.SelectedChanged += _playerSelectedChanged;
        Player.CellChanged += _playerCellChanged;
        Player.IsPoweredChanged += _playerIsPoweredChanged;

        _selectedOption = Player.Weapon.AttackOptions[0];
    }

    private void _playerSelectedChanged(Player _, bool selected)
    {
        if (selected)
        {
            _drawTargetSelectionPreview();
            _drawAttackDialog();
        }
        else
        {
            _clearSelectedTarget();
            _clearTargetPreview();
            _clearAttackDialog();
        }
    }

    private void _playerCellChanged(Player _, Vector2I cell)
    {
        if (Player.Selected) _clearSelectedTarget();
    }

    private void _playerIsPoweredChanged(Player _, bool isPowered)
    {
        _drawTargetSelectionPreview();
    }

    private void _drawTargetSelectionPreview()
    {
        _clearTargetPreview();
        if (!Player.Selected || !Player.IsPowered) return;
        _targetPreview = new Node2D();
        _drawSelectableTargets(_targetPreview);
        AddChild(_targetPreview);
    }

    private void _drawSelectableTargets(Node2D parentNode)
    {
        var validTargets = _getValidTargets();
        foreach (var target in validTargets)
        {
            var targetTile = TargetPreviewTileScene.Instantiate<TargetPreviewTile>();
            targetTile.Position = target.ArenaTileMapPosition();
            targetTile.Team = Player.Team;
            if (target == _selectedTarget)
            {
                targetTile.Type = TargetPreviewTile.PreviewTileType.SelectedCircle;
                targetTile.RightClicked += _clearSelectedTarget;
            }
            else
            {
                targetTile.Type = TargetPreviewTile.PreviewTileType.TeamCircle;
                targetTile.RightClicked += () => _selectTarget(target);
            }

            parentNode.AddChild(targetTile);
        }
    }

    private void _selectTarget(Player target)
    {
        _selectedTarget = target;
        if (!_selectedOption.GetValidTargets(Player).Contains(target))
            _selectedOption =
                Player.Weapon.AttackOptions.First(option => option.GetValidTargets(Player).Contains(target));

        _drawAttackDialog();
        _drawHitDirectionSelectionPreview();
        Player.Moving = false;
    }

    private void _clearSelectedTarget()
    {
        _selectedTarget = null;
        Player.Moving = true;
        _drawAttackDialog();
        _drawTargetSelectionPreview();
    }

    private void _drawHitDirectionSelectionPreview()
    {
        _clearTargetPreview();
        _targetPreview = new Node2D();
        _drawSelectableTargets(_targetPreview);
        _selectedOption.DisplayDirections(Player, _selectedTarget!, _targetPreview, _tryEnactingSelectedOption);
        AddChild(_targetPreview);
    }

    private void _drawAttackDialog()
    {
        if (_attackDialog != null)
        {
            _attackDialog.SelectedOption = _selectedOption;
            _attackDialog.Target = _selectedTarget;
            return;
        }

        _attackDialog = AttackDialogScene.Instantiate<AttackDialog>();
        _attackDialog.Attacker = Player;
        _attackDialog.Target = _selectedTarget;
        _attackDialog.AttackOptions = new Array<AttackOption>(Player.Weapon.AttackOptions);
        _attackDialog.SelectedOption = _selectedOption;
        _attackDialog.SelectedOptionChanged += _setAttackOption;
        AddChild(_attackDialog);
    }

    private void _clearAttackDialog()
    {
        _attackDialog?.QueueFree();
        _attackDialog = null;
    }

    private void _setAttackOption(AttackDialog _, AttackOption option)
    {
        _selectedOption = option;
        if (_selectedTarget == null) return;
        if (_selectedOption.GetValidTargets(Player).Contains(_selectedTarget))
            _drawHitDirectionSelectionPreview();
        else
            _clearSelectedTarget();
    }

    private void _clearTargetPreview()
    {
        _targetPreview?.QueueFree();
        _targetPreview = null;
    }

    private IEnumerable<Player> _getValidTargets()
    {
        var targets = new HashSet<Player>();
        foreach (var option in Player.Weapon.AttackOptions) targets.UnionWith(option.GetValidTargets(Player));

        return targets;
    }

    private void _tryEnactingSelectedOption(TileSet.CellNeighbor direction)
    {
        var attackCost = _selectedOption.BasePowerCost;
        if (!Player.TurnState.TrySpendPower(attackCost))
        {
            Player.EventLog.Log(
                $"{BB.PlayerName(Player)} tried to {_selectedOption.DisplayName} but didn't have {attackCost}\u26a1!");
            Player.Selected = false;
            return;
        }

        Player.EventLog.Log(
            $"{BB.PlayerName(Player)} spent {attackCost}\u26a1 to {_selectedOption.DisplayName} {BB.PlayerName(_selectedTarget!)}");
        var excessPowerUsed =
            (from effect in _selectedOption.GetEffects(Player, _selectedTarget, direction)
                where effect.Enabled
                select effect.Enact()).Prepend(0).Max();
        var totalPowerUsed = attackCost + excessPowerUsed;
        Player.SpawnPopupAtSprite($"-{totalPowerUsed}\u26a1");
        Player.ActedThisTurn = true;
        _selectedOption = Player.Weapon.AttackOptions.First();
    }
}