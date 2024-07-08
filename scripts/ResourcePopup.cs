using Godot;

namespace conduit.scripts;

public partial class ResourcePopup : CenterContainer
{
    private static readonly NodePath PosPath = new(Control.PropertyName.Position);
    private static readonly NodePath ModulatePath = new(CanvasItem.PropertyName.Modulate);
    private RichTextLabel _label;
    [Export] public string Text = "";

    public override void _Ready()
    {
        _label = GetNode<RichTextLabel>("RichTextLabel");
        _label.Clear();
        _label.Text = "";
        _label.PushParagraph(HorizontalAlignment.Center);
        _label.PushOutlineSize(8);
        _label.PushOutlineColor(Colors.Black);
        _label.AppendText(Text);

        var startingPos = Position;
        var tween = CreateTween();
        tween.TweenProperty(this, PosPath, startingPos - new Vector2(0, 40), 1.2);
        tween.TweenProperty(this, PosPath, startingPos - new Vector2(0, 60), 0.6);
        tween.Parallel().TweenProperty(this, ModulatePath, Colors.White with { A = 0 },
            0.6);
        tween.TweenCallback(Callable.From(QueueFree));
    }
}