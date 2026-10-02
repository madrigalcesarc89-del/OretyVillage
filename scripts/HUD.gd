extends CanvasLayer
## HUD táctil: joystick, interacción, pausa, diálogo, tienda y regalos.
## Los nodos Joystick, InteractButton, MessageLabel, PlaceButton y GiftButton
## siguen existiendo (el código de juego los busca por esos nombres).

@onready var joystick: TouchJoystick = $Joystick
@onready var interact_button: Button = $InteractButton
@onready var message_label: Label = $MessageLabel
@onready var place_button: Button = $PlaceButton
@onready var gift_button: Button = $GiftButton

var player: VillagePlayer = null
var _msg_tween: Tween = null
var _toast: PanelContainer

var _pause_root: Control
var _pause_name: Label
var _pause_coins: Label
var _status_name: Label
var _status_coins: Label

var _dialogue_root: PanelContainer
var _dialogue_portrait: TextureRect
var _dialogue_name: Label
var _dialogue_body: Label
var _dialogue_target: Node = null
var _dialogue_open := false

var _shop_root: Control
var _shop_coins: Label
var _shop_list: VBoxContainer
var _shop_confirm: VBoxContainer
var _shop_confirm_label: Label
var _shop_target: Node = null
var _shop_mode := "sell"
var _shop_pending: Dictionary = {}

var _gift_root: Control
var _gift_title: Label
var _gift_list: VBoxContainer
var _gift_confirm: VBoxContainer
var _gift_confirm_label: Label
var _gift_target: Node = null
var _gift_pending := ""
var _ui_theme: Theme


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ui_theme = OretyTheme.make()
	player = get_tree().get_first_node_in_group("player") as VillagePlayer
	if player == null:
		call_deferred("_resolver_player_diferido")
	interact_button.visible = false
	interact_button.pressed.connect(_on_interact_pressed)
	place_button.visible = false
	place_button.pressed.connect(_on_place_pressed)
	gift_button.visible = false
	gift_button.pressed.connect(_on_gift_pressed)
	_build_toast()
	_build_status()
	_build_pause()
	_build_dialogue()
	_build_shop()
	_build_gift()
	_style_action_buttons()
	for node in [interact_button, place_button, gift_button, message_label]:
		node.theme = _ui_theme


func _resolver_player_diferido() -> void:
	player = get_tree().get_first_node_in_group("player") as VillagePlayer
	if player == null:
		push_warning("HUD: no se encontró nodo en grupo 'player'; joystick y botón inactivos.")


func _process(_delta: float) -> void:
	if player == null:
		return
	var blocking := _ui_blocks_move()
	if blocking:
		player.touch_vector = Vector2.ZERO
	else:
		player.touch_vector = joystick.output
	interact_button.visible = player.interact_target != null and not blocking
	if interact_button.visible:
		_label_interact()
	_update_place_button(blocking)
	_update_gift_button(blocking)
	_refresh_status()
	if _dialogue_open and player.interact_target != _dialogue_target:
		_close_dialogue_now()


func _ui_blocks_move() -> bool:
	return get_tree().paused or (_shop_root != null and _shop_root.visible) or (_gift_root != null and _gift_root.visible)


func _label_interact() -> void:
	var target: Node = player.interact_target
	if target == null:
		return
	if _dialogue_open and target == _dialogue_target:
		interact_button.text = "Seguir"
	elif target.has_method("advance_dialogue"):
		interact_button.text = "Hablar"
	elif target.has_method("is_vendor") and bool(target.call("is_vendor")):
		interact_button.text = "Tienda"
	elif "target_scene" in target and String(target.get("target_scene")) != "":
		interact_button.text = "Ir"
	else:
		interact_button.text = "Usar"


## Fase 6 — botón Colocar: solo con silla + placer (casa) + sin arrastre.
func _placer():
	return get_tree().get_first_node_in_group("furniture_placer")


