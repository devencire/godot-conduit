using System;
using System.Collections.Generic;
using System.Linq;
using conduit.scripts.weapons;
using Godot;

namespace conduit.scripts;

public partial class Player : Node
{
    [Signal]
    public delegate void ActedThisTurnChangedEventHandler(Player player, bool actedThisTurn);

    [Signal]
    public delegate void CellChangedEventHandler(Player player, Vector2I cell);

    [Signal]
    public delegate void CurrentStatusChangedEventHandler(Player player, Status status);

    [Signal]
    public delegate void DashesUsedChangedEventHandler(Player player, int dashesUsed);

    [Signal]
    public delegate void FreeMovesRemainingChangedEventHandler(Player player, int freeMovesRemaining);

    [Signal]
    public delegate void IsBeaconChangedEventHandler(Player player, bool isBeacon);

    [Signal]
    public delegate void IsOnActiveTeamChangedEventHandler(Player player, bool isOnActiveTeam);

    [Signal]
    public delegate void IsPoweredChangedEventHandler(Player player, bool isPowered);

    [Signal]
    public delegate void ResolveChangedEventHandler(Player player, int resolve);

    [Signal]
    public delegate void SelectedChangedEventHandler(Player player, bool selected);

    [Signal]
    public delegate void InitializedEventHandler(Player player);

    public enum Status
    {
        Ok,
        Dazed,
        KnockedOut
    }

    private static int _nextDebugNameId = 1;

    private static readonly PackedScene _pathPreviewTileScene =
        GD.Load<PackedScene>("res://scenes/path_preview_tile.tscn");

    private bool _actedThisTurn;
    public ArenaTileMap ArenaTileMap;

    private Vector2I _cell;
    private ControlZones _controlZones;

    private Status _currentStatus;

    private int _dashesUsed;

    private int _freeMovesRemaining;

    private Node2D _graphic;

    private Vector2I _hoveredCell;

    private bool _isBeacon;

    private bool _isOnActiveTeam;

    private bool _isPowered;

    private Node2D? _pathPreview;
    public Players Players;
    private Popups _popups;
    private NodePath _positionPath = new(Node2D.PropertyName.Position);

    private int _resolve;

    [Export] public RoundRoot RoundRoot;
    private ScoreState _scoreState;

    private bool _selected;
    private AnimatedSprite2D _sprite;
    public TurnState TurnState;

    public string DebugName;
    public EventLog EventLog;

    public bool Moving;

    public PlayerStats Stats = new();

    public Team Team;

    private Tween? tween;

    public Weapon Weapon;

    public bool ActedThisTurn
    {
        get => _actedThisTurn;
        set
        {
            _actedThisTurn = value;
            EmitSignal(SignalName.ActedThisTurnChanged, this, value);
            // TODO move this somewhere else
            if (Selected) Selected = false;
        }
    }

    public Status CurrentStatus
    {
        get => _currentStatus;
        set
        {
            _currentStatus = value;
            EmitSignal(SignalName.CurrentStatusChanged, this, (int)value);
        }
    }

    public int DashesUsed
    {
        get => _dashesUsed;
        set
        {
            _dashesUsed = value;
            EmitSignal(SignalName.DashesUsedChanged, this, value);
        }
    }

    public int FreeMovesRemaining
    {
        get => _freeMovesRemaining;
        set
        {
            _freeMovesRemaining = value;
            EmitSignal(SignalName.FreeMovesRemainingChanged, this, value);
        }
    }

    public bool IsBeacon
    {
        get => _isBeacon;
        set
        {
            _isBeacon = value;
            EmitSignal(SignalName.IsBeaconChanged, this, value);
        }
    }

    public bool IsOnActiveTeam
    {
        get => _isOnActiveTeam;
        set
        {
            _isOnActiveTeam = value;
            EmitSignal(SignalName.IsOnActiveTeamChanged, this, value);
        }
    }

    public bool IsPowered
    {
        get => _isPowered;
        set
        {
            _isPowered = value;
            EmitSignal(SignalName.IsPoweredChanged, this, value);
        }
    }

