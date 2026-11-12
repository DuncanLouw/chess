class_name GameState
extends RefCounted
## The whole game as data. The rules read and change this; the Board only shows it.

# Every square on the board. The value is the PieceData on it, or null if it's empty.
# Squares that aren't part of the board ("xx" in a layout) are left out completely.
var squares: Dictionary[Vector2i, PieceData] = {}

# Whose turn it is, as an index into variant.sides (0 = the first side in the list)
var turn := 0


# Fills `squares` from the variant's layout text
func load_layout(variant: ChessVariant) -> void:
	squares.clear()
	# YOUR TURN: see below


# Returns the index of the side with this letter in variant.sides, or -1 if there's none
func find_side_index(variant: ChessVariant, letter: String) -> int:
	# YOUR TURN: see below
	return -1


#func place_pieces() -> void: 
	#var rows: Array = variant.layout.strip_edges().split("\n", false)
	#for row_num in range(len(rows)):
		#var codes: Array = rows[row_num].split(" ", false)
		#for column_num in range(len(codes)):
			#var piece_code: String = codes[column_num]
			#place_one_piece(piece_code, column_num, row_num)
#
#
#func place_one_piece(piece_code: String, column_num: int, row_num: int) -> void:
	#if piece_code == "..":
		#$Board.place_piece_on_board(null)
		#return
	#elif piece_code == "xx":
		#return
	#
	#var piece_name: String = variant.piece_names[piece_code[1]]
	#if piece_name == null:
		#push_error("No piece with letter '%s'" % piece_code[1])
		#return
	#var piece: Piece = load("res://scenes/pieces/%s.tscn" % piece_name).instantiate()
	#
	#var side: Side = find_side(piece_code[0])
	#if side == null: # reduntant with the push error in find_side which should I keep?
		#push_error("No side with letter '%s'" % piece_code[0])
		#return
	#piece.set_colors(side.fill_color, side.outline_color)
	#
	#$Board.place_piece_on_board(piece)
#
#
#func find_side(letter) -> Side:
	#for side in variant.sides:
		#if letter == side.letter:
			#return side
	#push_error("No side with letter '%s'" % letter)
	#return null # Godot throws an error: Not all code paths return a value.
	#