func _update_place_button(blocking: bool) -> void:
	var pl = _placer()
	if blocking or pl == null or pl.is_carrying():
		place_button.visible = false
		return
	place_button.visible = bool(player.get("inventory").call("has_item", "silla", 1))


func _on_place_pressed() -> void:
	var pl = _placer()
	if pl != null:
		pl.start_placing()


func _npc_nearby():
	var t: Node2D = player.interact_target if player != null else null
	if t != null and t.has_method("give_gift"):
		return t
	return null


func _update_gift_button(blocking: bool) -> void:
	if blocking:
		gift_button.visible = false
		return
	gift_button.visible = _npc_nearby() != null


func _on_gift_pressed() -> void:
	var npc = _npc_nearby()
	if npc == null:
		return
	_open_gift(npc)


func show_message(text: String) -> void:
	if _toast == null:
		message_label.text = text
		return
	message_label.text = text
	_toast.visible = true
	_toast.modulate.a = 1.0
	if _msg_tween and _msg_tween.is_valid():
		_msg_tween.kill()
	_msg_tween = create_tween()
	_msg_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_msg_tween.tween_interval(2.2)
	_msg_tween.tween_property(_toast, "modulate:a", 0.0, 0.35)
	_msg_tween.tween_callback(func() -> void:
		_toast.visible = false
		_toast.modulate.a = 1.0
	)


func _on_interact_pressed() -> void:
	if player == null or player.interact_target == null:
		return
	var target: Node2D = player.interact_target
	if target.has_method("is_vendor") and bool(target.call("is_vendor")):
		_open_shop(target)
		return
	if target.has_method("advance_dialogue"):
		if _dialogue_open and _dialogue_target == target:
			_advance_dialogue()
		else:
			_open_dialogue(target)
		return
	if target.has_method("interact"):
		show_message(String(target.call("interact", player)))


func clear_message() -> void:
	if _msg_tween and _msg_tween.is_valid():
		_msg_tween.kill()
	message_label.text = ""
	if _toast != null:
		_toast.visible = false
		_toast.modulate.a = 1.0


func _style_action_buttons() -> void:
	for b in [interact_button, place_button, gift_button]:
		b.add_theme_font_size_override("font_size", 26)
		b.custom_minimum_size = Vector2(132, 112)
	place_button.text = "Poner"
	gift_button.text = "Regalo"
	interact_button.text = "Usar"
	OretyTheme.style_secondary(place_button)


func _build_toast() -> void:
	_toast = PanelContainer.new()
	_toast.theme = _ui_theme
	_toast.name = "Toast"
	_toast.visible = false
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.z_index = 6
	_toast.add_theme_stylebox_override("panel", OretyTheme.toast_box())
	_anchor(_toast, 0.06, 0.0, 0.94, 0.0, 0, 118, 0, 250)
	add_child(_toast)
	message_label.reparent(_toast)
	message_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	message_label.offset_left = 0
	message_label.offset_top = 0
	message_label.offset_right = 0
	message_label.offset_bottom = 0
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_color_override("font_color", OretyTheme.CREAM)
	message_label.add_theme_font_size_override("font_size", 26)


func _build_status() -> void:
	var chip := PanelContainer.new()
	chip.theme = _ui_theme
	chip.name = "StatusChip"
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.z_index = 4
	_anchor(chip, 1.0, 0.0, 1.0, 0.0, -250, 16, -16, 108)
	add_child(chip)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(box)
	_status_name = Label.new()
	_status_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status_name.add_theme_font_size_override("font_size", 26)
	box.add_child(_status_name)
	_status_coins = Label.new()
	_status_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status_coins.add_theme_color_override("font_color", Color("9a6230"))
	_status_coins.add_theme_font_size_override("font_size", 24)
	box.add_child(_status_coins)


func _refresh_status() -> void:
	if _status_name == null or player == null:
		return
	var nm := String(player.player_name)
	_status_name.text = nm if nm != "" else "Viajero"
	_status_coins.text = "%d monedas" % int(player.coins)
	if _pause_root != null and _pause_root.visible:
		_pause_name.text = _status_name.text
		_pause_coins.text = _status_coins.text


