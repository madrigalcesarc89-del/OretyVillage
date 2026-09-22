extends CanvasModulate
## Fase 2 — Iluminación día/noche por gradiente CONTINUO.
## NO asigna keyframes discretos: interpola (lerp) entre los dos
## keyframes adyacentes según el progreso 0.0-1.0 de Time.
## keyframes (hora -> color): 5:00 amanecer cálido, 12:00 blanco,
## 18:00 atardecer naranja, 22:00 noche azul ~0.35, 4:00 noche profunda.

const KEYS: Array = [
	[0.0, Color(0.30, 0.36, 0.55)],    # 00:00 noche profunda
	[0.2083, Color(1.0, 0.85, 0.70)],  # 05:00 amanecer cálido
	[0.5, Color(1.0, 1.0, 1.0)],       # 12:00 mediodía
	[0.75, Color(1.0, 0.62, 0.38)],    # 18:00 atardecer
	[0.9167, Color(0.32, 0.38, 0.62)], # 22:00 noche azul
	[1.0, Color(0.30, 0.36, 0.55)],    # 24:00 = 00:00
]


func _ready() -> void:
	color = sample_color(GameTime.get_progress())


func _process(_delta: float) -> void:
	color = sample_color(GameTime.get_progress())


## Muestreo continuo del gradiente: lerp entre keyframes vecinos.
static func sample_color(progress: float) -> Color:
	var p := clampf(progress, 0.0, 1.0)
	for i in range(KEYS.size() - 1):
		var p0: float = KEYS[i][0]
		var p1: float = KEYS[i + 1][0]
		if p >= p0 and p <= p1:
			var t := 0.0
			if p1 > p0:
				t = (p - p0) / (p1 - p0)
			return (KEYS[i][1] as Color).lerp(KEYS[i + 1][1] as Color, t)
	return KEYS[KEYS.size() - 1][1]
