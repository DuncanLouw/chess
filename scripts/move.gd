class_name Move
extends RefCounted
## One possible move: the square a piece moves from, and the square it moves to.
## Special moves (castling, en passant, promotion) will add extra information here later.

var from: Vector2i
var to: Vector2i


func _init(from_square: Vector2i, to_square: Vector2i) -> void:
	from = from_square
	to = to_square