func _build_pause() -> void:
	var btn := Button.new()
	btn.theme = _ui_theme
	btn.name = "PauseButton"
	btn.text = "Pausa"
	btn.z_index = 4
	btn.custom_minimum_size = Vector2(150, 84)
	_anchor(btn, 0.0, 0.0, 0.0, 0.0, 16, 16, 166, 100)
	btn.pressed.connect(_open_pause)
	add_child(btn)

	_pause_root = Control.new()
	_pause_root.theme = _ui_theme
	_pause_root.name = "PauseMenu"
	_pause_root.visible = false
	_pause_root.z_index = 25
	_pause_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_pause_root)
	var dim := ColorRect.new()
	dim.color = Color(0.10, 0.06, 0.14, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_root.add_child(dim)
	var card := PanelContainer.new()
	_anchor(card, 0.5, 0.5, 0.5, 0.5, -280, -280, 280, 280)
	_pause_root.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	card.add_child(box)
	var title := Label.new()
	title.text = "Pausa"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", OretyTheme.PLUM)
	box.add_child(title)
	_pause_name = Label.new()
	_pause_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_name.add_theme_font_size_override("font_size", 34)
	box.add_child(_pause_name)
	_pause_coins = Label.new()
	_pause_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_coins.add_theme_font_size_override("font_size", 30)
	_pause_coins.add_theme_color_override("font_color", Color("9a6230"))
	box.add_child(_pause_coins)
	var resume := Button.new()
	resume.text = "Volver al juego"
	resume.custom_minimum_size = Vector2(0, 96)
	resume.pressed.connect(_close_pause)
	box.add_child(resume)


func _open_pause() -> void:
	_close_shop_now()
	_close_gift_now()
	_close_dialogue_now()
	joystick.cancel()
	_refresh_status()
	_reveal(_pause_root)
	get_tree().paused = true


func _close_pause() -> void:
	_conceal(_pause_root, func() -> void:
		get_tree().paused = false
	)


func _build_dialogue() -> void:
	_dialogue_root = PanelContainer.new()
	_dialogue_root.theme = _ui_theme
	_dialogue_root.name = "DialogueBox"
	_dialogue_root.visible = false
	_dialogue_root.z_index = 8
	_dialogue_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_anchor(_dialogue_root, 0.04, 1.0, 0.96, 1.0, 0, -760, 0, -470)
	add_child(_dialogue_root)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_root.add_child(row)
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(132, 160)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_box := OretyTheme.panel_box()
	frame_box.bg_color = Color("f3e2cf")
	frame_box.shadow_size = 0
	frame.add_theme_stylebox_override("panel", frame_box)
	row.add_child(frame)
	_dialogue_portrait = TextureRect.new()
	_dialogue_portrait.custom_minimum_size = Vector2(120, 148)
	_dialogue_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dialogue_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_dialogue_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_dialogue_portrait)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	_dialogue_name = Label.new()
	_dialogue_name.add_theme_font_size_override("font_size", 30)
	_dialogue_name.add_theme_color_override("font_color", OretyTheme.TERRACOTTA_DARK)
	_dialogue_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_dialogue_name)
	_dialogue_body = Label.new()
	_dialogue_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dialogue_body.add_theme_font_size_override("font_size", 28)
	_dialogue_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_dialogue_body)
	var hint := Label.new()
	hint.text = "Toca la caja o Seguir"
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color("8a7b90"))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(hint)
	_dialogue_root.gui_input.connect(_on_dialogue_input)


func _on_dialogue_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_advance_dialogue()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance_dialogue()


func _open_dialogue(target: Node) -> void:
	_dialogue_target = target
	_dialogue_open = true
	_apply_dialogue_line(String(target.call("advance_dialogue")))
	if _dialogue_open:
		_reveal(_dialogue_root)


