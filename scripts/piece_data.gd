class_name PieceData
extends RefCounted
## One piece in the game state. Pure data: no nodes, nothing on screen.

var type: String          # "king", "rook", ... (from the variant's piece_names)
var side: int             # index into variant.sides: 0 = white, 1 = black in standard chess
var has_moved := false    # needed later for castling and the pawn's double first move
var recently_moved := false    # needed later for en passant


# _init runs when you write PieceData.new(...), so a piece always starts with a type and side
func _init(piece_type: String, piece_side: int) -> void:
	type = piece_type
	side = piece_side
