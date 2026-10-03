class_name FootstepSynth
extends RefCounted
## Pasos placeholder generados por código (cero archivos, cero licencias).
## 0 pasto suave, 1 tierra media, 2 piedra/madera clic. Reemplazable por
## WAV reales sin tocar la lógica (misma firma: stream_por_terreno()).

const MIX_RATE := 22050
const LENGTH := 0.12

static var _cache := {}


## Un stream por terreno, generado una vez (la variedad la da el pitch).
static func stream_por_terreno(terrain_id: int) -> AudioStreamWAV:
	var key := 2 if (terrain_id == 2 or terrain_id == 3) else (1 if terrain_id == 1 else 0)
	if _cache.has(key):
		return _cache[key]
	var wav: AudioStreamWAV
	match key:
		2:
			wav = _burst(4200.0, 0.35, 0.09)
		1:
			wav = _burst(1400.0, 0.5, 0.11)
		_:
			wav = _burst(500.0, 0.65, 0.12)
	_cache[key] = wav
	return wav


## Ráfaga de ruido con envolvente de decaimiento y suavizado simple.
## cutoff alto = brillante (piedra); bajo = sordo (pasto).
static func _burst(cutoff: float, gain: float, length: float) -> AudioStreamWAV:
	var n := int(MIX_RATE * length)
	var data := PackedByteArray()
	data.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var smooth := 0.0
	var alpha: float = clampf(cutoff / 6000.0, 0.05, 0.9)
	for i in n:
		var t := float(i) / float(n)
		var env := (1.0 - t) * (1.0 - t)
		var noise := rng.randf_range(-1.0, 1.0)
		smooth = lerpf(smooth, noise, alpha)
		data[i] = int(127.5 + 127.0 * clampf(smooth * env * gain, -1.0, 1.0)) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = MIX_RATE
	wav.data = data
	return wav
