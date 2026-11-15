class_name ChessVariant
extends Resource

@export var rules: Rules                   # which rules this variant plays by

@export var piece_names: Dictionary[String, String] = {
	"B": PieceNames.BISHOP,
	"K": PieceNames.KING,
	"N": PieceNames.KNIGHT,
	"P": PieceNames.PAWN,
	"Q": PieceNames.QUEEN,
	"R": PieceNames.ROOK
}

@export var display_name := "Standard chess"
@export var sides: Array[Side] = []        # turn order
@export_multiline var layout := ""         # the starting position, typed as text
