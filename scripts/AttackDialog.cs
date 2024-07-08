using System.Collections.Generic;
using conduit.scripts.attack_options;
using Godot;
using Godot.Collections;

namespace conduit.scripts;

public partial class AttackDialog : CanvasLayer
{
    [Signal]
    public delegate void SelectedOptionChangedEventHandler(AttackDialog attackDialog, AttackOption selectedOption);

    [Signal]
    public delegate void TargetChangedEventHandler(AttackDialog attackDialog, Player target);

    private static readonly PackedScene _attackOptionDescriptionScene =
        GD.Load<PackedScene>("res://scenes/attack_option_description.tscn");

    // Used to suppress option_selected signals when tabs are recreated on target change.
    private bool _regenerating;

    private AttackOption _selectedOption;

    private TabContainer _tabContainer;

    private Player? _target;
    [Export] public Player Attacker;
    [Export] public Array<AttackOption> AttackOptions;

    public AttackOption SelectedOption
    {
        get => _selectedOption;
        set
        {
            _selectedOption = value;
            EmitSignal(SignalName.SelectedOptionChanged, this, value);
            if (IsInsideTree()) _regenerateAttackOptionTabs();
        }
    }

    public Player? Target
    {
        get => _target;
        set
        {
            _target = value;
            EmitSignal(SignalName.TargetChanged, this, value);
            if (IsInsideTree()) _regenerateAttackOptionTabs();
        }
    }

    public override void _Ready()
    {
        _tabContainer = GetNode<TabContainer>("%TabContainer");
        _regenerateAttackOptionTabs();
    }

    private void _regenerateAttackOptionTabs()
    {
        _regenerating = true;

        foreach (var child in _tabContainer.GetChildren())
        {
            _tabContainer.RemoveChild(child);
            child.QueueFree();
        }

        var originalOption = SelectedOption;
        foreach (var option in AttackOptions)
        {
            var isSelected = option == originalOption;
            var description = _attackOptionDescriptionScene.Instantiate<AttackOptionDescription>();
            description.AttackOption = option;
            description.Attacker = Attacker;
            description.Target = Target;
            _tabContainer.AddChild(description);
            var tabIndex = _tabContainer.GetChildCount() - 1;
            _tabContainer.SetTabTitle(tabIndex, option.DisplayName);
            if (isSelected) _tabContainer.CurrentTab = tabIndex;
        }

        _regenerating = false;
    }

    private void _onTabContainerTabChanged(int tabIndex)
    {
        if (_regenerating) return;
        SelectedOption = AttackOptions[tabIndex];
    }
}