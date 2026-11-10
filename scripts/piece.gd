class_name Piece
extends Node2D

# Fills (Polygon2D) get the fill colour, outlines (Line2D) get the outline colour
func set_colors(fill: Color, outline: Color) -> void:
	for shape in find_children("*", "Polygon2D", true, false):
		shape.color = fill
	for line in find_children("*", "Line2D", true, false):
		line.default_color = outline
