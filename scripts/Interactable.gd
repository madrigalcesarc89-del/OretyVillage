class_name Interactable
extends Area2D
## Fase 1 — Objeto de prueba: registra al jugador al entrar/salir.
## Fase 4 — fuente opcional de ítems (gives_item_id). Vacío = solo mensaje.

@export var message := "¡Encontraste algo! 📦"
## Si tiene id de ítem válido, interact() lo entrega (repetible) y
## devuelve "Obtuviste: ...". Si no, devuelve message como siempre.
@export var gives_item_id := ""


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
	if gives_item_id.is_empty():
		return message
	var data := ItemDatabase.get_item(gives_item_id)
	if data.is_empty():
		return message
	var total: int = player.get("inventory").add_item(gives_item_id, 1)
	return "Obtuviste: %s (tienes %d)" % [String(data["name"]), total]
