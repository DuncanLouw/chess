class_name ChessVariant
extends Resource

@export var rules: Rules                   # which rules this variant plays by

@export var piece_names: Dictionary[String, String] = {
	"B": Enum.PIECE_NAMES.BISHOP,
	"K": Enum.PIECE_NAMES.KING,
	"N": Enum.PIECE_NAMES.KNIGHT,
	"P": Enum.PIECE_NAMES.PAWN,
	"Q": Enum.PIECE_NAMES.QUEEN,
	"R": Enum.PIECE_NAMES.ROOK
}

@export var display_name := "Standard chess"
@export var sides: Array[Side] = []        # turn order
@export_multiline var layout := ""         # the starting position, typed as text
