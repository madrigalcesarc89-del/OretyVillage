class_name Door
extends Interactable
## Fase 6 — Puerta entre mundos (mismo patrón proximidad + botón).
## interact() pide a Main (grupo world_manager) el cambio de escena
## con transferencia de inventario/monedas. Sin animación todavía.

@export var target_scene := ""
@export var spawn_pos := Vector2.ZERO
@export var go_message := "¡Vamos! 🚪"


func interact(player: Node2D) -> String:
	var mgr: Node = get_tree().get_first_node_in_group("world_manager")
	if mgr != null and not target_scene.is_empty():
		mgr.call("goto_world", target_scene, spawn_pos)
	return go_message
