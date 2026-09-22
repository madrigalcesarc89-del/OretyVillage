# Orety Village

Proyecto nuevo e independiente de `Orety` (Godot 4.7.1 Standard, 2D vertical móvil 720x1280).

Estado: Fase 2 — Plaza jugable con ciclo día/noche (Autoload `GameTime`).

## Estructura

- `scenes/` — Main.tscn (carga Plaza); `world/` — zonas del pueblo
  (actual: `Plaza.tscn`; futuras: `Playa`, `Bosque`, `Granja`, ...
  como escenas separadas que comparten el Autoload `GameTime`).
  `PrototypeWorld.tscn` se conserva como referencia de testing.
- `scripts/` — Main.gd; `simulation/`, `save/` para Fase 1
- `data/content/` — catálogos JSON futuros
- `assets/import/` — PNG/MP3 (pendiente, tarea aparte)
- `audio/`, `ui/`, `export/` — audio, UI y builds (debug)

## Export Android

Preset Android pendiente de SDK (ver reporte de setup). Solo APK debug.
