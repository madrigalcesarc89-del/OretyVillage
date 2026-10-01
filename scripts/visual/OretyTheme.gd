class_name OretyTheme
extends RefCounted
## Paleta de Orety Village: papel crema, ciruela, terracota y salvia.
## No es el madera-y-hoja de otros life-sims: es cuento pintado.

const CREAM := Color("fff6e8")
const PLUM := Color("3a2a4a")
const PLUM_DEEP := Color("241830")
const TERRACOTTA := Color("e07a4c")
const TERRACOTTA_DARK := Color("c45d34")
const SAGE := Color("6e9460")
const SAGE_DARK := Color("567848")
const INK := Color("2a2033")
const GOLD := Color("e2b15a")


static func make() -> Theme:
	var theme := Theme.new()
	var font_path := "res://assets/fonts/Nunito-Bold.ttf"
	if ResourceLoader.exists(font_path):
		var loaded: Font = load(font_path)
		if loaded is FontFile:
			var ff := loaded as FontFile
			if ThemeDB.fallback_font != null:
				ff.fallbacks = [ThemeDB.fallback_font]
			theme.default_font = ff
		else:
			theme.default_font = loaded
	theme.default_font_size = 28

	var normal := _button_box(TERRACOTTA, PLUM)
	var hover := _button_box(TERRACOTTA.lightened(0.08), PLUM)
	var pressed := _button_box(TERRACOTTA_DARK, PLUM)
	var disabled := _button_box(Color("d9cbb8"), Color("a898a4"))
	theme.set_stylebox("normal", "Button", normal)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_stylebox("disabled", "Button", disabled)
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_color", "Button", CREAM)
	theme.set_color("font_hover_color", "Button", CREAM)
	theme.set_color("font_pressed_color", "Button", CREAM)
	theme.set_color("font_disabled_color", "Button", Color("7a7080"))
	theme.set_font_size("font_size", "Button", 28)

	theme.set_color("font_color", "Label", INK)
	theme.set_font_size("font_size", "Label", 28)

	var line := _button_box(CREAM, PLUM)
	line.set_corner_radius_all(22)
	line.shadow_size = 0
	theme.set_stylebox("normal", "LineEdit", line)
	theme.set_stylebox("focus", "LineEdit", line)
	theme.set_color("font_color", "LineEdit", INK)
	theme.set_color("font_placeholder_color", "LineEdit", Color("9a8b98"))
	theme.set_color("caret_color", "LineEdit", TERRACOTTA)
	theme.set_font_size("font_size", "LineEdit", 36)

	var panel := panel_box()
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("panel", "Panel", panel)
	return theme


static func panel_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = CREAM
	box.border_color = PLUM
	box.set_border_width_all(5)
	box.set_corner_radius_all(28)
	box.shadow_color = Color(0.12, 0.06, 0.16, 0.35)
	box.shadow_size = 10
	box.shadow_offset = Vector2(0, 6)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 16
	box.content_margin_bottom = 16
	return box


static func toast_box() -> StyleBoxFlat:
	var box := panel_box()
	box.bg_color = Color(0.227, 0.165, 0.290, 0.94)
	box.set_corner_radius_all(22)
	box.shadow_size = 6
	return box


static func _button_box(bg: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(4)
	box.set_corner_radius_all(24)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	box.shadow_color = Color(0.15, 0.08, 0.2, 0.25)
	box.shadow_size = 4
	box.shadow_offset = Vector2(0, 3)
	return box


static func style_secondary(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _button_box(SAGE, PLUM))
	button.add_theme_stylebox_override("hover", _button_box(SAGE.lightened(0.06), PLUM))
	button.add_theme_stylebox_override("pressed", _button_box(SAGE_DARK, PLUM))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
