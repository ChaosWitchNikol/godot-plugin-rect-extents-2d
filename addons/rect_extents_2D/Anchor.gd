extends Object

const COLOR : Color = Color("#fff")

var position : Vector2
var rect : Rect2


func _init(position : Vector2, size: Vector2) -> void:
	self.position = position
	self.rect = Rect2(position - size / 2.0, size)


func draw(overlay: Control, color: Color) ->  void:
	overlay.draw_circle(position, 12, color)
	overlay.draw_circle(position, 7, COLOR)