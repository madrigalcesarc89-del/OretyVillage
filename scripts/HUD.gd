extends CanvasLayer
## Fase 1 — HUD mínimo: joystick, botón de interacción y mensaje temporal.

@onready var joystick: TouchJoystick = $Joystick
@onready var interact_button: Button = $InteractButton
@onready var message_label: Label = $MessageLabel

var player: VillagePlayer = null
var _msg_tween: Tween = null


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as VillagePlayer
	if player == null:
		# Orden de _ready atípico (p. ej. HUD antes que Player): reintentar.
		call_deferred("_resolver_player_diferido")
	interact_button.visible = false
	interact_button.pressed.connect(_on_interact_pressed)
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


func show_message(text: String) -> void:
	message_label.text = text
	if _msg_tween and _msg_tween.is_valid():
		_msg_tween.kill()
	message_label.modulate.a = 1.0
	_msg_tween = create_tween()
	_msg_tween.tween_interval(2.0)
	_msg_tween.tween_property(message_label, "modulate:a", 0.0, 0.5)


func _on_interact_pressed() -> void:
	if player != null and player.interact_target != null:
		show_message(player.interact_target.message)
