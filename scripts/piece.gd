class_name Piece
extends Node2D

# Recolours the piece. The colours in the SVG decide what becomes what:
# white -> fill colour, black -> outline colour, grey -> a mix of the two.
func set_colors(fill: Color, outline: Color) -> void:
	for shape in find_children("*", "Polygon2D", true, false):
		shape.color = _mixed_color(shape, shape.color, fill, outline)
	for line in find_children("*", "Line2D", true, false):
		line.default_color = _mixed_color(line, line.default_color, fill, outline)


# Uses the shape's original brightness (1 = white, 0 = black) to mix the two colours.
# The original is remembered the first time, so recolouring a piece again still works.
func _mixed_color(node: Node, current: Color, fill: Color, outline: Color) -> Color:
	if not node.has_meta("original_brightness"):
		node.set_meta("original_brightness", current.v)    # .v = brightness, from 0 to 1
	var brightness: float = node.get_meta("original_brightness")
	return outline.lerp(fill, brightness)    # lerp = mix: 0 gives outline, 1 gives fill
