class_name Board
extends Node2D

const SQUARE_SIZE := 100

@export var piece_scale := 0.9

@export var light_color := Color("#f0d9b5")
@export var dark_color := Color("#b58863")

func _draw() -> void:
	for col in 8:
		for row in 8:
			var color: Color = light_color if (col + row) % 2 == 0 else dark_color
			draw_rect(Rect2(col * SQUARE_SIZE, row * SQUARE_SIZE, SQUARE_SIZE, SQUARE_SIZE), color)

# Converts a square like (4, 7) into the pixel position of its centre
func square_to_position(col: int, row: int) -> Vector2:
	return Vector2(col + 0.5, row + 0.5) * SQUARE_SIZE
