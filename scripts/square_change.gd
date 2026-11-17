class_name SquareChange
extends RefCounted
## What one move changed on one square: a copy of the piece there before the move
## and a copy of the piece there after it (null = empty).
## Copies, so later moves can't change the record.

var square: Vector2i
var before: PieceData    # null if the square was empty before the move
var after: PieceData     # null if the square is empty after the move


func _init(changed_square: Vector2i, piece_before: PieceData, piece_after: PieceData) -> void:
	square = changed_square
	before = piece_before
	after = piece_after
