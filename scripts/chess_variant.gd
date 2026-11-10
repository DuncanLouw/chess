class_name ChessVariant
extends Resource

@export var piece_names: Dictionary[String, String] = {
	"B": "bishop",
	"K": "king",
	"N": "knight",
	"P": "pawn",
	"Q": "queen",
	"R": "rook"
}

@export var display_name := "Standard chess"
@export var sides: Array[Side] = []        # turn order
@export_multiline var layout := ""         # the starting position, typed as text
