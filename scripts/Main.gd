extends Node2D
## Fase 6 — Gestor de mundos (grupo world_manager).
## goto_world() recrea el mundo destino y TRANSFIERE inventario/monedas
## del Player viejo al nuevo (los nodos no persisten; los datos sí).
## Sin guardado entre sesiones todavía: NPCs/rutinas se reinician.


func _ready() -> void:
	add_to_group("world_manager")


func goto_world(path: String, spawn: Vector2) -> void:
	var old: Node = get_node_or_null("World")
	var inv_data := {}
	var coins := 0
	if old != null:
		var p: Node = old.get_node_or_null("Player")
		if p != null:
			inv_data = p.get("inventory").call("get_all")
			coins = int(p.get("coins"))
		remove_child(old)
		old.queue_free()
	var packed: PackedScene = load(path)
	if packed == null or not packed.can_instantiate():
		push_error("Main: escena inválida '%s'." % path)
		return
	var world: Node = packed.instantiate()
	world.name = "World"
	add_child(world)
	var np: Node = world.get_node_or_null("Player")
	if np != null:
		np.position = spawn
		var inv: Inventory = np.get("inventory")
		for k in inv_data.keys():
			inv.add_item(String(k), int(inv_data[k]))
		np.set("coins", coins)