    public int Resolve
    {
        get => _resolve;
        set
        {
            _resolve = value;
            EmitSignal(SignalName.ResolveChanged, this, value);
        }
    }

    public bool Selected
    {
        get => _selected;
        set
        {
            _selected = value;
            EmitSignal(SignalName.SelectedChanged, this, value);
            // TODO move this somewhere else
            Moving = value;
            if (!value) _clearPathPreview();
        }
    }

    public Vector2I Cell
    {
        get => _cell;
        set
        {
            _cell = value;
            EmitSignal(SignalName.CellChanged, this, _cell);
        }
    }

    public bool Conscious => CurrentStatus != Status.KnockedOut;
    public bool CanAct => CurrentStatus == Status.Ok && !ActedThisTurn;

    public void Setup(Team team, Vector2I cell, Weapon weapon, bool isBeacon)
    {
        Team = team;
        Cell = cell;
        Weapon = weapon;
        IsBeacon = isBeacon;
    }

    public override void _Ready()
    {
        ArenaTileMap = RoundRoot.ArenaTileMap;
        TurnState = RoundRoot.TurnState;
        EventLog = RoundRoot.EventLog;
        _scoreState = RoundRoot.ScoreState;
        _controlZones = RoundRoot.ControlZones;
        _popups = RoundRoot.Popups;
        Players = GetParent<Players>();

        _graphic = GetNode<Node2D>("Graphic");
        _sprite = GetNode<AnimatedSprite2D>("Graphic/Sprite");
        DebugName = $"Player {_nextDebugNameId++}";
        _sprite.SelfModulate = Team.Color;
        _moveGraphicToCell();

        Resolve = Stats.StartingResolve;
        TurnState.NewTurnStarted += _turnStateOnNewTurnStarted;
        

        EmitSignal(SignalName.Initialized, this);
    }

    private void _turnStateOnNewTurnStarted(TurnState turnState)
    {
        if (turnState.ActiveTeam == Team)
        {
            ActedThisTurn = false;
            if (CanAct && !IsBeacon) FreeMovesRemaining = Stats.FreeMovesPerTurn;

            DashesUsed = 0;
        }
        else
        {
            FreeMovesRemaining = 0;
            DashesUsed = 0;
            if (CurrentStatus == Status.Dazed)
            {
                CurrentStatus = Status.Ok;
                EventLog.Log($"{BB.PlayerName(this)} recovered from being dazed");
            }
        }

        IsOnActiveTeam = turnState.ActiveTeam == Team;
    }

    public override void _UnhandledInput(InputEvent @event)
    {
        switch (@event)
        {
            case InputEventMouseMotion motionEvent:
            {
                var newHoveredCell = ArenaTileMap.GetHoveredCell(motionEvent);
                if (_hoveredCell == newHoveredCell) return;
                _hoveredCell = newHoveredCell;

                if (!Selected || !Moving)
                {
                    if (CurrentStatus == Status.Dazed)
                    {
                        if (Team == TurnState.ActiveTeam && Cell == newHoveredCell && IsPowered)
                            _updateRevivePreview();
                        else _clearPathPreview();
                    }

                    return;
                }

                if (IsBeacon && Cell != newHoveredCell && ArenaTileMap.CellsAreAligned(Cell, newHoveredCell))
                {
                    var hoveredPlayer = Players.PlayerInCell(newHoveredCell, Team);
                    if (hoveredPlayer is { CurrentStatus: Status.Ok })
                    {
                        _updatePassPreview(hoveredPlayer);
                        return;
                    }
                }

                var cellPath = ArenaTileMap.GetCellPath(Cell, newHoveredCell);
                if (cellPath != null) _updatePathPreview(cellPath);
                else _clearPathPreview();
                break;
            }
            case InputEventMouseButton { Pressed: true, ButtonIndex: MouseButton.Right } pressEvent:
            {
                var newHoveredCell = ArenaTileMap.GetHoveredCell(pressEvent);
                _handleRightClick(newHoveredCell);
                break;
            }
        }
    }

