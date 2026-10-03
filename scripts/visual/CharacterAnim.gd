extends Node
## Camina con una hoja 2x2 si existe; si no, un squash suave.
## No toca flip_h: lo siguen poniendo Player.gd y NPC.gd.

@export var walk_texture: Texture2D
@export var h_frames := 2
@export var v_frames := 2
@export var fps := 6.5
## Solo se usa si no se puede medir el cuerpo opaco.
@export var fill := 0.86

var _sprite: Sprite2D
var _walk: Texture2D
var _idle: Texture2D
var _idle_scale := Vector2.ONE
var _walk_scale := Vector2.ONE
var _captured := false
var _time := 0.0
var _last_pos := Vector2.ZERO
var _have_pos := false


func _ready() -> void:
	_sprite = get_parent() as Sprite2D
	_walk = walk_texture if walk_texture != null else _resolve_sheet()
	_capture_idle()


func _process(delta: float) -> void:
	if _sprite == null:
		return
	_capture_idle()
	var body := _body()
	if body == null:
		return
	var pos := body.global_position
	var moving := _have_pos and pos.distance_to(_last_pos) > 0.45
	_last_pos = pos
	_have_pos = true
	if _walk == null or not _captured:
		_fallback(delta, moving)
		return
	if moving:
		if _sprite.texture != _walk:
			_sprite.texture = _walk
			_sprite.hframes = h_frames
			_sprite.vframes = v_frames
			_sprite.scale = _walk_scale
		_time += delta
		var count := maxi(h_frames * v_frames, 1)
		_sprite.frame = int(_time * fps) % count
	else:
		_time = 0.0
		if _idle != null and _sprite.texture != _idle:
			_sprite.texture = _idle
			_sprite.hframes = 1
			_sprite.vframes = 1
			_sprite.frame = 0
			_sprite.scale = _idle_scale


func _fallback(delta: float, moving: bool) -> void:
	if not _captured:
		return
	if moving:
		_time += delta
		var squash := 1.0 + sin(_time * 12.0) * 0.045
		_sprite.scale = Vector2(_idle_scale.x / squash, _idle_scale.y * squash)
	else:
		_sprite.scale = _sprite.scale.lerp(_idle_scale, minf(delta * 10.0, 1.0))


func _capture_idle() -> void:
	if _captured or _sprite == null:
		return
	if _sprite.texture == null or _sprite.texture == _walk:
		return
	_idle = _sprite.texture
	_idle_scale = _sprite.scale
	_captured = true
	if _walk != null:
		var idle_body := _body_height(_idle, 1, 1)
		var walk_body := _body_height(_walk, h_frames, v_frames)
		if idle_body > 2.0 and walk_body > 2.0:
			# Mismo alto de cuerpo en pantalla. El lienzo idle tiene mucho
			# padding; comparar el alto de la textura hacía el caminar más grande.
			var s := (idle_body * absf(_idle_scale.y)) / walk_body
			_walk_scale = Vector2(s, s)
		else:
			var frame_h := float(_walk.get_height()) / float(maxi(v_frames, 1))
			var shown := frame_h * fill
			var idle_h := float(_idle.get_height()) * absf(_idle_scale.y)
			var s2 := idle_h / shown if shown > 0.0 else 1.0
			_walk_scale = Vector2(s2, s2)


func _body_height(tex: Texture2D, hf: int, vf: int) -> float:
	if tex == null:
		return 0.0
	var img := tex.get_image()
	if img == null or img.is_empty():
		return 0.0
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var data := img.get_data()
	var width := img.get_width()
	var fw := int(width / maxi(hf, 1))
	var fh := int(img.get_height() / maxi(vf, 1))
	var heights: Array[int] = []
	for row in vf:
		for col in hf:
			var x0 := col * fw
			var y0 := row * fh
			var min_y := -1
			var max_y := -1
			for y in fh:
				var row_start := ((y0 + y) * width + x0) * 4
				var opaque := false
				for x in fw:
					if data[row_start + x * 4 + 3] > 30:
						opaque = true
						break
				if opaque:
					if min_y < 0:
						min_y = y
					max_y = y
			if min_y >= 0:
				heights.append(max_y - min_y + 1)
	if heights.is_empty():
		return 0.0
	heights.sort()
	return float(heights[heights.size() >> 1])


func _body() -> Node2D:
	if _sprite == null:
		return null
	return _sprite.get_parent() as Node2D


func _resolve_sheet() -> Texture2D:
	var body := _body()
	if body == null:
		return null
	var path := ""
	var id := String(body.get("npc_id"))
	match id:
		"mango":
			path = "res://assets/characters/mango_walk.png"
		"orety":
			path = "res://assets/characters/orety_walk.png"
		_:
			if body.is_in_group("player"):
				path = "res://assets/characters/ciana_walk.png"
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
