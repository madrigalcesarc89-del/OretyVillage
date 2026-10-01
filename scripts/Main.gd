extends Node2D
## Fase 6 — Gestor de mundos (grupo world_manager).
## goto_world() recrea el mundo destino y TRANSFIERE inventario/monedas
## del Player viejo al nuevo (los nodos no persisten; los datos sí).
## Sin guardado entre sesiones todavía: NPCs/rutinas se reinician.
## HOTFIX Android: los overrides de límites de Camera2D en .tscn NO
## llegan al APK (verificado por bytes: ausentes en el .scn exportado),
## así que los límites se aplican por CÓDIGO aquí (los .gd sí exportan
## frescos). No confiar en overrides de escena para la cámara.

## Límites por mundo (right, bottom; left/top siempre 0).
const WORLD_LIMITS := {
	"Plaza": [2160.0, 3840.0],
	"House": [720.0, 1280.0],
}


func _ready() -> void:
	add_to_group("world_manager")
	call_deferred("_apply_camera_limits")


func _world_key(world: Node) -> String:
	if world == null:
		return ""
	# El nodo instanciado se llama "World"; la escena origen da el nombre.
	var src := str(world.scene_file_path.get_file().get_basename())
	return src if WORLD_LIMITS.has(src) else ""


func _apply_camera_limits() -> void:
	var world: Node = get_node_or_null("World")
	var key := _world_key(world)
	if key.is_empty():
		return
	var cam: Camera2D = world.get_node_or_null("Player/Camera2D")
	if cam == null:
		return
	var lim: Array = WORLD_LIMITS[key]
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(lim[0])
	cam.limit_bottom = int(lim[1])


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
	_apply_camera_limits()
	var np: Node = world.get_node_or_null("Player")
	if np != null:
		np.position = spawn
		var inv: Inventory = np.get("inventory")
		for k in inv_data.keys():
			inv.add_item(String(k), int(inv_data[k]))
		np.set("coins", coins)
