using System;
using Godot;

namespace conduit.scripts;

public partial class HealthBar : Node2D
{
    private Player? _player;
    private ColorRect? _healthRemainingRect;
    private ColorRect _healthBackRect;
    
    public override void _Ready()
    {
        _healthRemainingRect = GetNode<ColorRect>("HealthRemainingRect");
        _healthBackRect = GetNode<ColorRect>("HealthBackRect");
    }

    public override void _Draw()
    {
        if (_player == null) return;
        for (var notch = 1; notch <= _player.Stats.MaxResolve; notch++)
        {
            var xPos = _healthBackRect.Position.X +
                       Mathf.Lerp(0, _healthBackRect.Size.X, (float)notch / _player.Stats.MaxResolve);
            var from = new Vector2(xPos, _healthBackRect.Position.Y);
            var to = new Vector2(xPos, _healthBackRect.Position.Y + _healthBackRect.Size.Y / 2);
            DrawLine(from, to, Colors.Black, 2, false);
        }
    }

    private void _onPlayerInitialized(Player player)
    {
        _player = player;
        _updateHealthRemaining();
        QueueRedraw();
    }

    private void _onPlayerResolveChanged(Player player, int resolve)
    {
        _updateHealthRemaining();
    }

    private void _updateHealthRemaining()
    {
        if (_healthRemainingRect == null || _player == null) return;
        _healthRemainingRect.Size = _healthRemainingRect.Size with
        {
            X = 60 * (float)_player.Resolve / _player.Stats.MaxResolve
        };
    }
}