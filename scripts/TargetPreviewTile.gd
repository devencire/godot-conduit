class_name TargetPreviewTile

extends Node2D

signal right_clicked

@onready var sprite: AnimatedSprite2D = $Sprite

enum PreviewTileType { TEAM_CIRCLE, SELECTED_CIRCLE, ARROW, FADED_ARROW }

@export var team: Constants.Team:
    set(new_team):
        team = new_team
        update_color()

@export var type: PreviewTileType:
    set(new_type):
        type = new_type
        match new_type:
            PreviewTileType.TEAM_CIRCLE, PreviewTileType.SELECTED_CIRCLE:
                $Sprite.animation = 'circle'
            PreviewTileType.ARROW, PreviewTileType.FADED_ARROW:
                $Sprite.animation = 'arrow'
        update_color()

@export var direction: TileSet.CellNeighbor:
    set(new_direction):
        direction = new_direction
        match new_direction:
            TileSet.CELL_NEIGHBOR_TOP_SIDE:
                $Sprite.rotation_degrees = 0
            TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE:
                $Sprite.rotation_degrees = 60
            TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE:
                $Sprite.rotation_degrees = 120
            TileSet.CELL_NEIGHBOR_BOTTOM_SIDE:
                $Sprite.rotation_degrees = 180
            TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE:
                $Sprite.rotation_degrees = 240
            TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE:
                $Sprite.rotation_degrees = 300

@export var success_chance: float:
    set(new_success_chance):
        success_chance = new_success_chance
        $SuccessChanceLabel.visible = true
        BB.set_centered_outlined_text($SuccessChanceLabel, '%s%%' % roundi(success_chance * 100), Constants.success_chance_color(success_chance))

func update_color():
    if type == PreviewTileType.SELECTED_CIRCLE:
        $Sprite.modulate = Color.WHITE
        return
    var color := Constants.team_color(team)
    if type == PreviewTileType.FADED_ARROW:
        color.a = 0.4
    $Sprite.modulate = color

func _on_mouse_entered():
    if type == PreviewTileType.ARROW or type == PreviewTileType.TEAM_CIRCLE:
        $Sprite.modulate = Color.WHITE

func _on_mouse_exited():
    if type == PreviewTileType.ARROW or type == PreviewTileType.TEAM_CIRCLE:
        $Sprite.modulate = Constants.team_color(team)

func _on_mouse_over_area_input_event(viewport: Node, event: InputEvent, _shape_idx: int) -> void:
    if event is InputEventMouseButton:
        if not event.pressed or not event.button_index == MOUSE_BUTTON_RIGHT:
            return
        right_clicked.emit()
        viewport.set_input_as_handled()
