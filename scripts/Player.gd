class_name VillagePlayer
extends CharacterBody2D
## Fase 1 — Personaje controlable (Ciana, placeholder idle).
## Teclado (move_* del InputMap) + vector táctil del joystick (touch_vector).

@export var speed := 220.0

var touch_vector := Vector2.ZERO
var interact_target: Interactable = null
## Fase 4 — inventario propio del jugador (clase reutilizable).
var inventory: Inventory = null
## Fase 4 paso 2 — monedas de sesión (el guardado es fase posterior).
var coins: int = 0

@onready var sprite: Sprite2D = $Sprite2D

var _bob := 0.0


func _ready() -> void:
	inventory = Inventory.new()
	add_to_group("player")


func _physics_process(delta: float) -> void:
	var keys := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir := keys + touch_vector
	if dir.length() > 1.0:
		dir = dir.normalized()
	velocity = dir * speed
	move_and_slide()
	_animar(dir, delta)


func _animar(dir: Vector2, delta: float) -> void:
	if absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x < 0.0
	if dir.length() > 0.05:
		# Caminar procedural: no hay frames dedicados, solo idle como base.
		_bob += delta * 10.0
		sprite.position.y = sin(_bob) * 4.0
	else:
		sprite.position.y = lerpf(sprite.position.y, 0.0, minf(delta * 10.0, 1.0))
