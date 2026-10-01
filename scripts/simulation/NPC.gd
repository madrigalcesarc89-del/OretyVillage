class_name NPC
extends Interactable
## Fase 3 — NPC dirigido por datos (npcs.json).
## Fuente de verdad = la ficha JSON (sprite, escala, posición de ANCLA).
## Paso 2: vagabundeo aleatorio con pausas dentro de un círculo.
## Paso 4: rutina día/noche (vaga de día, descansa de noche).
## Paso 5: diálogo secuencial data-driven (hereda el patrón Interactable:
## la raíz Area2D registra al NPC como interact_target, tipado seguro).
## Sin colisión sólida todavía (solo Area2D, el jugador lo atraviesa).
## TODO paso diálogo/rutinas: agregar StaticBody2D con colisión real para
## que el jugador no atraviese al NPC.
## TODO futuras zonas: rutina con desplazamientos (casa/tienda/...) usando
## start_walk_to(punto) + arrive() como ganchos, sin rehacer esta base.

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
## Paso 5: diálogo secuencial data-driven (sin ramificaciones).
var _name := ""
var _lines: Array = []
var _line_idx := 0
## Fase 7 — afinidad (persistida en SaveGame como friendship/{id}).
var friendship := 0
## Prioridad de regalo: peces primero (es un gato), luego el resto.
## La silla (mueble) queda excluida a propósito.
const GIFT_ORDER: Array = ["pez_sol", "pez_luna", "pez_roca", "fibra", "piedra"]
## Paso 4: descanso nocturno. Con GameTime por señal (event-driven).
var _resting := false

const REST_TINT := Color(0.72, 0.74, 0.88)
const WAKE_TINT := Color.WHITE


## Día = manana/tarde. Las rutinas futuras refinan por fase aquí.
func is_day() -> bool:
	var p := GameTime.get_phase()
	return p == "manana" or p == "tarde"


func _ready() -> void:
	super._ready()
	add_to_group("npc")
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
	_name = String(data.get("name", npc_id))
	_lines = data.get("dialogue", [])
	randomize()
	_pause_left = randf_range(pause_min, pause_max)
	GameTime.phase_changed.connect(_on_phase_changed)
	_apply_phase(GameTime.get_phase())
	# Proximidad heredada de Interactable: la raíz Area2D registra al NPC
	# como interact_target (ver super._ready()). Sin conexiones extra.


func _process(delta: float) -> void:
	if _walking:
		_step_walk(delta)
	else:
		_pause_left -= delta
		if _pause_left <= 0.0:
			start_walk()


## Elige destino y arranca. Las rutinas futuras pueden llamar aquí
## directamente o sustituir esta función sin tocar el resto del NPC.
## De noche no arranca: el walk en curso termina (sin corte) y descansa.
func start_walk() -> void:
	if _resting:
		return
	_target = pick_target()
	_walking = true


func _on_phase_changed(new_phase: String) -> void:
	_apply_phase(new_phase)


func _apply_phase(phase: String) -> void:
	var day := phase == "manana" or phase == "tarde"
	_resting = not day
	# Si cae la noche a mitad de WALK, _step_walk lo termina y arrive()
	# lo deja descansando: transición natural, sin congelamiento.
	sprite.modulate = WAKE_TINT if day else REST_TINT
	if day and not _walking:
		_pause_left = randf_range(pause_min, pause_max)


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


## Diálogo genérico: cada llamada devuelve "Nombre: línea" y avanza.
## Tras la última devuelve "" (el HUD limpia) y reinicia en la 1ª.
## Cualquier NPC con array "dialogue" en su ficha lo reutiliza tal cual.
## Soporta placeholder {player} (nombre del jugador, default "Viajero").
func advance_dialogue() -> String:
	if _lines.is_empty():
		return ""
	if _line_idx >= _lines.size():
		_line_idx = 0
		return ""
	var line := "%s: %s" % [_name, String(_lines[_line_idx]).replace("{player}", _player_name())]
	_line_idx += 1
	return line


func _player_name() -> String:
	var p: Node = get_tree().get_first_node_in_group("player")
	if p == null:
		return "Viajero"
	return String(p.get("player_name")) if String(p.get("player_name")) != "" else "Viajero"


## Al alejarse se resetea la secuencia (hereda el desregistro de Interactable).
func _on_body_exited(body: Node2D) -> void:
	super._on_body_exited(body)
	if body.is_in_group("player"):
		_line_idx = 0


## Regala un ítem (+1 amistad).
## item_id vacío = el primer regalable en stock (comportamiento anterior).
## Un id concreto lo usa el menú de regalos; si no es regalable, no gasta nada.
func give_gift(player: Node2D, item_id: String = "") -> String:
	var inv: Inventory = player.get("inventory")
	var order: Array = GIFT_ORDER
	if not item_id.is_empty():
		if not GIFT_ORDER.has(item_id):
			return "Eso no se puede regalar."
		order = [item_id]
	for gid in order:
		var id := String(gid)
		if inv.has_item(id, 1):
			inv.remove_item(id, 1)
			friendship += 1
			var data := ItemDatabase.get_item(id)
			return "¡Gracias por el regalo (%s)! %s parece feliz. (Amistad: %d)" % [String(data.get("name", id)), _name, friendship]
	if not item_id.is_empty():
		var named := ItemDatabase.get_item(item_id)
		var label := String(named.get("name", item_id)) if not named.is_empty() else item_id
		return "No tienes %s para regalar." % label
	return "No tienes nada para regalar."
