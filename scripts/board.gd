class_name Board
extends Node2D

# Sent when a square is clicked or tapped. The Board only reports it;
# main.gd decides what happens.
signal square_clicked(square: Vector2i)

const SQUARE_SIZE := 100

@export var piece_scale := 0.9
@export var light_color := Color("#f0d9b5")
@export var dark_color := Color("#b58863")
@export var selected_color := Color(1.0, 0.85, 0.2, 0.5)    # the selected piece's square
@export var move_color := Color(0.0, 0.0, 0.0, 0.25)        # dots on squares it can move to
@export var capture_color := Color(0.8, 0.1, 0.1, 0.4)      # squares where it can capture

# Which node shows which piece. The key is the piece's PieceData: apply_move moves
# that same object around the board, so its node can simply follow it.
var piece_nodes: Dictionary[PieceData, Piece] = {}

# The state currently shown (used to tell captures apart from normal moves when drawing)
var shown_state: GameState

# What to highlight: the selected square and the selected piece's moves
var has_selection := false
var selected_square := Vector2i.ZERO
var shown_moves: Array[Move] = []


func _draw() -> void:
	# The squares
	for col in 8:
		for row in 8:
			var color: Color = light_color if (col + row) % 2 == 0 else dark_color
			draw_rect(Rect2(col * SQUARE_SIZE, row * SQUARE_SIZE, SQUARE_SIZE, SQUARE_SIZE), color)

	if not has_selection:
		return

	# The selected piece's square
	draw_rect(square_to_rect(selected_square), selected_color)

	# Where it can go: a dot on empty squares, a tinted square where it can capture.
	# Everything drawn in _draw() appears under the pieces, so the tint shows around the piece.
	for move in shown_moves:
		if shown_state.squares.get(move.to) != null:
			draw_rect(square_to_rect(move.to), capture_color)
		else:
			draw_circle(square_to_position(move.to), SQUARE_SIZE * 0.15, move_color)


# Clicks and taps. Godot sends a tap on a touch screen as a left mouse click,
# so this handles both.
func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton    # null if this isn't a mouse button event
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	# Converts the click position into this node's own coordinates, so it works
	# wherever the board is placed and however the window is scaled
	var local_click := make_input_local(click) as InputEventMouseButton
	square_clicked.emit(position_to_square(local_click.position))


# Converts a square like (4, 7) into the pixel position of its centre
func square_to_position(square: Vector2i) -> Vector2:
	return (Vector2(square) + Vector2(0.5, 0.5)) * SQUARE_SIZE


# The rectangle a square covers, for drawing
func square_to_rect(square: Vector2i) -> Rect2:
	return Rect2(Vector2(square) * SQUARE_SIZE, Vector2.ONE * SQUARE_SIZE)


# The reverse of square_to_position: which square a point on the board is in
func position_to_square(point: Vector2) -> Vector2i:
	return Vector2i((point / SQUARE_SIZE).floor())


# Highlights the selected square and where its piece can move
func show_moves(from: Vector2i, moves: Array[Move]) -> void:
	has_selection = true
	selected_square = from
	shown_moves = moves
	queue_redraw()    # asks Godot to run _draw() again


# Removes the selection and the move marks
func clear_moves() -> void:
	has_selection = false
	shown_moves = []
	queue_redraw()


# Rebuilds every piece node from scratch. Slow (~125 ms for a full board), so it's only
# for the start and the Refresh button. After a move, use update_pieces() instead.
func show_state(state: GameState, variant: ChessVariant) -> void:
	for node in piece_nodes.values():
		node.queue_free()    # deletes the node safely at the end of this frame
	piece_nodes.clear()
	update_pieces(state, variant)


# Makes the piece nodes match the state, changing only what's different: pieces that
# moved get their node moved, captured pieces lose their node, and only new pieces
# (like a promoted pawn) get a new node. It works for every kind of move without
# needing to know what happened.
func update_pieces(state: GameState, variant: ChessVariant) -> void:
	shown_state = state
	var on_board: Dictionary[PieceData, bool] = {}    # every piece still on the board

	for square: Vector2i in state.squares:
		var piece_data: PieceData = state.squares[square]
		if piece_data == null:
			continue
		on_board[piece_data] = true
		if piece_nodes.has(piece_data):
			piece_nodes[piece_data].position = square_to_position(square)    # moved, or stayed put
		else:
			add_piece(square, piece_data, variant)    # a new piece

	# Pieces that are no longer on the board were captured: delete their nodes.
	# (.keys() gives a copy, so erasing inside the loop is safe.)
	for piece_data: PieceData in piece_nodes.keys():
		if not on_board.has(piece_data):
			piece_nodes[piece_data].queue_free()
			piece_nodes.erase(piece_data)


# Creates the node for one piece and puts it on its square
func add_piece(square: Vector2i, piece_data: PieceData, variant: ChessVariant) -> void:
	var path := "res://scenes/pieces/%s.tscn" % piece_data.type
	if not ResourceLoader.exists(path):    # gives a clear error instead of a crash
		push_error("No scene for piece type '%s' (%s)" % [piece_data.type, path])
		return
	var piece: Piece = load(path).instantiate()

	var side: Side = variant.sides[piece_data.side]
	piece.set_colors(side.fill_color, side.outline_color)
	piece.position = square_to_position(square)
	piece.scale = Vector2.ONE * piece_scale
	$Pieces.add_child(piece)
	piece_nodes[piece_data] = piece