    private void _handleRightClick(Vector2I clickedCell)
    {
        if (!Selected || !Moving)
        {
            if (IsOnActiveTeam && CurrentStatus == Status.Dazed && IsPowered && clickedCell == Cell)
            {
                _tryRevivePlayer();
                GetViewport().SetInputAsHandled();
            }

            return;
        }

        if (clickedCell == Cell)
        {
            Selected = false;
            GetViewport().SetInputAsHandled();
            return;
        }

        if (IsBeacon && ArenaTileMap.CellsAreAligned(clickedCell, Cell))
        {
            var clickedPlayer = Players.PlayerInCell(clickedCell);
            if (clickedPlayer is { CurrentStatus: Status.Ok } && clickedPlayer.Team == Team)
            {
                _tryPassToPlayer(clickedPlayer);
                GetViewport().SetInputAsHandled();
                return;
            }
        }

        _tryMoveSelectedPlayer(clickedCell);
    }

    private void _updatePathPreview(IEnumerable<Vector2I> cellPath)
    {
        _clearPathPreview();
        _pathPreview = new Node2D();
        var freeMovesUsed = 0;
        var newDashesUsed = 0;
        var totalPowerCost = 0;
        foreach (var cell in cellPath)
        {
            var increasedCost = _dashesUsed + newDashesUsed >= Stats.DashesBeforeCostIncrease;
            if (freeMovesUsed < _freeMovesRemaining)
            {
                freeMovesUsed++;
            }
            else
            {
                totalPowerCost += increasedCost ? Constants.IncreasedDashCost : Constants.DashCost;
                newDashesUsed++;
            }

            var previewTile = _pathPreviewTileScene.Instantiate<PathPreviewTile>();
            previewTile.Position = ArenaTileMap.MapToLocal(cell);
            previewTile.PowerCost = totalPowerCost;
            previewTile.IncreasedCost = increasedCost;
            previewTile.SuccessChance = TurnState.ChanceThatPowerAvailable(totalPowerCost);
            _pathPreview.AddChild(previewTile);
        }

        AddChild(_pathPreview);
    }

    private void _updateRevivePreview()
    {
        _clearPathPreview();
        _pathPreview = new Node2D();
        var previewTile = _pathPreviewTileScene.Instantiate<PathPreviewTile>();
        previewTile.Position = ArenaTileMap.MapToLocal(Cell);
        previewTile.PowerCost = Stats.DazedReviveCost;
        previewTile.SuccessChance = TurnState.ChanceThatPowerAvailable(previewTile.PowerCost);
        _pathPreview.AddChild(previewTile);
        AddChild(_pathPreview);
    }

    private void _updatePassPreview(Player receiver)
    {
        _clearPathPreview();
        _pathPreview = new Node2D();
        var previewTile = _pathPreviewTileScene.Instantiate<PathPreviewTile>();
        previewTile.Position = ArenaTileMap.MapToLocal(receiver.Cell);
        previewTile.PowerCost = Stats.PassCost;
        previewTile.SuccessChance = TurnState.ChanceThatPowerAvailable(previewTile.PowerCost);
        _pathPreview.AddChild(previewTile);
        AddChild(_pathPreview);
    }

    private void _clearPathPreview()
    {
        _pathPreview?.QueueFree();
        _pathPreview = null;
    }

    private void _moveGraphicToCell()
    {
        _graphic.Position = ArenaTileMap.MapToLocal(Cell);
    }

