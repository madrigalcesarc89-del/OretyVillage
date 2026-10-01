class_name TouchJoystick
extends Control
## Fase 1 — Joystick virtual de arrastre (táctil + ratón para editor).
## Expone `output` normalizado (-1..1) que HUD copia a Player.touch_vector.

const RADIUS := 90.0
const KNOB := 38.0

var output := Vector2.ZERO

var _touch_id := -1
var _mouse_down := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(340.0, 340.0)
	visible = true
	call_deferred("queue_redraw")


func cancel() -> void:
	_touch_id = -1
	_mouse_down = false
	output = Vector2.ZERO
	queue_redraw()


func _center() -> Vector2:
	return size * 0.5


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id == -1:
			_touch_id = event.index
			_update_output(event.position)
		elif not event.pressed and event.index == _touch_id:
			_touch_id = -1
			output = Vector2.ZERO
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_update_output(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse_down = event.pressed
		if _mouse_down:
			_update_output(event.position)
		else:
			output = Vector2.ZERO
			queue_redraw()
	elif event is InputEventMouseMotion and _mouse_down:
		_update_output(event.position)


func _update_output(pos: Vector2) -> void:
	var d := pos - _center()
	if d.length() > RADIUS:
		d = d.normalized() * RADIUS
	output = d / RADIUS
	queue_redraw()


func _draw() -> void:
	var c := _center()
	draw_circle(c, RADIUS + 12.0, Color(0.227, 0.165, 0.290, 0.40))
	draw_circle(c, RADIUS, Color(1.0, 0.965, 0.910, 0.28))
	draw_arc(c, RADIUS, 0, TAU, 48, Color(0.878, 0.478, 0.298, 0.95), 6.0)
	draw_circle(c + output * (RADIUS - KNOB), KNOB, Color(0.878, 0.478, 0.298, 0.88))