func _advance_dialogue() -> void:
	if _dialogue_target == null or not is_instance_valid(_dialogue_target):
		_close_dialogue_now()
		return
	if not _dialogue_target.has_method("advance_dialogue"):
		_close_dialogue_now()
		return
	_apply_dialogue_line(String(_dialogue_target.call("advance_dialogue")))


func _apply_dialogue_line(raw: String) -> void:
	if raw.is_empty():
		_close_dialogue_now()
		return
	var speaker := _speaker_name(_dialogue_target)
	var body := raw
	var prefix := speaker + ": "
	if speaker != "" and raw.begins_with(prefix):
		body = raw.substr(prefix.length())
	_dialogue_name.text = speaker
	_dialogue_body.text = body
	_dialogue_portrait.texture = _speaker_texture(_dialogue_target)
	_dialogue_open = true
	_dialogue_root.visible = true


func _speaker_name(target: Node) -> String:
	if target == null:
		return ""
	var id := String(target.get("npc_id"))
	if id != "":
		var data := NPCDatabase.get_npc(id)
		if not data.is_empty():
			return String(data.get("name", id))
	return id


func _speaker_texture(target: Node) -> Texture2D:
	if target == null:
		return null
	var id := String(target.get("npc_id"))
	if id == "":
		return null
	var data := NPCDatabase.get_npc(id)
	if data.is_empty():
		return null
	var path := String(data.get("sprite", ""))
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _close_dialogue_now() -> void:
	_dialogue_open = false
	_dialogue_target = null
	if _dialogue_root != null:
		_dialogue_root.visible = false


func _build_shop() -> void:
	_shop_root = _modal_root("ShopMenu")
	var card := _modal_card(_shop_root, 300, 470)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	var title := Label.new()
	title.text = "Puesto"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", OretyTheme.PLUM)
	box.add_child(title)
	_shop_coins = Label.new()
	_shop_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_shop_coins)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	box.add_child(tabs)
	var sell := Button.new()
	sell.text = "Vender"
	sell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell.custom_minimum_size = Vector2(0, 80)
	sell.pressed.connect(func() -> void: _set_shop_mode("sell"))
	tabs.add_child(sell)
	var buy := Button.new()
	buy.text = "Comprar"
	buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy.custom_minimum_size = Vector2(0, 80)
	OretyTheme.style_secondary(buy)
	buy.pressed.connect(func() -> void: _set_shop_mode("buy"))
	tabs.add_child(buy)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 380)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_shop_list = VBoxContainer.new()
	_shop_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shop_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_shop_list)
	_shop_confirm = VBoxContainer.new()
	_shop_confirm.visible = false
	_shop_confirm.add_theme_constant_override("separation", 8)
	box.add_child(_shop_confirm)
	_shop_confirm_label = Label.new()
	_shop_confirm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_shop_confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shop_confirm.add_child(_shop_confirm_label)
	var confirm_row := HBoxContainer.new()
	confirm_row.add_theme_constant_override("separation", 10)
	_shop_confirm.add_child(confirm_row)
	var yes := Button.new()
	yes.text = "Confirmar"
	yes.custom_minimum_size = Vector2(0, 84)
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.pressed.connect(_confirm_shop)
	confirm_row.add_child(yes)
	var no := Button.new()
	no.text = "Cancelar"
	no.custom_minimum_size = Vector2(0, 84)
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	OretyTheme.style_secondary(no)
	no.pressed.connect(func() -> void:
		_shop_pending = {}
		_shop_confirm.visible = false
	)
	confirm_row.add_child(no)
	var close := Button.new()
	close.text = "Cerrar"
	close.custom_minimum_size = Vector2(0, 80)
	OretyTheme.style_secondary(close)
	close.pressed.connect(_close_shop)
	box.add_child(close)


func _set_shop_mode(mode: String) -> void:
	_shop_mode = mode
	_shop_pending = {}
	_shop_confirm.visible = false
	_refresh_shop()


