class_name Rules
extends Resource
## Standard chess. A variant with different rules extends this script and
## overrides only the functions that are different.
## Rules never store the game: every function gets the GameState to look at.

# Vector2i.UP is (0, -1), because y goes down the screen
const STRAIGHT = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const DIAGONAL = [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
const ALL_DIRECTIONS = STRAIGHT + DIAGONAL
const KNIGHT_JUMPS = [Vector2i(1,2), Vector2i(1,-2), Vector2i(-1,2), Vector2i(-1,-2), Vector2i(2,1), Vector2i(2,-1), Vector2i(-2,1), Vector2i(-2,-1)]
const PAWN_MOVES = [Vector2i.UP]
const PAWN_CAPTURE = [Vector2i(1,1), Vector2i(-1,1)]

# Where the piece on `from` could move, ignoring check (check comes in a later step)
func get_piece_moves(state: GameState, from: Vector2i) -> Array[Move]:
	var moves: Array[Move] = []
	var piece: PieceData = state.squares.get(from)
	if piece == null:
		return moves
	match piece.type:
		PieceNames.ROOK:
			moves = _slide_moves(state, from, STRAIGHT, true)
		PieceNames.BISHOP:
			moves = _slide_moves(state, from, DIAGONAL, true)
		PieceNames.QUEEN:
			moves = _slide_moves(state, from, ALL_DIRECTIONS, true)
		PieceNames.KING:
			moves = _step_moves(state, from, ALL_DIRECTIONS, true)
		PieceNames.KNIGHT:
			moves = _step_moves(state, from, KNIGHT_JUMPS, true)
		PieceNames.PAWN:
			moves = _step_moves(state, from, PAWN_CAPTURE, true)
			var max_steps := 1 if piece.has_moved else 2
			moves.append_array(_numbered_moves_can_capture(state, from, PAWN_MOVES, false, max_steps))
	return moves


# The moves the player may actually make. For now that's every piece move;
# the check step will remove moves that leave your own king attacked.
func get_legal_moves(state: GameState, from: Vector2i) -> Array[Move]:
	return get_piece_moves(state, from)


# Plays a move by changing the state. A piece on the target square is
# captured simply by being replaced.
func apply_move(state: GameState, move: Move) -> void:
	var piece: PieceData = state.squares[move.from]
	state.squares[move.to] = piece
	state.squares[move.from] = null
	piece.has_moved = true
	state.turn = get_next_side(state)
	state.history.append(move)


# Whose turn is next: the next side in the list, then back to the first
func get_next_side(state: GameState) -> int:
	return (state.turn + 1) % state.side_count


# Rook, bishop, queen: keep going in each direction until the edge of the board
# or a piece. An enemy piece can be captured; any piece stops the slide.
func _slide_moves(state: GameState, from: Vector2i, directions: Array, can_capture: bool) -> Array[Move]:
	var moves: Array[Move] = []
	var piece: PieceData = state.squares[from]
	for direction: Vector2i in directions:
		var target := from + direction
		while state.squares.has(target):    # false once we're off the board
			var other: PieceData = state.squares[target]
			if other == null:
				moves.append(Move.new(from, target))
			else:
				if other.side != piece.side and can_capture:
					moves.append(Move.new(from, target))    # a capture
				break    # any piece blocks the rest of this direction
			target += direction
	return moves


# King (and soon the knight): one step or jump in each direction, if that
# square is on the board and not taken by your own piece
func _step_moves(state: GameState, from: Vector2i, steps: Array, can_capture: bool) -> Array[Move]:
	var moves: Array[Move] = []
	var piece: PieceData = state.squares[from]
	for step: Vector2i in steps:
		var target := from + step
		if not state.squares.has(target):
			continue    # off the board
		var other: PieceData = state.squares[target]
		if other == null or (other.side != piece.side and can_capture):
			moves.append(Move.new(from, target))
	return moves


# allows the pawn to move two and, for example knight to jump multiple times
# diffrent from slide it allows all moves again from the new spot
func _numbered_moves_can_capture(
	state: GameState,
	from: Vector2i,
	steps: Array,
	can_capture: bool,
	number_of_moves: int
) -> Array[Move]:
	var moves: Array[Move] = []
	var piece: PieceData = state.squares[from]
	for step: Vector2i in steps:
		var target := from + direction
		for i in number_of_moves:
			# either I make this part similar to _step_moves, or I split _step_moves into two functions and then have both call that function. Could also just use this one and input 1 as the step input for king and pawn capture
	return moves
