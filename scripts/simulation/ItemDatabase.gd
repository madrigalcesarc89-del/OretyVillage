class_name ItemDatabase
extends RefCounted
## Fase 4 — Catálogo centralizado de ítems (lee data/content/items.json).
## Mismo patrón que NPCDatabase: JSON editable, caché, validación.
## Campos obligatorios por ficha: id, name, category.

const PATH := "res://data/content/items.json"

static var _cache: Dictionary = {}


static func all() -> Array:
	_load_once()
	return _cache.values()


static func get_item(item_id: String) -> Dictionary:
	_load_once()
	if not _cache.has(item_id):
		push_error("ItemDatabase: no existe ítem con id '%s'." % item_id)
		return {}
	return _cache[item_id]


static func _load_once() -> void:
	if not _cache.is_empty():
		return
	if not FileAccess.file_exists(PATH):
		push_error("ItemDatabase: falta " + PATH)
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or not (parsed as Dictionary).has("items"):
		push_error("ItemDatabase: formato inválido en " + PATH)
		return
	for entry in (parsed as Dictionary)["items"]:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var e: Dictionary = entry
		if not e.has("id") or not e.has("name") or not e.has("category"):
			push_error("ItemDatabase: ficha incompleta (id/name/category): %s" % str(e))
			continue
		if e.has("sell_price") and (typeof(e["sell_price"]) != TYPE_INT and typeof(e["sell_price"]) != TYPE_FLOAT or int(e["sell_price"]) < 0):
			push_error("ItemDatabase: 'sell_price' inválido (>=0): %s" % str(e.get("id")))
			continue
		_cache[String(e["id"])] = e
