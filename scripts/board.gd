class_name Board
extends Node2D

const SQUARE_SIZE := 100

@export var piece_scale := 0.9
@export var light_color := Color("#f0d9b5")
@export var dark_color := Color("#b58863")

# Which piece node is drawn on which square. Only for the visuals:
# the game itself is tracked in GameState.
var piece_nodes: Dictionary[Vector2i, Piece] = {}


func _draw() -> void:
	for col in 8:
		for row in 8:
			var color: Color = light_color if (col + row) % 2 == 0 else dark_color
			draw_rect(Rect2(col * SQUARE_SIZE, row * SQUARE_SIZE, SQUARE_SIZE, SQUARE_SIZE), color)


# Converts a square like (4, 7) into the pixel position of its centre
func square_to_position(square: Vector2i) -> Vector2:
	return (Vector2(square) + Vector2(0.5, 0.5)) * SQUARE_SIZE


# Removes all piece nodes, then creates a node for every piece in the state
func show_state(state: GameState, variant: ChessVariant) -> void:
	for node in piece_nodes.values():
		node.queue_free()    # deletes the node safely at the end of this frame
	piece_nodes.clear()

	for square: Vector2i in state.squares:    # looping over a dictionary gives its keys
		var piece_data: PieceData = state.squares[square]
		if piece_data != null:
			add_piece(square, piece_data, variant)


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
	piece_nodes[square] = piece
