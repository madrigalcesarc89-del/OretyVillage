extends CanvasLayer
## Fase 1 — HUD mínimo: joystick, botón de interacción y mensaje temporal.

@onready var joystick: TouchJoystick = $Joystick
@onready var interact_button: Button = $InteractButton
@onready var message_label: Label = $MessageLabel
@onready var place_button: Button = $PlaceButton
@onready var gift_button: Button = $GiftButton

var player: VillagePlayer = null
var _msg_tween: Tween = null


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as VillagePlayer
	if player == null:
		# Orden de _ready atípico (p. ej. HUD antes que Player): reintentar.
		call_deferred("_resolver_player_diferido")
	interact_button.visible = false
	interact_button.pressed.connect(_on_interact_pressed)
	place_button.visible = false
	place_button.pressed.connect(_on_place_pressed)
	gift_button.visible = false
	gift_button.pressed.connect(_on_gift_pressed)
	message_label.modulate.a = 0.0


func _resolver_player_diferido() -> void:
	player = get_tree().get_first_node_in_group("player") as VillagePlayer
	if player == null:
		push_warning("HUD: no se encontró nodo en grupo 'player'; joystick y botón inactivos.")


func _process(_delta: float) -> void:
	if player == null:
		return
	player.touch_vector = joystick.output
	interact_button.visible = player.interact_target != null
	_update_place_button()
	_update_gift_button()


## Fase 6 — botón Colocar: solo con silla + placer (casa) + sin arrastre.
## Sin tipado estático a propósito (duck-typing, igual que interact_target).
func _placer():
	return get_tree().get_first_node_in_group("furniture_placer")


func _update_place_button() -> void:
	var pl = _placer()
	if pl == null or pl.is_carrying():
		place_button.visible = false
		return
	place_button.visible = bool(player.get("inventory").call("has_item", "silla", 1))


func _on_place_pressed() -> void:
	var pl = _placer()
	if pl != null:
		pl.start_placing()


## Fase 7 — botón Regalar: visible cerca de Mango con regalable en mano.
func _mango_nearby():
	var t: Node2D = player.interact_target if player != null else null
	if t != null and t.has_method("give_gift"):
		return t
	return null


func _update_gift_button() -> void:
	var npc = _mango_nearby()
	if npc == null:
		gift_button.visible = false
		return
	gift_button.visible = _has_giftable()


func _has_giftable() -> bool:
	var inv: Inventory = player.get("inventory")
	for gid in ["pez_sol", "pez_luna", "pez_roca", "fibra", "piedra"]:
		if inv.has_item(gid, 1):
			return true
	return false


func _on_gift_pressed() -> void:
	var npc = _mango_nearby()
	if npc == null:
		return
	show_message(String(npc.call("give_gift", player)))


func show_message(text: String) -> void:
	message_label.text = text
	if _msg_tween and _msg_tween.is_valid():
		_msg_tween.kill()
	message_label.modulate.a = 1.0
	_msg_tween = create_tween()
	_msg_tween.tween_interval(2.0)
	_msg_tween.tween_property(message_label, "modulate:a", 0.0, 0.5)


func _on_interact_pressed() -> void:
	if player == null or player.interact_target == null:
		return
	var target: Node2D = player.interact_target
	# NPCs con diálogo secuencial; resto (caja/pozo) vía interact().
	if target.has_method("advance_dialogue"):
		var line: String = target.call("advance_dialogue")
		if line.is_empty():
			clear_message()
		else:
			show_message(line)
	elif target.has_method("interact"):
		show_message(String(target.call("interact", player)))


func clear_message() -> void:
	if _msg_tween and _msg_tween.is_valid():
		_msg_tween.kill()
	message_label.text = ""
	message_label.modulate.a = 0.0
