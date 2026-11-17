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

# Every piece made in this game, by id, including captured ones, so undo and redo
# can find the original object again. Pieces are only made with create_piece().
var pieces_by_id: Dictionary[int, PieceData] = {}
var next_piece_id := 0

# Every move played so far, in order, each with its change record (see play_move).
# After undo, the undone moves stay in the list so redo can play them again:
# history_position is how many of them are currently played.
var history: Array[Move] = []
var history_position := 0


# A frozen copy of everything a move can change: every square (with copies of
# the pieces, not the pieces themselves) and whose turn it is.
# If GameState ever gets more things that moves change (not on a square, like
# castling rights), add them here, to Move's record, and to undo/redo.
class Snapshot:
	var squares: Dictionary[Vector2i, PieceData] = {}
	var turn := 0


# Fills `squares` from the variant's layout text, and starts a new game
func load_layout(variant: ChessVariant) -> void:
	squares.clear()
	turn = 0
	history.clear()
	history_position = 0
	pieces_by_id.clear()
	next_piece_id = 0
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

	squares[square] = create_piece(piece_name, side_index)


# Makes a new piece with the next free id. Every piece in a game is made with this,
# including ones the rules create (like a promoted queen), so undo can find it again.
func create_piece(piece_type: String, piece_side: int) -> PieceData:
	var piece := PieceData.new(piece_type, piece_side)
	piece.id = next_piece_id
	next_piece_id += 1
	pieces_by_id[piece.id] = piece
	return piece


# Plays a move and records what it changed. The rules decide what the move does;
# this only compares the state before and after, so it works for every rule.
func play_move(rules: Rules, move: Move) -> void:
	history.resize(history_position)    # a new move after undo drops the undone moves
	var before := take_snapshot()
	rules.apply_move(self, move)
	move.changes = _find_changes(before)
	move.turn_before = before.turn
	move.turn_after = turn
	history.append(move)
	history_position += 1


func take_snapshot() -> Snapshot:
	var snapshot := Snapshot.new()
	snapshot.turn = turn
	for square: Vector2i in squares:
		var piece: PieceData = squares[square]
		snapshot.squares[square] = piece.copy() if piece != null else null
	return snapshot


# Every square that's different from the snapshot: a different piece (or empty on one
# side), or the same piece with any value changed (like has_moved)
func _find_changes(before: Snapshot) -> Array[SquareChange]:
	var changes: Array[SquareChange] = []
	if before.squares.size() != squares.size():
		push_error("A move added or removed board squares. Change records don't support that yet.")
	for square: Vector2i in squares:
		var old_piece: PieceData = before.squares.get(square)    # already a copy
		var new_piece: PieceData = squares[square]
		if not _same(old_piece, new_piece):
			var new_copy: PieceData = new_piece.copy() if new_piece != null else null
			changes.append(SquareChange.new(square, old_piece, new_copy))
	return changes


# True if two squares hold the same thing: both empty, or equal pieces
func _same(a: PieceData, b: PieceData) -> bool:
	if a == null or b == null:
		return a == b    # true only if both are null
	return a.equals(b)


func can_undo() -> bool:
	return history_position > 0


func can_redo() -> bool:
	return history_position < history.size()


# Steps back one move by writing back what each changed square held before it.
# (Each square is in a move's record only once, so the order inside one move doesn't matter.)
func undo() -> void:
	if not can_undo():
		return
	history_position -= 1
	var move: Move = history[history_position]
	for change in move.changes:
		_put_piece(change.square, change.before)
	turn = move.turn_before


# Plays the next undone move again, from its record (the rules aren't run)
func redo() -> void:
	if not can_redo():
		return
	var move: Move = history[history_position]
	for change in move.changes:
		_put_piece(change.square, change.after)
	turn = move.turn_after
	history_position += 1


# Puts a recorded piece on a square. It uses the original PieceData object (found
# by id) with the recorded values written into it, never the copy itself, so the
# Board finds the node it already has for that piece.
func _put_piece(square: Vector2i, recorded: PieceData) -> void:
	if recorded == null:
		squares[square] = null
		return
	var piece: PieceData = pieces_by_id.get(recorded.id)
	if piece == null:
		push_error("No piece with id %d. Make new pieces with GameState.create_piece()." % recorded.id)
		return
	piece.copy_from(recorded)
	squares[square] = piece
