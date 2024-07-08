using Godot;

namespace conduit.scripts;

public partial class Selection : Node
{
    private ArenaTileMap _arenaTileMap;
    private TurnState _turnState;
    private Players _players;

    private Player? _selectedPlayer;
    
    public override void _Ready()
    {
        _arenaTileMap = GetNode<ArenaTileMap>("%ArenaTileMap");
        _turnState = GetNode<TurnState>("%TurnState");
        _players = GetNode<Players>("%Players");
    }

    public override void _UnhandledInput(InputEvent @event)
    {
        if (@event is InputEventMouseButton { Pressed: true, ButtonIndex: MouseButton.Left } clickEvent)
        {
            var clickedCell = _arenaTileMap.GetHoveredCell(clickEvent);
            var player = _players.PlayerInCell(clickedCell, _turnState.ActiveTeam);
            if (player is { CanAct: true })
            {
                if (player != _selectedPlayer)
                {
                    _selectPlayer(player);
                }
                else
                {
                    _deselectPlayer();
                }
            }
        }
    }

    private void _selectPlayer(Player player)
    {
        if (player == _selectedPlayer) return;
        _deselectPlayer();
        _selectedPlayer = player;
        _selectedPlayer.Selected = true;
        _selectedPlayer.SelectedChanged += _selectedPlayerOnSelectedChanged;
    }

    private void _deselectPlayer()
    {
        if (_selectedPlayer == null) return;
        _selectedPlayer.SelectedChanged -= _selectedPlayerOnSelectedChanged;
        _selectedPlayer.Selected = false;
        _selectedPlayer = null;
    }

    private void _selectedPlayerOnSelectedChanged(Player player, bool selected)
    {
        if (player == _selectedPlayer && !selected) _deselectPlayer();
    }

    private void _onTurnStateNewTurnStarted(TurnState _)
    {
        Callable.From(_deselectPlayer).CallDeferred();
    }
}