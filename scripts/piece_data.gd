class_name PieceData
extends RefCounted
## One piece in the game state. Pure data: no nodes, nothing on screen.
## copy(), copy_from() and equals() go through every variable automatically,
## so a variable added here later is copied and compared without changing them.

var id := -1              # unique number in this game, given by GameState.create_piece()
var type: String          # "king", "rook", ... (from the variant's piece_names)
var side: int             # index into variant.sides: 0 = white, 1 = black in standard chess
var has_moved := false    # needed later for castling and the pawn's double first move
var recently_moved := false    # needed later for en passant


# _init runs when you write PieceData.new(...), so a piece always starts with a type and side.
# During a game, make pieces with GameState.create_piece() instead, so they get an id.
func _init(piece_type: String, piece_side: int) -> void:
	type = piece_type
	side = piece_side


# A new PieceData with the same values (the same id too). Change records keep copies,
# because a later move changing this piece would otherwise change the old record as well.
func copy() -> PieceData:
	var new_piece := PieceData.new(type, side)
	new_piece.copy_from(self)
	return new_piece


# Sets every variable to the other piece's value. Undo uses this to put recorded
# values back into the original object, so the Board keeps the same node for it.
# (Every variable is a plain value now. If one ever holds an Array or Dictionary,
# it needs a .duplicate() here, or both pieces would share it.)
func copy_from(other: PieceData) -> void:
	for field in _field_names():
		set(field, other.get(field))


# True if the other piece has exactly the same values, id included
func equals(other: PieceData) -> bool:
	if other == null:
		return false
	for field in _field_names():
		if get(field) != other.get(field):
			return false
	return true


# The names of every variable declared in this script ("id", "type", "side", ...).
# Godot can list an object's properties; the ones a script declares with `var`
# are marked with PROPERTY_USAGE_SCRIPT_VARIABLE.
func _field_names() -> Array[String]:
	var names: Array[String] = []
	for property: Dictionary in get_property_list():
		if (property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0:
			names.append(property["name"])
	return names
