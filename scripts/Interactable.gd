class_name Interactable
extends Area2D
## Fase 1 — Objeto de prueba: registra al jugador al entrar/salir.

@export var message := "¡Encontraste algo! 📦"


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
