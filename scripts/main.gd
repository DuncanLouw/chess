extends Node2D

@export var variant: ChessVariant

var state := GameState.new()


func _ready() -> void:
	state.load_layout(variant)
	$Board.show_state(state, variant)
