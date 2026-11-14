extends Node2D

@export var variant: ChessVariant

var state := GameState.new()
var rules: Rules
var legal_moves: Array[Move] = []    # the selected piece's moves (empty when nothing is selected)

@onready var board: Board = $Board    # the Board node, fetched once the scene is ready


func _ready() -> void:
	if variant.rules == null:
		push_error("The variant '%s' has no Rules set, so the game won't start." % variant.display_name)
		return
	rules = variant.rules
	state.load_layout(variant)
	board.show_state(state, variant)
	board.square_clicked.connect(_on_board_square_clicked)    # run that function on every click


# Runs every time the Board reports a clicked or tapped square
func _on_board_square_clicked(square: Vector2i) -> void:
	# 1. One of the selected piece's moves goes to this square: play it
	for move in legal_moves:
		if move.to == square:
			rules.apply_move(state, move)
			_deselect()
			board.show_state(state, variant)
			return

	# 2. One of the current player's own pieces: select it and show its moves
	var piece: PieceData = state.squares.get(square)    # null if empty or off the board
	if piece != null and piece.side == state.turn:
		legal_moves = rules.get_legal_moves(state, square)
		board.show_moves(square, legal_moves)
		return

	# 3. Anything else: deselect
	_deselect()


func _deselect() -> void:
	legal_moves = []
	board.clear_moves()
