class_name Inventory
extends RefCounted
## Fase 4 — Inventario básico (id -> cantidad). Vive en Player.
## Reutilizable por NPCs/cofres luego. Ampliable (capacidad, slots)
## sin rehacer la base. Emite changed en cada modificación.

signal changed

var _items: Dictionary = {}


## Agrega y devuelve el total resultante. Ignora ids/cantidades inválidas.
func add_item(item_id: String, amount: int = 1) -> int:
	if item_id.is_empty() or amount <= 0:
		return count(item_id)
	if ItemDatabase.get_item(item_id).is_empty():
		push_error("Inventory: ítem desconocido '%s'." % item_id)
		return 0
	_items[item_id] = int(_items.get(item_id, 0)) + amount
	changed.emit()
	return int(_items[item_id])


func has_item(item_id: String, amount: int = 1) -> bool:
	return count(item_id) >= amount


func count(item_id: String) -> int:
	return int(_items.get(item_id, 0))


func get_all() -> Dictionary:
	return _items.duplicate()
