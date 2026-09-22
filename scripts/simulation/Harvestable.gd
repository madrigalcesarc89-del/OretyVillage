class_name Harvestable
extends Interactable
## Fase 5 — Recurso recolectable genérico (pesca/insectos/agricultura
## futuros heredan este patrón). Suma a Interactable un ciclo de estado
## disponible/agotado con reaparición medida en GameTime (minutos de
## juego, nunca tiempo real del sistema). Aritmética modular: seguro
## aunque el respawn cruce la medianoche.

@export var depleted_message := "Agotado, vuelve más tarde."
## Minutos DE JUEGO hasta reaparecer (12/minuto real en testing).
@export var respawn_minutes_game := 360.0

const DEPLETED_TINT := Color(0.5, 0.5, 0.5)
const READY_TINT := Color.WHITE

var is_available := true
var _depleted_at := 0.0


func _ready() -> void:
	super._ready()
	GameTime.time_tick.connect(_on_time_tick)


## Agotado = aviso sin entregar. Si entrega (vía super), se agota.
func interact(player: Node2D) -> String:
	if not is_available:
		return depleted_message
	if gives_item_id.is_empty() or ItemDatabase.get_item(gives_item_id).is_empty():
		return message
	var line: String = super.interact(player)
	_deplete()
	return line


func _deplete() -> void:
	is_available = false
	_depleted_at = GameTime.time_minutes
	modulate = DEPLETED_TINT


func _restore() -> void:
	is_available = true
	modulate = READY_TINT


func _on_time_tick(now: float) -> void:
	if is_available:
		return
	var elapsed: float = fmod(now - _depleted_at + GameTime.MINUTES_PER_DAY, GameTime.MINUTES_PER_DAY)
	if elapsed >= respawn_minutes_game:
		_restore()
