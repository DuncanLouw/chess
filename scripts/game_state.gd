class_name GameState
extends RefCounted
## The whole game as data. The rules read and change this; the Board only shows it.

# Every square on the board. The value is the PieceData on it, or null if it's empty.
# Squares that aren't part of the board ("xx" in a layout) are left out completely.
var squares: Dictionary[Vector2i, PieceData] = {}

# Whose turn it is, as an index into variant.sides (0 = the first side in the list)
var turn := 0

# How many sides take turns (2 in standard chess)
var side_count := 0


# Fills `squares` from the variant's layout text
func load_layout(variant: ChessVariant) -> void:
	squares.clear()
	side_count = variant.sides.size()
	var rows: Array = variant.layout.strip_edges().split("\n", false)
	for row_num in range(len(rows)):
		var codes: Array = rows[row_num].split(" ", false)
		for column_num in range(len(codes)):
			var piece_code: String = codes[column_num]
			add_one_piece_to_dictionary(variant, piece_code, Vector2i(column_num, row_num))


# Returns the index of the side with this letter in variant.sides, or -1 if there's none
func find_side_index(variant: ChessVariant, letter: String) -> int:
	return variant.sides.find_custom(func(element): return element.letter == letter)


func add_one_piece_to_dictionary(
	variant: ChessVariant, 
	piece_code: String, 
	square: Vector2i
) -> void:
	if piece_code == "..":
		squares[square] = null
		return
	elif piece_code == "xx":
		return
	
	var piece_name: String = variant.piece_names.get(piece_code[1], "")
	if piece_name == "":
		push_error("No piece with letter '%s'" % piece_code[1])
		return
	
	var side_index: int = find_side_index(variant, piece_code[0])
	if side_index == -1:
		push_error("No side with letter '%s'" % piece_code[0])
		return
	
	squares[square] = PieceData.new(piece_name, side_index)
