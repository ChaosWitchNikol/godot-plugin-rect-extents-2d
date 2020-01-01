tool
extends EditorPlugin

enum Anchors {
	TOP_LEFT,
	TOP_RIGHT,
	BOT_LEFT,
	BOT_RIGHT,
}

# Workaround for
const RectExtents2D = preload("res://addons/rect_extents_2D/RectExtents2D.gd")
#class RectExtents2D extends "RectExtents2D.gd":
#	func _init():
#		.init()


var rect_extents : RectExtents2D
var anchors : Array
var dragged_anchor : Dictionary = {}
var rect_drag_start : Dictionary = {
	'size': Vector2(),
	'offset': Vector2()
}


const CIRCLE_RADIUS : float = 6.0
const STROKE_RADIUS : float = 2.0
const STROKE_COLOR = Color("#f50956")
const FILL_COLOR = Color("#ffffff")


#== node ==
func _enter_tree() -> void:
	add_custom_type("RectExtents2D", "Node2D", preload("RectExtents2D.gd"), null)

func _exit_tree() -> void:
	remove_custom_type("RectExtents2D")

#== plugin ==
func edit(object: Object) -> void:
	rect_extents = object

func make_visible(visible : bool) -> void:
	if not rect_extents:
		return
	
	if not visible:
		rect_extents = null
	
	update_overlays()


func handles(object : Object) -> bool:
	return object is RectExtents2D

func forward_canvas_draw_over_viewport(overlay: Control) -> void:
	if not rect_extents or not rect_extents.is_inside_tree():
		return
	
	var pos = rect_extents.position
	var offset = rect_extents.offset
	var half_size : Vector2 = rect_extents.size / 2.0
	var edit_anchors : Dictionary = {
		Anchors.TOP_LEFT: pos - half_size + offset,
		Anchors.TOP_RIGHT: pos + Vector2(half_size.x, half_size.y * -1.0) + offset,
		Anchors.BOT_LEFT: pos + Vector2(half_size.x * -1.0, half_size.y) + offset,
		Anchors.BOT_RIGHT: pos + half_size + offset
	}
	
	var transform_viewport := rect_extents.get_viewport_transform()
	var transform_global := rect_extents.get_canvas_transform()
	
	anchors = []
	
	var anchor_size : Vector2 = Vector2.ONE * CIRCLE_RADIUS * 2.0
	for coord in edit_anchors.values():
		var anchor_center : Vector2 = transform_viewport * (transform_global * coord)
		var new_anchor : Dictionary = {
			'position': anchor_center,
			'rect': Rect2(anchor_center - anchor_size / 2.0, anchor_size)
		}
		
		draw_anchor(new_anchor, overlay)
		anchors.append(new_anchor)

func draw_anchor(anchor: Dictionary, overlay: Control) -> void:
	var pos = anchor['position']
	overlay.draw_circle(pos, CIRCLE_RADIUS + STROKE_RADIUS, STROKE_COLOR)
	overlay.draw_circle(pos, CIRCLE_RADIUS, FILL_COLOR)


func drag_to(event_position: Vector2) -> void:
	if not dragged_anchor:
		return
	# Calculate the position of the mouse cursor relative to the RectExtents' center
	var viewport_transform_inv := rect_extents.get_viewport().get_global_canvas_transform().affine_inverse()
	var viewport_position: Vector2 = viewport_transform_inv.xform(event_position)
	var transform_inv := rect_extents.get_global_transform().affine_inverse()
	var target_position : Vector2 = transform_inv.xform(viewport_position.round())
	# Update the rectangle's size. Only resizes uniformly around the center for now
	var target_size = (target_position - rect_extents.offset).abs() * 2.0
	rect_extents.size = target_size

func forward_canvas_gui_input(event: InputEvent) -> bool:
	if not rect_extents or not rect_extents.visible:
		return false

	# Clicking and releasing the click
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if not dragged_anchor and event.is_pressed():
			for anchor in anchors:
				if not anchor['rect'].has_point(event.position):
					continue
				dragged_anchor = anchor
				print("Drag start: %s" % dragged_anchor)
				rect_drag_start = {
					'size': rect_extents.size,
					'offset': rect_extents.offset,
				}
				return true
		elif dragged_anchor and not event.is_pressed():
			drag_to(event.position)
			dragged_anchor = {}
			var undo := get_undo_redo()
			undo.create_action("Move anchor")
		
			undo.add_do_property(rect_extents, "size", rect_extents.size)
			undo.add_undo_property(rect_extents, "size", rect_drag_start['size'])
		
			undo.add_do_property(rect_extents, "offset", rect_extents.offset)
			undo.add_undo_property(rect_extents, "offset", rect_drag_start['offset'])
		
			undo.commit_action()
			return true
	if not dragged_anchor:
		return false
	# Dragging
	if event is InputEventMouseMotion:
		drag_to(event.position)
		update_overlays()
		return true
	# Cancelling with ui_cancel
	if event.is_action_pressed("ui_cancel"):
		dragged_anchor = {}
		
		return true
	return false