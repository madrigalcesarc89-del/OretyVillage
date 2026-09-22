class_name NPCDatabase
extends RefCounted
## Fase 3 — Catálogo centralizado de NPCs (lee data/content/npcs.json).
## Agregar un NPC = añadir una ficha al JSON. Sin tocar scripts.
## Campos obligatorios por ficha: id, name, sprite, position [x, y].

const PATH := "res://data/content/npcs.json"

static var _cache: Dictionary = {}


static func all() -> Array:
	_load_once()
	return _cache.values()


static func get_npc(npc_id: String) -> Dictionary:
	_load_once()
	if not _cache.has(npc_id):
		push_error("NPCDatabase: no existe NPC con id '%s'." % npc_id)
		return {}
	return _cache[npc_id]


static func _load_once() -> void:
	if not _cache.is_empty():
		return
	if not FileAccess.file_exists(PATH):
		push_error("NPCDatabase: falta " + PATH)
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or not (parsed as Dictionary).has("npcs"):
		push_error("NPCDatabase: formato inválido en " + PATH)
		return
	for entry in (parsed as Dictionary)["npcs"]:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var e: Dictionary = entry
		if not e.has("id") or not e.has("sprite") or not e.has("position"):
			push_error("NPCDatabase: ficha incompleta (id/sprite/position): %s" % str(e))
			continue
		if e.has("dialogue") and (typeof(e["dialogue"]) != TYPE_ARRAY or (e["dialogue"] as Array).is_empty()):
			push_error("NPCDatabase: 'dialogue' debe ser array no vacío: %s" % str(e.get("id")))
			continue
		_cache[String(e["id"])] = e
