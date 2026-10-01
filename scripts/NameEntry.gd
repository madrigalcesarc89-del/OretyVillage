extends CanvasLayer
## Primera vez: pide el nombre del jugador (táctil + teclado virtual).
## Sin Player en escena; al confirmar, Main arranca Plaza con el nombre.
## Raíz CanvasLayer (no Control bajo Node2D): así los anchors usan el
## viewport, igual que el HUD ya validado.


func _ready() -> void:
	%StartButton.disabled = true
	%StartButton.pressed.connect(_on_confirm)
	%NameField.text_changed.connect(_on_text_changed)
	%NameField.text_submitted.connect(_on_submitted)
	%NameField.grab_focus()


func _on_text_changed(new_text: String) -> void:
	%StartButton.disabled = new_text.strip_edges().is_empty()


func _on_submitted(text: String) -> void:
	if not text.strip_edges().is_empty():
		_on_confirm()


func _on_confirm() -> void:
	var field: LineEdit = %NameField
	var player_name: String = field.text.strip_edges()
	if player_name.is_empty():
		return
	%NameField.release_focus()
	var mgr: Node = get_tree().get_first_node_in_group("world_manager")
	if mgr != null:
		mgr.call("begin_from_name", player_name)
