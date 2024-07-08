using Godot;

namespace conduit.scripts;

public partial class PathPreviewTile : Node2D
{
    [Export] public bool IncreasedCost;
    [Export] public int PowerCost;
    [Export] public float SuccessChance;

    public override void _Ready()
    {
        var powerCostLabel = GetNode<RichTextLabel>("PowerCostLabel");
        var freeMoveDisplay = GetNode<RichTextLabel>("FreeMoveDisplay");
        var successChanceLabel = GetNode<RichTextLabel>("SuccessChanceLabel");
        if (PowerCost > 0)
        {
            powerCostLabel.Visible = true;
            powerCostLabel.Clear();
            powerCostLabel.Text = "";
            powerCostLabel.PushParagraph(HorizontalAlignment.Center);
            powerCostLabel.PushOutlineSize(8);
            powerCostLabel.PushOutlineColor(IncreasedCost ? Colors.Red : Colors.Black);
            powerCostLabel.AppendText($"{PowerCost}\u26a1");
            freeMoveDisplay.Visible = false;
        }
        else
        {
            freeMoveDisplay.Visible = true;
            powerCostLabel.Visible = false;
        }

        successChanceLabel.Clear();
        successChanceLabel.Text = "";
        successChanceLabel.PushParagraph(HorizontalAlignment.Center);
        successChanceLabel.PushOutlineSize(8);
        successChanceLabel.PushOutlineColor(IncreasedCost ? Colors.Red : Colors.Black);
        successChanceLabel.PushColor(Constants.SuccessChanceColor(SuccessChance));
        successChanceLabel.AppendText($"{Mathf.Round(SuccessChance * 100)}%");
    }
}