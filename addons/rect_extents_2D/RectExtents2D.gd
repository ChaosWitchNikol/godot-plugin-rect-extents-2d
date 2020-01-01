tool
extends Node2D



export(Color) var color : Color = Color("#fff") setget set_color
export(Vector2) var size : Vector2 = Vector2(10, 10) setget set_size
export(Vector2) var offset : Vector2 = Vector2() setget set_offset


var _rect : Rect2

#== node ==
func _draw() -> void:
	if not Engine.editor_hint:
		return
	draw_rect(_rect, color, false)
	


#== functions ==
func _recalculate_rect() -> void:
	_rect = Rect2(size / -2 + offset, size)



#== setters ==
func set_color(value : Color) -> void:
	color = value
	update()


func set_size(value : Vector2) -> void:
	size = value
	_recalculate_rect()
	update()


func set_offset(value : Vector2) -> void:
	offset = value
	_recalculate_rect()
	update()