extends Node
## Guardado automático único (Autoload `SaveGame`): inventario, monedas y
## escena/posición del jugador en user://savegame.json (FileAccess+JSON,
## sin permisos extra en Android). Sin slots ni UI manual todavía.

const PATH := "user://savegame.json"
const AUTOSAVE_INTERVAL := 30.0

var _timer := 0.0


func _ready() -> void:
	_timer = AUTOSAVE_INTERVAL


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = AUTOSAVE_INTERVAL
		var p: Node2D = get_tree().get_first_node_in_group("player")
		if p != null:
			var w: Node = p.get_parent()
			if w != null and str(w.scene_file_path) != "":
				save_game(p, str(w.scene_file_path))


## Foto serializable del estado esencial (dict JSON-safe).
## Fase 7: suma friendship {npc_id: nivel} (saves viejos la omiten).
static func capture(player: Node2D, world_path: String) -> Dictionary:
	var friendship := {}
	var tree := player.get_tree()
	if tree != null:
		for n in tree.get_nodes_in_group("npc"):
			var id := String(n.get("npc_id"))
			if not id.is_empty():
				friendship[id] = int(n.get("friendship"))
	return {
		"coins": int(player.get("coins")),
		"inventory": player.get("inventory").call("get_all"),
		"scene": world_path,
		"pos": [float(player.position.x), float(player.position.y)],
		"friendship": friendship,
		"player_name": String(player.get("player_name")),
	}


## Aplica una foto sobre el jugador actual (tolera fichas parciales,
## incluidos saves viejos sin "friendship": amistad queda en 0).
static func apply_to(player: Node2D, data: Dictionary) -> void:
	if data.is_empty():
		return
	if data.has("pos"):
		var pos: Array = data["pos"]
		player.position = Vector2(float(pos[0]), float(pos[1]))
	if data.has("coins"):
		player.set("coins", int(data["coins"]))
	if data.has("player_name"):
		player.set("player_name", String(data["player_name"]))
	if data.has("inventory"):
		var inv: Inventory = player.get("inventory")
		for k in (data["inventory"] as Dictionary).keys():
			inv.add_item(String(k), int((data["inventory"] as Dictionary)[k]))
	if data.has("friendship"):
		var tree := player.get_tree()
		if tree != null:
			for n in tree.get_nodes_in_group("npc"):
				var id := String(n.get("npc_id"))
				if (data["friendship"] as Dictionary).has(id):
					n.set("friendship", int((data["friendship"] as Dictionary)[id]))


static func save_game(player: Node2D, world_path: String) -> bool:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveGame: no se pudo escribir " + PATH)
		return false
	f.store_string(JSON.stringify(capture(player, world_path)))
	return true


## Dict vacío = primera vez (el llamador usa valores por defecto).
static func load_data() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveGame: formato inválido, se ignora.")
		return {}
	return parsed
