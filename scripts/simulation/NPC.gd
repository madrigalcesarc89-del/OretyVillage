class_name NPC
extends Node2D
## Fase 3 (paso 1) — NPC estático dirigido por datos (npcs.json).
## Fuente de verdad = la ficha JSON (sprite, escala, posición).
## Sin movimiento, sin diálogo, sin rutinas todavía.
## TODO paso diálogo/rutinas: agregar StaticBody2D con colisión real para
## que el jugador no atraviese al NPC + activar Area2D Proximity.

@export var npc_id := ""

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	var data := NPCDatabase.get_npc(npc_id)
	if data.is_empty():
		return
	var tex: Texture2D = load(String(data["sprite"]))
	if tex == null:
		push_error("NPC '%s': no se pudo cargar sprite %s." % [npc_id, String(data["sprite"])])
		return
	sprite.texture = tex
	sprite.scale = Vector2.ONE * float(data.get("scale", 1.0))
	var pos: Array = data["position"]
	position = Vector2(float(pos[0]), float(pos[1]))
