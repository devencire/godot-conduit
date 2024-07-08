using System;
using conduit.scripts.attack_options;
using Godot;

namespace conduit.scripts;

public partial class AttackOptionDescription : MarginContainer
{
    [Export] public Player Attacker;
    [Export] public AttackOption AttackOption;
    [Export] public Player? Target;

    public override void _Ready()
    {
        var effectContainer = GetNode<VBoxContainer>("%EffectContainer");
        var powerCostLabel = GetNode<RichTextLabel>("%PowerCostLabel");
        var successChanceLabel = GetNode<RichTextLabel>("%SuccessChanceLabel");
        var attackEffectLabel = GetNode<RichTextLabel>("%AttackEffectLabel");

        powerCostLabel.Text = $"{AttackOption.BasePowerCost}\u26a1";
        var successChance = Attacker.TurnState.ChanceThatPowerAvailable(AttackOption.BasePowerCost);
        successChanceLabel.Text = $"{Math.Round(successChance * 100)}% chance";
        successChanceLabel.Modulate = Constants.SuccessChanceColor(successChance);

        var effects = AttackOption.GetEffects(Attacker, Target, TileSet.CellNeighbor.TopSide);
        foreach (var effect in effects)
        {
            var label = (RichTextLabel)attackEffectLabel.Duplicate();
            if (effect.Enabled)
            {
                label.Text = effect.DisplayText;
            }
            else
            {
                label.Text = $"[s]{effect.DisplayText}[/s]";
                label.Modulate = Colors.White with { A = 0.6f };
            }

            label.Visible = true;
            effectContainer.AddChild(label);
        }
    }
}