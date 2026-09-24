class_name FurniturePlacer
extends Node2D
## Fase 6 — Colocación touch + drag dentro de la casa (solo existe en
## House.tscn). Sin rotación ni guardado todavía: al salir, lo colocado
## se pierde (fase Save/Load futura).

const FURNITURE_ID := "silla"
const GHOST_SIZE := Vector2(90, 70)
const BOUNDS := Rect2(45, 45, 630, 1190)

var carrying := false

var _ghost: ColorRect = null


func _ready() -> void:
	add_to_group("furniture_placer")


func can_place() -> bool:
	var p: Node2D = get_tree().get_first_node_in_group("player")
	return p != null and bool(p.get("inventory").call("has_item", FURNITURE_ID, 1))


func is_carrying() -> bool:
	return carrying


func start_placing() -> void:
	if carrying or not can_place():
		return
	carrying = true
	_ghost = ColorRect.new()
	_ghost.size = GHOST_SIZE
	_ghost.color = Color(0.55, 0.35, 0.17, 0.6)
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ghost)
	_move_ghost(get_viewport().get_mouse_position())


func _input(event: InputEvent) -> void:
	if not carrying:
		return
	if event is InputEventScreenTouch:
		if not event.pressed:
			_commit(_to_world(event.position))
	elif event is InputEventScreenDrag:
		_move_ghost(event.position)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_move_ghost(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_commit(_to_world(event.position))


func _to_world(screen_pos: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_pos


func _move_ghost(screen_pos: Vector2) -> void:
	if _ghost == null:
		return
	_ghost.position = _clamp_inside(_to_world(screen_pos)) - GHOST_SIZE * 0.5


func _clamp_inside(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, BOUNDS.position.x, BOUNDS.end.x), clampf(p.y, BOUNDS.position.y, BOUNDS.end.y))


func _commit(world_pos: Vector2) -> void:
	var p: Node2D = get_tree().get_first_node_in_group("player")
	if p != null and bool(p.get("inventory").call("remove_item", FURNITURE_ID, 1)):
		var placed := Node2D.new()
		placed.name = "SillaColocada"
		placed.position = _clamp_inside(world_pos)
		var rect := ColorRect.new()
		rect.size = GHOST_SIZE
		rect.position = -GHOST_SIZE * 0.5
		rect.color = Color(0.55, 0.35, 0.17, 1.0)
		placed.add_child(rect)
		get_parent().add_child(placed)
	carrying = false
	if _ghost != null:
		_ghost.queue_free()
		_ghost = null
