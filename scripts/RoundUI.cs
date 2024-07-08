using System;
using Godot;

namespace conduit.scripts;

public partial class RoundUI : Node
{
    [Signal]
    public delegate void EndTurnButtonPressedEventHandler();
    
    private Label _teamIndicator;
    private Label _copiedExcessPower;
    private Label _baseTurnPower;
    private Label _maximumRandomPower;
    private Label _knownRemainingPower;
    private Label _maximumRemainingPower;
    private Label _actualRemainingPower;
    private Button _endTurnButton;

    public override void _Ready()
    {
        _teamIndicator = GetNode<Label>("VBoxContainer/TeamIndicator");
        _copiedExcessPower = GetNode<Label>("VBoxContainer/CopiedExcessPower");
        _baseTurnPower = GetNode<Label>("VBoxContainer/BaseTurnPower");
        _maximumRandomPower = GetNode<Label>("VBoxContainer/MaximumRandomPower");
        _knownRemainingPower = GetNode<Label>("VBoxContainer/KnownRemainingPower");
        _maximumRemainingPower = GetNode<Label>("VBoxContainer/MaximumRemainingPower");
        _actualRemainingPower = GetNode<Label>("VBoxContainer/ActualRemainingPower");
        _endTurnButton = GetNode<Button>("VBoxContainer/EndTurnButton");
    }

    private void _onTurnStateChanged(TurnState turnState)
    {
        if (_teamIndicator == null)
        {
            Callable.From(() => _onTurnStateChanged(turnState)).CallDeferred();
            return;
        }

        _teamIndicator.Text = $"It is Team {turnState.ActiveTeam.Name}'s turn";
        _teamIndicator.LabelSettings.FontColor = turnState.ActiveTeam.Color;

        _copiedExcessPower.Text = $"Copied excess power: {turnState.CopiedExcessPower}\u26a1";
        _baseTurnPower.Text = $"Base turn power: {turnState.BaseTurnPower}\u26a1";
        _maximumRandomPower.Text = $"Maximum random power: {Constants.MaxExcessPower}\u26a1";

        _knownRemainingPower.Text = $"Known remaining power: {Math.Max(0, turnState.KnownRemainingPower)}\u26a1";
        _maximumRemainingPower.Text = $"Maximum possible remaining power: {turnState.MaxRemainingPower}\u26a1";
        _actualRemainingPower.Text = $"Actual remaining power: {turnState.ActualRemainingPower}\u26a1";
    }

    private void _onEndTurnButtonPressed()
    {
        EmitSignal(SignalName.EndTurnButtonPressed);
    }
}