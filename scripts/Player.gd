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
## Nombre elegido en NameEntry (default para saves viejos).
var player_name := "Viajero"

@onready var sprite: Sprite2D = $Sprite2D
@onready var sensor: TerrainSensor = $TerrainSensor
@onready var steps: AudioStreamPlayer = $Steps

var _bob := 0.0
## Pasos: distancia acumulada; suena cada ~110px en movimiento.
var _step_acc := 0.0
const STEP_EVERY := 110.0


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
	_pasos(delta)


func _animar(dir: Vector2, delta: float) -> void:
	if absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x < 0.0
	# WalkAnim (si existe) hace los frames. El bob queda como respaldo.
	if sprite.get_node_or_null("WalkAnim") != null:
		return
	if dir.length() > 0.05:
		# Caminar procedural: no hay frames dedicados, solo idle como base.
		_bob += delta * 10.0
		sprite.position.y = sin(_bob) * 4.0
	else:
		sprite.position.y = lerpf(sprite.position.y, 0.0, minf(delta * 10.0, 1.0))


func _pasos(delta: float) -> void:
	if velocity.length() < 20.0:
		_step_acc = 0.0
		return
	_step_acc += velocity.length() * delta
	if _step_acc < STEP_EVERY:
		return
	_step_acc = 0.0
	steps.stream = FootstepSynth.stream_por_terreno(sensor.terrain_id)
	steps.pitch_scale = randf_range(0.92, 1.08)
	steps.play()