func _open_shop(target: Node) -> void:
	_close_dialogue_now()
	_close_gift_now()
	joystick.cancel()
	_shop_target = target
	_shop_mode = "sell"
	_shop_pending = {}
	_shop_confirm.visible = false
	_refresh_shop()
	_reveal(_shop_root)


func _refresh_shop() -> void:
	if player == null or _shop_target == null or not is_instance_valid(_shop_target):
		return
	_shop_coins.text = "Tienes %d monedas" % int(player.coins)
	for c in _shop_list.get_children():
		c.queue_free()
	var rows: Array = []
	if _shop_mode == "sell" and _shop_target.has_method("vendor_sell_list"):
		rows = _shop_target.call("vendor_sell_list")
	elif _shop_target.has_method("vendor_buy_list"):
		rows = _shop_target.call("vendor_buy_list")
	if rows.is_empty():
		var empty := Label.new()
		empty.text = "Nada por aquí todavía."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_shop_list.add_child(empty)
		return
	for row in rows:
		var info: Dictionary = row
		var id := String(info.get("id", ""))
		var nm := String(info.get("name", id))
		var price := int(info.get("price", 0))
		var owned := player.inventory.count(id)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 92)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if _shop_mode == "sell":
			btn.text = "%s    tienes %d    ·    %d monedas" % [nm, owned, price]
			btn.disabled = owned < 1 or price <= 0
		else:
			btn.text = "%s    ·    %d monedas" % [nm, price]
			btn.disabled = price <= 0 or int(player.coins) < price
		btn.pressed.connect(_ask_shop.bind(id, nm, price))
		_shop_list.add_child(btn)


func _ask_shop(id: String, nm: String, price: int) -> void:
	_shop_pending = {"id": id, "name": nm, "price": price, "mode": _shop_mode}
	if _shop_mode == "sell":
		_shop_confirm_label.text = "¿Vender 1 %s por %d monedas?" % [nm, price]
	else:
		_shop_confirm_label.text = "¿Comprar 1 %s por %d monedas?" % [nm, price]
	_shop_confirm.visible = true


func _confirm_shop() -> void:
	if _shop_pending.is_empty() or player == null or _shop_target == null:
		return
	if not is_instance_valid(_shop_target):
		_close_shop_now()
		return
	var id := String(_shop_pending.get("id", ""))
	var msg := ""
	if String(_shop_pending.get("mode", "")) == "sell":
		msg = String(_shop_target.call("confirm_sell", player, id))
	else:
		msg = String(_shop_target.call("confirm_buy", player, id))
	_shop_pending = {}
	_shop_confirm.visible = false
	show_message(msg)
	_refresh_shop()


func _close_shop() -> void:
	_conceal(_shop_root, _close_shop_now)


func _close_shop_now() -> void:
	_shop_pending = {}
	_shop_target = null
	if _shop_confirm != null:
		_shop_confirm.visible = false
	if _shop_root != null:
		_shop_root.visible = false
		_shop_root.modulate.a = 1.0