    private void _tryMoveSelectedPlayer(Vector2I destination)
    {
        var cellPath = ArenaTileMap.GetCellPath(Cell, destination);
        if (cellPath == null) return;
        var walkSteps = new List<WalkStep>();
        var powerSpent = 0;
        foreach (var cell in cellPath)
        {
            var stepCost = 0;
            if (FreeMovesRemaining > 0)
            {
                FreeMovesRemaining--;
            }
            else
            {
                stepCost = DashesUsed < Stats.DashesBeforeCostIncrease
                    ? Constants.DashCost
                    : Constants.IncreasedDashCost;
                if (!TurnState.TrySpendPower(stepCost))
                {
                    EventLog.Log(walkSteps.Count == 0
                        ? $"{BB.PlayerName(this)} tried to move but ran out of power!"
                        : $"{BB.PlayerName(this)} ran out of power after spending {powerSpent}\u26a1 to move {walkSteps.Count} spaces!");
                    Selected = false;
                    break;
                }

                DashesUsed++;
            }

            powerSpent += stepCost;
            walkSteps.Add(new WalkStep(cell, stepCost));
        }

        if (walkSteps.Count > 0) WalkPath(walkSteps);
        if (!Selected) return;
        EventLog.Log(powerSpent > 0
            ? $"{BB.PlayerName(this)} spent {powerSpent}\u26a1 to move {walkSteps.Count} spaces"
            : $"{BB.PlayerName(this)} moved {walkSteps.Count} spaces");
        _clearPathPreview();
    }

    public void WalkPath(List<WalkStep> walkSteps)
    {
        _moveGraphicToCell();
        tween?.Kill();
        tween = CreateTween();
        foreach (var step in walkSteps)
        {
            tween.TweenProperty(_graphic, _positionPath, ArenaTileMap.MapToLocal(step.Cell), 0.2)
                .SetTrans(Tween.TransitionType.Sine).SetEase(Tween.EaseType.InOut);
            if (step.PowerCost > 0)
                tween.TweenCallback(Callable.From(() => SpawnPopupAtSprite($"-{step.PowerCost}\u26a1")));
        }

        Cell = walkSteps.Last().Cell;
    }

    public void SpawnPopupAtSprite(string text)
    {
        _popups.SpawnResourcePopup(text, _graphic.Position with { Y = _graphic.Position.Y - 60 });
    }

    private void _tryRevivePlayer()
    {
        var powerCost = Stats.DazedReviveCost;
        if (!TurnState.TrySpendPower(powerCost))
        {
            EventLog.Log($"{BB.PlayerName(this)} tried to recover from being dazed but ran out of power!");
            return;
        }

        Revive();
        EventLog.Log($"{BB.PlayerName(this)} spent ${powerCost}\u26a1 to recover from being dazed");
        SpawnPopupAtSprite($"-{powerCost}\u26a1");
        _clearPathPreview();
    }

    private void _tryPassToPlayer(Player receiver)
    {
        var powerCost = Stats.PassCost;
        if (!TurnState.TrySpendPower(powerCost))
        {
            EventLog.Log(
                $"{BB.PlayerName(this)} tried to pass the beacon to {BB.PlayerName(receiver)} but ran out of power and dropped it!");
            RoundRoot.EndRound();
            _scoreState.ScorePoints(Constants.OtherTeam(Team), Constants.PointsForDroppingBeacon);
            return;
        }

        PassTo(receiver);
        EventLog.Log($"{BB.PlayerName(this)} spent {powerCost}\u26a1 to pass the beacon to {BB.PlayerName(receiver)}!");
        SpawnPopupAtSprite($"-{powerCost}\u26a1");
    }

    public void PushTo(Vector2I cell, Player pusher)
    {
        _moveGraphicToCell();
        tween?.Kill();
        tween = CreateTween();
        tween.TweenProperty(_graphic, _positionPath, ArenaTileMap.MapToLocal(cell), 0.2)
            .SetTrans(Tween.TransitionType.Sine).SetEase(Tween.EaseType.InOut);
        Cell = cell;
        if (!ArenaTileMap.CellIsPathable(cell)) TakeDamage(new DamageSource.OutOfArena(pusher));
    }

    public void DazeIfNotDazed()
    {
        if (CurrentStatus != Status.Ok) return;
        CurrentStatus = Status.Dazed;
        EventLog.Log($"{BB.PlayerName(this)} is dazed");
    }

