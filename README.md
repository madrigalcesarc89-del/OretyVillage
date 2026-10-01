# Orety Village

Vida/exploración/socialización ambientado en el universo Orety. 
Godot 4.7.1 (GDScript), target principal Android/móvil, 100% gratis 
y open source en sus herramientas.

## Estado actual

Proyecto en desarrollo activo. MVP funcional y verificado en 
dispositivo Android real: mundo explorable (Plaza) con ciclo día/
noche, dos NPCs (Mango, Orety) con vagabundeo/rutina/diálogo/amistad 
por regalos, economía completa (recolección, pesca, compra/venta), 
casa con un mueble colocable, guardado automático persistente, y 
pantalla de nombre de jugador.

**Todo el contenido visual actual es placeholder deliberado**: 
geometría de colores sólidos, sin arte final, sin animaciones más 
allá de un bob procedural básico. La lógica y los datos están 
completos y probados; lo visual está pendiente de diseño real.

## Estructura del proyecto

scenes/
world/ → Plaza.tscn, House.tscn, PrototypeWorld.tscn (testing)
scripts/
simulation/ → NPC.gd, GameTime.gd, Inventory.gd, ItemDatabase.gd,
NPCDatabase.gd, SaveGame.gd, Harvestable/Interactable
save/ → (vacío, reservado)
data/
content/ → items.json, npcs.json — TODO el contenido del juego
(ítems, precios, NPCs, diálogos) vive aquí, no en código
assets/
import/ → sprites copiados desde el proyecto Orety original
ui/
HUD.tscn → joystick, botón de interacción, botón de regalo, mensajes
export/ → builds de Android (no versionado)


## Principios de arquitectura (no negociables)

1. **Datos fuera del código.** Todo el contenido del juego (NPCs, 
   ítems, precios, diálogos) vive en `data/content/*.json`. Los 
   scripts leen esos datos, nunca los tienen hardcodeados.
2. **Composición sobre reescritura.** `Harvestable extends 
   Interactable`, y todo objeto interactuable (caja, pozo, puesto, 
   NPCs, puertas) usa ese mismo patrón base. No crear sistemas 
   paralelos para cosas que ya encajan en el patrón existente.
3. **Autoloads mínimos y con nombres que no colisionen** con clases 
   nativas de Godot (lección aprendida: `Time` colisionaba, se usa 
   `GameTime`; evitar `class_name` en singletons que puedan 
   duplicarse).
4. **Todo se verifica en dispositivo Android real**, no solo en el 
   editor de escritorio. Varios bugs reales (cámara desalineada, 
   joystick que no respondía) solo eran visibles en el dispositivo 
   físico, nunca en el editor.

## ⚠️ Zonas de alcance restringido

Este repo recibe cambios de dos fuentes: lógica/arquitectura 
(coordinada por Claude + un agente de código) y visual/estética 
(coordinada por Grok). Para evitar romper funcionalidad ya probada 
en dispositivo real, respeta esta división:

### Libre de modificar (visual/estética):
- `ui/` — rediseño visual completo permitido (colores, tipografía, 
  iconos, layout), siempre que los nodos que el código referencia 
  por nombre/ruta sigan existiendo con esos mismos nombres (o se 
  coordine el cambio de referencias).
- Apariencia de `scenes/world/*.tscn` — reemplazar geometría de 
  color sólido por tilemaps/sprites reales, agregar decoración 
  visual, iluminación, partículas — SIN mover ni eliminar los nodos 
  funcionales existentes (Player, Camera2D, Area2D de interactuables, 
  límites de colisión) ni cambiar sus posiciones/tamaños de colisión 
  sin avisar.
- `assets/` — agregar sprites, animaciones, audio nuevo.
- Animaciones de personajes (jugador, NPCs) — bienvenidas, siempre 
  que no rompan el sistema de `flip_h` y las referencias de nodo que 
  `Player.gd`/`NPC.gd` esperan.

### NO modificar sin coordinarlo primero:
- `scripts/simulation/*.gd` — toda la lógica de juego.
- `data/content/*.json` — la ESTRUCTURA de campos (puedes agregar 
  campos nuevos opcionales como `sprite_path` o `animation_id`, 
  nunca eliminar o renombrar campos existentes como `id`, 
  `sell_price`, `buy_price`, `gives_item_id`).
- El árbol de nodos funcional de las escenas (qué Area2D existen, 
  sus nombres, su jerarquía) — solo su apariencia.
- `SaveGame.gd` y el formato de `user://savegame.json`.
- `project.godot` (viewport, stretch mode, preset de exportación 
  Android) salvo que el cambio sea explícitamente sobre estos.

### Flujo de trabajo esperado:
- Trabajar en una rama separada (`visual-polish` o similar), no 
  directo en `main`.
- Cada lote de cambios visuales debe poder abrirse en el editor sin 
  errores y no debe romper ninguna funcionalidad descrita en "Estado 
  actual" arriba.
- Si algo visual requiere tocar una zona restringida (por ejemplo, 
  una animación nueva necesita un nodo adicional en Player.tscn), 
  está bien — pero decirlo explícitamente en el commit/PR en vez de 
  hacerlo silenciosamente.