func _build_gift() -> void:
	_gift_root = _modal_root("GiftMenu")
	var card := _modal_card(_gift_root, 300, 430)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	_gift_title = Label.new()
	_gift_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gift_title.add_theme_font_size_override("font_size", 34)
	_gift_title.add_theme_color_override("font_color", OretyTheme.PLUM)
	box.add_child(_gift_title)
	var hint := Label.new()
	hint.text = "Elige qué regalar. La silla se queda en casa."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 22)
	box.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 360)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_gift_list = VBoxContainer.new()
	_gift_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gift_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_gift_list)
	_gift_confirm = VBoxContainer.new()
	_gift_confirm.visible = false
	_gift_confirm.add_theme_constant_override("separation", 8)
	box.add_child(_gift_confirm)
	_gift_confirm_label = Label.new()
	_gift_confirm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_gift_confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gift_confirm.add_child(_gift_confirm_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_gift_confirm.add_child(row)
	var yes := Button.new()
	yes.text = "Regalar"
	yes.custom_minimum_size = Vector2(0, 84)
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.pressed.connect(_confirm_gift)
	row.add_child(yes)
	var no := Button.new()
	no.text = "Cancelar"
	no.custom_minimum_size = Vector2(0, 84)
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	OretyTheme.style_secondary(no)
	no.pressed.connect(func() -> void:
		_gift_pending = ""
		_gift_confirm.visible = false
	)
	row.add_child(no)
	var close := Button.new()
	close.text = "Cerrar"
	close.custom_minimum_size = Vector2(0, 80)
	OretyTheme.style_secondary(close)
	close.pressed.connect(_close_gift)
	box.add_child(close)


func _open_gift(npc: Node) -> void:
	_close_dialogue_now()
	_close_shop_now()
	joystick.cancel()
	_gift_target = npc
	_gift_pending = ""
	_gift_confirm.visible = false
	var speaker := _speaker_name(npc)
	_gift_title.text = "Regalo para %s" % speaker if speaker != "" else "Regalo"
	_refresh_gift()
	_reveal(_gift_root)


func _refresh_gift() -> void:
	if player == null:
		return
	for c in _gift_list.get_children():
		c.queue_free()
	var order: Array = NPC.GIFT_ORDER
	for gid in order:
		var id := String(gid)
		var data := ItemDatabase.get_item(id)
		if data.is_empty():
			continue
		var owned := player.inventory.count(id)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 88)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.text = "%s    ·    tienes %d" % [String(data.get("name", id)), owned]
		btn.disabled = owned < 1
		btn.pressed.connect(_ask_gift.bind(id, String(data.get("name", id))))
		_gift_list.add_child(btn)


func _ask_gift(id: String, nm: String) -> void:
	_gift_pending = id
	_gift_confirm_label.text = "¿Regalar 1 %s?" % nm
	_gift_confirm.visible = true


func _confirm_gift() -> void:
	if _gift_pending == "" or player == null or _gift_target == null:
		return
	if not is_instance_valid(_gift_target):
		_close_gift_now()
		return
	var msg := String(_gift_target.call("give_gift", player, _gift_pending))
	_gift_pending = ""
	_gift_confirm.visible = false
	show_message(msg)
	_refresh_gift()


func _close_gift() -> void:
	_conceal(_gift_root, _close_gift_now)


func _close_gift_now() -> void:
	_gift_pending = ""
	_gift_target = null
	if _gift_confirm != null:
		_gift_confirm.visible = false
	if _gift_root != null:
		_gift_root.visible = false
		_gift_root.modulate.a = 1.0


func _modal_root(node_name: String) -> Control:
	var root := Control.new()
	root.theme = _ui_theme
	root.name = node_name
	root.visible = false
	root.z_index = 18
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.10, 0.06, 0.14, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	return root


func _modal_card(root: Control, half_w: float, half_h: float) -> PanelContainer:
	var card := PanelContainer.new()
	_anchor(card, 0.5, 0.5, 0.5, 0.5, -half_w, -half_h, half_w, half_h)
	root.add_child(card)
	return card


func _anchor(c: Control, l: float, t: float, r: float, b: float, ol: float, ot: float, orr: float, ob: float) -> void:
	c.anchor_left = l
	c.anchor_top = t
	c.anchor_right = r
	c.anchor_bottom = b
	c.offset_left = ol
	c.offset_top = ot
	c.offset_right = orr
	c.offset_bottom = ob


func _reveal(node: Control) -> void:
	node.visible = true
	node.modulate.a = 0.0
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(node, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _conceal(node: Control, done: Callable) -> void:
	if node == null or not node.visible:
		done.call()
		return
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(node, "modulate:a", 0.0, 0.14)
	tw.tween_callback(func() -> void:
		node.visible = false
		node.modulate.a = 1.0
		done.call()
	)