    public void TakeDamage(DamageSource source)
    {
        var remainingDamage = source.Amount;
        if (!source.PiercesResolve)
        {
            var damageAbsorbedByResolve = Math.Min(Resolve, remainingDamage);
            Resolve -= damageAbsorbedByResolve;
            remainingDamage -= damageAbsorbedByResolve;
        }

        EventLog.Log($"{BB.PlayerName(this)} took {source.Amount} damage {source.DisplayText}");

        var statusAltered = false;
        if (remainingDamage > 0 && CurrentStatus == Status.Ok)
        {
            remainingDamage -= 1;
            CurrentStatus = Status.Dazed;
            statusAltered = true;
        }

        if (remainingDamage > 0 && CurrentStatus == Status.Dazed)
        {
            remainingDamage -= 1;
            CurrentStatus = Status.KnockedOut;
            statusAltered = true;
        }

        if (remainingDamage > 0)
        {
            // longer-term wounds
        }

        if (statusAltered && CurrentStatus == Status.Dazed)
        {
            EventLog.Log($"{BB.PlayerName(this)} was dazed by damage");
        }
        else if (statusAltered && CurrentStatus == Status.KnockedOut)
        {
            EventLog.Log($"{BB.PlayerName(this)} was knocked unconscious by damage!");
            if (IsBeacon)
            {
                RoundRoot.EndRound();
                _scoreState.ScorePoints(Constants.OtherTeam(Team), Constants.PointsForSackingBeacon);
            }
        }
    }

    public void ResolvePush(Player target, TileSet.CellNeighbor direction, int force)
    {
        var currentCell = target.Cell;
        var distance = 0;
        Player? clashedWith = null;

        while (force > 0)
        {
            distance += 1;
            var previousCell = currentCell;
            currentCell = ArenaTileMap.GetNeighborCell(currentCell, direction);
            if (!ArenaTileMap.CellIsPathable(currentCell))
            {
                if (ArenaTileMap.CellIsWall(currentCell))
                {
                    target.PushTo(previousCell, this);
                    EventLog.Log(distance > 1
                        ? $"{BB.PlayerName(this)} pushed {BB.PlayerName(target)} {distance - 1} spaces into a wall"
                        : $"{BB.PlayerName(this)} pushed {BB.PlayerName(target)} into a wall");
                    target.TakeDamage(new DamageSource.PushedIntoWall(this, force));
                    return;
                }
                else
                {
                    EventLog.Log(
                        $"{BB.PlayerName(this)} pushed {BB.PlayerName(target)} {distance} spaces, off the arena!");
                    target.PushTo(currentCell, this);
                    return;
                }
            }

            var playerInNextCell = Players.PlayerInCell(currentCell);
            if (playerInNextCell != null)
            {
                clashedWith = playerInNextCell;
                EventLog.Log(
                    $"{BB.PlayerName(this)} pushed {BB.PlayerName(target)} {distance} spaces into {BB.PlayerName(clashedWith)}");
                break;
            }

            force--;
        }

        ;

        target.PushTo(currentCell, this);
        if (clashedWith != null)
        {
            target.TakeDamage(new DamageSource.PushedIntoPlayer(this, clashedWith));
            clashedWith.TakeDamage(new DamageSource.HitByPushedPlayer(this, target));
            ResolvePush(clashedWith, direction, Math.Max(force - 1, 1));
        }
        else
        {
            EventLog.Log($"{BB.PlayerName(this)} pushed {BB.PlayerName(target)} {distance} spaces");
        }
    }

    public void Revive()
    {
        CurrentStatus = Status.Ok;
        _freeMovesRemaining = Stats.FreeMovesPerTurn;
    }

    public void PassTo(Player receiver)
    {
        IsBeacon = false;
        receiver.IsBeacon = true;
        receiver.FreeMovesRemaining = 0;
        ActedThisTurn = true;
    }

    public Vector2 ArenaTileMapPosition(Vector2I? cell = null)
    {
        return ArenaTileMap.MapToLocal(cell ?? Cell);
    }

    public record WalkStep(Vector2I Cell, int PowerCost);
}