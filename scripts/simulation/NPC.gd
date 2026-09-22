class_name NPC
extends Node2D
## Fase 3 — NPC dirigido por datos (npcs.json).
## Fuente de verdad = la ficha JSON (sprite, escala, posición de ANCLA).
## Paso 2: vagabundeo aleatorio con pausas dentro de un círculo.
## Sin diálogo, sin rutinas, sin colisión todavía.
## TODO paso diálogo/rutinas: agregar StaticBody2D con colisión real para
## que el jugador no atraviese al NPC + activar Area2D Proximity.

## Puntos a evitar al elegir destino (caja, pozo): no "flotar encima".
const AVOID_POINTS: Array = [Vector2(700, 1500), Vector2(1500, 2300)]
const AVOID_MIN_DIST := 170.0
const PICK_TRIES := 8

@export var npc_id := ""
## Radio de vagabundeo alrededor del ancla (px). Default si el JSON no trae.
@export var wander_radius := 200.0
## Velocidad de paseo (px/s). Más lenta que el jugador (220) a propósito.
@export var wander_speed := 90.0
## Pausas aleatorias entre paseos (s).
@export var pause_min := 2.0
@export var pause_max := 5.0

@onready var sprite: Sprite2D = $Sprite2D

var _anchor := Vector2.ZERO
var _target := Vector2.ZERO
var _walking := false
var _pause_left := 0.0


func _ready() -> void:
	var data := NPCDatabase.get_npc(npc_id)
	if data.is_empty():
		return
	var tex: Texture2D = load(String(data["sprite"]))
	if tex == null:
		push_error("NPC '%s': no se pudo cargar sprite %s." % [npc_id, String(data["sprite"])])
		return
	sprite.texture = tex
	sprite.scale = Vector2.ONE * float(data.get("scale", 1.0))
	var pos: Array = data["position"]
	_anchor = Vector2(float(pos[0]), float(pos[1]))
	position = _anchor
	wander_radius = float(data.get("wander_radius", wander_radius))
	randomize()
	_pause_left = randf_range(pause_min, pause_max)


func _process(delta: float) -> void:
	if _walking:
		_step_walk(delta)
	else:
		_pause_left -= delta
		if _pause_left <= 0.0:
			start_walk()


## Elige destino y arranca. Las rutinas futuras pueden llamar aquí
## directamente o sustituir esta función sin tocar el resto del NPC.
func start_walk() -> void:
	_target = pick_target()
	_walking = true


func pick_target() -> Vector2:
	var fallback := _anchor
	for i in PICK_TRIES:
		var a := randf() * TAU
		var r := sqrt(randf()) * wander_radius
		var p := _anchor + Vector2(cos(a), sin(a)) * r
		var ok := true
		for avoid in AVOID_POINTS:
			if p.distance_to(avoid) < AVOID_MIN_DIST:
				ok = false
				break
		if ok:
			return p
		if i == 0:
			fallback = p
	return fallback


func _step_walk(delta: float) -> void:
	var to: Vector2 = _target - position
	var dist := to.length()
	var step := wander_speed * delta
	if dist <= maxf(step, 2.0):
		position = _target
		arrive()
		return
	var dir := to / dist
	position += dir * step
	if absf(dir.x) > 0.05:
		sprite.flip_h = dir.x < 0.0


## Punto único de llegada. Las rutinas futuras enganchan aquí.
func arrive() -> void:
	_walking = false
	_pause_left = randf_range(pause_min, pause_max)
