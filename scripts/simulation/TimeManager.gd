extends Node
## Fase 2 — Reloj global del pueblo (Autoload `Time`).
## Cualquier zona/sistema futuro (NPCs, tiendas, pesca, clima) consulta
## esta API sin acoplarse a ninguna escena:
##   GameTime.get_progress()  -> 0.0-1.0 del ciclo (0.0 = 00:00)
##   GameTime.get_phase()     -> "madrugada" | "manana" | "tarde" | "noche"
##   GameTime.get_clock_string() -> "08:00"
## Señales: phase_changed(phase), time_tick(minutes).

signal phase_changed(new_phase: String)
signal time_tick(current_minutes: float)

## Minutos de juego por segundo real. 12.0 = día completo en 2 minutos.
@export var game_minutes_per_real_second := 12.0

const MINUTES_PER_DAY := 1440.0

var time_minutes := 480.0  # 08:00 de arranque.

var _phase := ""


func _ready() -> void:
	_phase = _calc_phase()
	# Estructura mínima para futuras zonas (playa, bosque, granja, ...):
	# cada una será una escena en scenes/world/ que lee este mismo Autoload.


func _process(delta: float) -> void:
	time_minutes = fmod(time_minutes + delta * game_minutes_per_real_second, MINUTES_PER_DAY)
	time_tick.emit(time_minutes)
	var p := _calc_phase()
	if p != _phase:
		_phase = p
		phase_changed.emit(p)


func get_progress() -> float:
	return time_minutes / MINUTES_PER_DAY


func get_phase() -> String:
	return _phase


func get_clock_string() -> String:
	var h := int(time_minutes / 60.0)
	var m := int(time_minutes) % 60
	return "%02d:%02d" % [h, m]


func _calc_phase() -> String:
	var h := time_minutes / 60.0
	if h >= 6.0 and h < 12.0:
		return "manana"
	if h >= 12.0 and h < 19.0:
		return "tarde"
	if h >= 19.0 or h < 0.0:
		return "noche"
	if h >= 0.0 and h < 6.0:
		return "madrugada"
	return "noche"
