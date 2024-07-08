using Godot;

namespace conduit.scripts;

public partial class EventLog : RichTextLabel
{
    public void Log(string newText)
    {
        AppendText($"\n{newText}");
    }

    public void LogDeferred(string newText)
    {
        Callable.From(() => Log(newText)).CallDeferred();
    }
}