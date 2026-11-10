extends Node2D

@export var variant: ChessVariant


func _ready(): # Called when the node enters the scene tree for the first time.
	#Board.position
	place_pieces()


func place_pieces() -> void: 
	var rows: Array = variant.layout.strip_edges().split("\n", false)
	for row_num in range(len(rows)):
		var codes: Array = rows[row_num].split(" ", false)
		for column_num in range(len(codes)):
			var piece_code: String = codes[column_num]
			place_one_piece(piece_code, column_num, row_num)


func place_one_piece(piece_code: String, column_num: int, row_num: int) -> void:
	if piece_code == ".." or piece_code == "xx":
		return
	
	var piece_name: String = variant.piece_names[piece_code[1]]
	if piece_name == null:
		push_error("No piece with letter '%s'" % piece_code[1])
		return
	var piece: Piece = load("res://scenes/pieces/%s.tscn" % piece_name).instantiate()
	
	var side: Side = find_side(piece_code[0])
	if side == null: # reduntant with the push error in find_side which should I keep?
		push_error("No side with letter '%s'" % piece_code[0])
		return
	piece.set_colors(side.fill_color, side.outline_color)
	
	piece.position = $Board.square_to_position(column_num, row_num)
	piece.scale = Vector2.ONE * $Board.piece_scale
	$Board/Pieces.add_child(piece)


func find_side(letter) -> Side:
	for side in variant.sides:
		if letter == side.letter:
			return side
	push_error("No side with letter '%s'" % letter)
	return null # Godot throws an error: Not all code paths return a value.
	
