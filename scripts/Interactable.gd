class_name Interactable
extends Area2D
## Fase 1 — Objeto de prueba: registra al jugador al entrar/salir.
## Fase 4 — fuente opcional de ítems (gives_item_id). Vacío = solo mensaje.

@export var message := "¡Encontraste algo! 📦"
## Si tiene id de ítem válido, interact() lo entrega (repetible) y
## devuelve "Obtuviste: ...". Si no, devuelve message como siempre.
@export var gives_item_id := ""
## Fase 4 paso 2 — venta espejo: si tiene id, interact() vende 1 unidad
## al precio sell_price de items.json (nunca hardcodeado en código).
## takes vacío = comportamiento anterior intacto (caja/pozo/Mango).
@export var takes_item_id := ""


func _ready() -> void:
	add_to_group("interactuable")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.set("interact_target", self)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body.get("interact_target") == self:
		body.set("interact_target", null)


## Texto de interacción. El HUD lo llama con el jugador (duck-typing).
func interact(player: Node2D) -> String:
	if not takes_item_id.is_empty():
		return _sell_one(player)
	if gives_item_id.is_empty():
		return message
	var data := ItemDatabase.get_item(gives_item_id)
	if data.is_empty():
		return message
	var total: int = player.get("inventory").add_item(gives_item_id, 1)
	return "Obtuviste: %s (tienes %d)" % [String(data["name"]), total]


## Vende 1 unidad al sell_price de items.json. Sin stock = aviso, sin cambios.
func _sell_one(player: Node2D) -> String:
	var data := ItemDatabase.get_item(takes_item_id)
	if data.is_empty():
		return message
	var price := int(data.get("sell_price", 0))
	if price <= 0:
		return message
	var inv: Inventory = player.get("inventory")
	if not inv.has_item(takes_item_id, 1):
		return "No tienes %s para vender." % String(data["name"])
	inv.remove_item(takes_item_id, 1)
	player.set("coins", int(player.get("coins")) + price)
	return "Vendiste 1 %s por %d monedas. Total: %d" % [String(data["name"]), price, int(player.get("coins"))]
