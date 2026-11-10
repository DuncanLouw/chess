class_name Side
extends Resource

@export var letter := "w"                 # used in layouts: "wK" = this side's king
@export var forward := Vector2i(0, -1)    # the direction this side's pawns move
@export var fill_color := Color.WHITE
@export var outline_color := Color.BLACK
