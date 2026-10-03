class_name TerrainSensor
extends Area2D
## Terreno bajo los pies (0 pasto default, 1 camino, 2 piedra, 3 madera).
## Lee Area2Ds de zona (capa 4, metadata terrain_id/priority) y resuelve
## por prioridad (piedra sobre camino). Sin interferir (máscara 8).

signal terrain_changed(terrain_id: int)

var terrain_id := 0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 8
	monitoring = true
	area_entered.connect(_refresh)
	area_exited.connect(_refresh)


func _refresh(_area: Area2D = null) -> void:
	var best := 0
	var best_prio := -1
	for a in get_overlapping_areas():
		if not a.has_meta("terrain_id"):
			continue
		var prio := int(a.get_meta("terrain_priority", 0))
		if prio > best_prio:
			best_prio = prio
			best = int(a.get_meta("terrain_id"))
	if best != terrain_id:
		terrain_id = best
		terrain_changed.emit(terrain_id)
