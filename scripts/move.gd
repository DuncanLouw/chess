class_name Move
extends RefCounted
## One possible move: the square a piece moves from, and the square it moves to.
## Special moves (castling, en passant, promotion) will add extra information here later.

var from: Vector2i
var to: Vector2i

# include the one that got captured by being palced on so it can be undone when rewatching or undoing moves
# will be more than one in something like atomic chess
var deleted: Dictionary[Vector2i, PieceData] = {} 

# vetor4i I imagine as 2 Vector2i's for a from and a to as well as the piece's data that moved
var all_piece_moves: Dictionary[Vector4i, PieceData] = {}


func _init(from_square: Vector2i, to_square: Vector2i) -> void:
	from = from_square
	to = to_square
