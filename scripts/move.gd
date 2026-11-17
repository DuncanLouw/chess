class_name Move
extends RefCounted
## One possible move: the square a piece moves from, and the square it moves to.
## Special moves (castling, en passant, promotion) will add extra information here later.

var from: Vector2i
var to: Vector2i

# The change record, filled in by GameState.play_move() once the move is played.
# `changes` has one entry per square the move changed: a normal move gives two
# (the square it left and the square it landed on, with any captured piece as that
# square's "before"); castling, en passant or an atomic explosion give more.
# Undo and redo only use this record, so they never run the rules.
var changes: Array[SquareChange] = []
var turn_before := 0
var turn_after := 0


func _init(from_square: Vector2i, to_square: Vector2i) -> void:
	from = from_square
	to = to_square
