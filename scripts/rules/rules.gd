class_name Rules
extends Resource
## Standard chess. A variant with different rules extends this script and
## overrides only the functions that are different.
## Rules never store the game: every function gets the GameState to look at.

# What a move pattern may do on a square with a piece on it
enum CaptureRule {
	MOVE_OR_CAPTURE,    # most pieces: empty squares and enemy pieces
	MOVE_ONLY,          # the pawn's forward move: empty squares only
	CAPTURE_ONLY,       # the pawn's diagonal: enemy pieces only
}

# For _slide_moves: no maximum distance, keep going until something stops it
const UNLIMITED := -1

# Vector2i.UP is (0, -1), because y goes down the screen
const STRAIGHT = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const DIAGONAL = [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
const ALL_DIRECTIONS = STRAIGHT + DIAGONAL
const KNIGHT_JUMPS = [Vector2i(1,2), Vector2i(1,-2), Vector2i(-1,2), Vector2i(-1,-2), Vector2i(2,1), Vector2i(2,-1), Vector2i(-2,1), Vector2i(-2,-1)]
# Pawns: only right for white so far (forward = up). Other sides need their own
# forward direction (Side.forward).
const PAWN_MOVES = [Vector2i.UP]
const PAWN_CAPTURE = [Vector2i(1,-1), Vector2i(-1,-1)]

# Where the piece on `from` could move, ignoring check (check comes in a later step)
func get_piece_moves(state: GameState, from: Vector2i) -> Array[Move]:
	var moves: Array[Move] = []
	var piece: PieceData = state.squares.get(from)
	if piece == null:
		return moves
	match piece.type:
		PieceNames.ROOK:
			moves = _slide_moves(state, from, STRAIGHT)
		PieceNames.BISHOP:
			moves = _slide_moves(state, from, DIAGONAL)
		PieceNames.QUEEN:
			moves = _slide_moves(state, from, ALL_DIRECTIONS)
		PieceNames.KING:
			moves = _step_moves(state, from, ALL_DIRECTIONS)
		PieceNames.KNIGHT:
			moves = _step_moves(state, from, KNIGHT_JUMPS)
		PieceNames.PAWN:
			var max_steps := 1 if piece.has_moved else 2    # two squares on its first move
			moves = _slide_moves(state, from, PAWN_MOVES, CaptureRule.MOVE_ONLY, max_steps)
			moves.append_array(_step_moves(state, from, PAWN_CAPTURE, CaptureRule.CAPTURE_ONLY))
	return moves


# The moves the player may actually make. For now that's every piece move;
# the check step will remove moves that leave your own king attacked.
func get_legal_moves(state: GameState, from: Vector2i) -> Array[Move]:
	return get_piece_moves(state, from)


# Plays a move by changing the state. A piece on the target square is
# captured simply by being replaced.
# Don't call this directly to play a move: GameState.play_move() calls it and records
# what changed, for undo. New pieces (like a promoted queen) must be made with
# state.create_piece(), so they get an id.
func apply_move(state: GameState, move: Move) -> void:
	var piece: PieceData = state.squares[move.from]
	state.squares[move.to] = piece
	state.squares[move.from] = null
	piece.has_moved = true
	state.turn = get_next_side(state)


# Whose turn is next: the next side in the list, then back to the first
func get_next_side(state: GameState) -> int:
	return (state.turn + 1) % state.side_count


# Rook, bishop, queen, and the pawn's forward move: keep going in each direction until
# the edge of the board, a piece, or max_distance. Any piece stops the slide;
# capture_rule says whether an enemy piece there can be captured.
func _slide_moves(
	state: GameState,
	from: Vector2i,
	directions: Array,
	capture_rule: CaptureRule = CaptureRule.MOVE_OR_CAPTURE,
	max_distance: int = UNLIMITED
) -> Array[Move]:
	var moves: Array[Move] = []
	var piece: PieceData = state.squares[from]
	for direction: Vector2i in directions:
		var target := from + direction
		var distance := 1
		while state.squares.has(target):    # false once we're off the board
			var other: PieceData = state.squares[target]
			if _can_land(piece, other, capture_rule):
				moves.append(Move.new(from, target))
			if other != null or distance == max_distance:
				break    # a piece blocks the rest of this direction, or it has gone far enough
			target += direction
			distance += 1
	return moves


# King, knight, and the pawn's diagonal capture: one step or jump in each direction,
# if that square is on the board and the piece may land there
func _step_moves(
	state: GameState,
	from: Vector2i,
	steps: Array,
	capture_rule: CaptureRule = CaptureRule.MOVE_OR_CAPTURE
) -> Array[Move]:
	var moves: Array[Move] = []
	var piece: PieceData = state.squares[from]
	for step: Vector2i in steps:
		var target := from + step
		if state.squares.has(target) and _can_land(piece, state.squares[target], capture_rule):
			moves.append(Move.new(from, target))
	return moves


# Whether `piece` may end its move on a square holding `other` (null = empty).
# Shared by every movement helper, so the capture rules live in one place.
func _can_land(piece: PieceData, other: PieceData, capture_rule: CaptureRule) -> bool:
	if other == null:
		return capture_rule != CaptureRule.CAPTURE_ONLY
	return other.side != piece.side and capture_rule != CaptureRule.MOVE_ONLY
