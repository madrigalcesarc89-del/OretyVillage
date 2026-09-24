class_name Interactable
extends Area2D
## Fase 1 — Objeto de prueba: registra al jugador al entrar/salir.
## Fase 4 — fuente opcional de ítems (gives_item_id). Vacío = solo mensaje.

@export var message := "¡Encontraste algo! 📦"
## Si tiene id de ítem válido, interact() lo entrega (repetible) y
## devuelve "Obtuviste: ...". Si no, devuelve message como siempre.
@export var gives_item_id := ""
## Fase 5 pesca — pool para entrega aleatoria uniforme (vacío = gives
## fijo; la caja no cambia). Verbo del mensaje ("¡Pescaste" en el pozo).
@export var gives_pool: PackedStringArray = []
@export var catch_text := "Obtuviste"
## Fase 4 paso 2 — venta espejo: si tiene id, interact() vende 1 unidad
## al precio sell_price de items.json (nunca hardcodeado en código).
## takes vacío = comportamiento anterior intacto (caja/pozo/Mango).
## Fase 4 paso 3 — compra espejo: sells_item_id ofrece 1 unidad al
## buy_price. Alternancia por contexto (mismo botón, sin UI nueva):
## con stock del takes → VENDE; sin stock → COMPRA si hay fondos.
@export var takes_item_id := ""
@export var sells_item_id := ""
## Fase 6 — pool de compra: se ofrece el PRIMERO asequible en orden
## (vacío = sells_item_id legado). Ordenar caro-primero para que lo
## caro sea alcanzable (ver Puesto). Futura tienda con UI lo supera.
@export var sells_pool: PackedStringArray = []
## Fase 5 pesca — el puesto vende el primero del pool en stock
## (vacío = takes_item_id legado, mensajes antiguos verbatim).
@export var takes_pool: PackedStringArray = []

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("interactuable")
	_rng.randomize()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## Candidatos de venta: pool si hay, si no el takes legado.
func _sell_candidates() -> Array:
	if not takes_pool.is_empty():
		return Array(takes_pool)
	if not takes_item_id.is_empty():
		return [takes_item_id]
	return []


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.set("interact_target", self)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body.get("interact_target") == self:
		body.set("interact_target", null)


## Texto de interacción. El HUD lo llama con el jugador (duck-typing).
func interact(player: Node2D) -> String:
	var sell_ids := _sell_candidates()
	if not sell_ids.is_empty():
		var inv: Inventory = player.get("inventory")
		for sid in sell_ids:
			if inv.has_item(String(sid), 1):
				return _sell_one(player, String(sid))
		var bid := _buy_id(player)
		if not bid.is_empty():
			return _buy_one(player, bid)
		if not sells_item_id.is_empty():
			return _buy_one(player, sells_item_id)
		if sell_ids.size() == 1:
			var only := String(sell_ids[0])
			return "No tienes %s para vender." % String(ItemDatabase.get_item(only).get("name", only))
		return "No tienes nada para vender."
	if not _give_id().is_empty():
		return _give_one(player)
	if gives_item_id.is_empty():
		return message
	var data := ItemDatabase.get_item(gives_item_id)
	if data.is_empty():
		return message
	var total: int = player.get("inventory").add_item(gives_item_id, 1)
	return "Obtuviste: %s (tienes %d)" % [String(data["name"]), total]


## Id a entregar: aleatorio uniforme del pool, o el gives fijo.
## Pool vacío = comportamiento anterior byte-idéntico (caja).
func _give_id() -> String:
	if gives_pool.is_empty():
		return gives_item_id
	var valid: Array = []
	for gid in gives_pool:
		if not ItemDatabase.get_item(String(gid)).is_empty():
			valid.append(String(gid))
	if valid.is_empty():
		return gives_item_id
	return valid[_rng.randi_range(0, valid.size() - 1)]


func _give_one(player: Node2D) -> String:
	var gid := _give_id()
	var data := ItemDatabase.get_item(gid)
	if data.is_empty():
		return message
	var total: int = player.get("inventory").add_item(gid, 1)
	return "%s: %s (tienes %d)" % [catch_text, String(data["name"]), total]


## Vende 1 unidad al sell_price de items.json. Sin stock = aviso, sin cambios.
func _sell_one(player: Node2D, item_id: String = "") -> String:
	var sid := item_id if not item_id.is_empty() else takes_item_id
	var data := ItemDatabase.get_item(sid)
	if data.is_empty():
		return message
	var price := int(data.get("sell_price", 0))
	if price <= 0:
		return message
	var inv: Inventory = player.get("inventory")
	if not inv.has_item(sid, 1):
		return "No tienes %s para vender." % String(data["name"])
	inv.remove_item(sid, 1)
	player.set("coins", int(player.get("coins")) + price)
	return "Vendiste 1 %s por %d monedas. Total: %d" % [String(data["name"]), price, int(player.get("coins"))]


## Compra 1 unidad al buy_price de items.json. Sin fondos = aviso, sin cambios.
func _buy_one(player: Node2D, item_id: String = "") -> String:
	var bid := item_id if not item_id.is_empty() else sells_item_id
	var data := ItemDatabase.get_item(bid)
	if data.is_empty():
		return message
	var price := int(data.get("buy_price", 0))
	if price <= 0:
		return message
	var coins: int = int(player.get("coins"))
	if coins < price:
		return "No tienes monedas suficientes (cuesta %d)." % price
	player.set("coins", coins - price)
	var inv: Inventory = player.get("inventory")
	var total: int = inv.add_item(bid, 1)
	return "Compraste 1 %s por %d monedas. Total: %d monedas, %d %s." % [String(data["name"]), price, int(player.get("coins")), total, String(data["name"])]


## Primera oferta asequible del sells_pool ("" si ninguna).
func _buy_id(player: Node2D) -> String:
	if sells_pool.is_empty():
		return ""
	var coins: int = int(player.get("coins"))
	for bid in sells_pool:
		var data := ItemDatabase.get_item(String(bid))
		if not data.is_empty() and coins >= int(data.get("buy_price", 0)) and int(data.get("buy_price", 0)) > 0:
			return String(bid)
	return ""
