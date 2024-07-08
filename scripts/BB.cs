namespace conduit.scripts;

// ReSharper disable once InconsistentNaming
public abstract class BB
{
    public static string TeamName(Team team)
    {
        return $"[color={team.Color.ToHtml()}]Team {team.Name}[/color]";
    }

    public static string PlayerName(Player player)
    {
        return $"[color={player.Team.Color.ToHtml()}]{player.DebugName}[/color]";
    }
}