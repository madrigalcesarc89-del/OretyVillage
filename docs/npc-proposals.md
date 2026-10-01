# Propuestas de NPCs — Orety Village

**No integrar todavía.** Este documento es solo diseño. No modifica
`data/content/npcs.json` ni instancia a nadie en la Plaza. La lógica de
vagabundeo, rutinas y amistad la engancha el otro agente cuando toque,
siguiendo el patrón de Mango y Orety.

Estilo: gouache de cuento, paleta crema / ciruela / terracota / salvia.
No son aldeanos redondos de un life-sim genérico: cada uno tiene silueta
y oficio distintos.

Retratos (fondo transparente):

- [Luma](proposals/luma.png)
- [Tilo](proposals/tilo.png)
- [Bruma](proposals/bruma.png)

El pueblo, con estos tres, pasaría de dos voces a cinco sin sentirse
lleno de clones. No hace falta más por ahora.

---

## Luma

Farolera del anochecer. Persona bajita, pelo ciruela corto, abrigo crema
y un farol de vidrio que enciende cuando el día se apaga.

**Rasgos:** serena, observadora, humor seco.

**Lazo con Orety:** recorre la plaza al caer la tarde para encender los
faroles. Orety dice que, si Luma faltara, se perdería de tanto hablar
después del ocaso. Ella no lo discute; solo llega un poco antes.

**Diálogo propuesto** (mismo tono que `npcs.json`, placeholder `{player}`):

1. «El farol ya está tibio, {player}. Siéntate si quieres. Yo miro.»
2. «De día el pueblo habla solo. De noche me toca a mí escucharlo.»
3. «Orety cree que lo cuido. En realidad cuido que no tropiece con sus propias frases.»
4. «Si el cielo se pone ciruela, no corras. Solo significa que voy a encender.»

---

## Tilo

Aprendiz de carpintero, unos doce años. Piel cálida, pelo rizado recogido,
anteojos redondos, delantal terracota lleno de serrín. Lleva una silla
pequeña como si fuera un tesoro.

**Rasgos:** manitas inquietas, impaciente con lo torcido, generoso.

**Lazo con Orety:** no viene del mito; viene del mueble. Vio que en el
puesto venden una silla sencilla y quiere que la de tu casa sea mejor que
esa. No vende nada (el puesto ya existe). Sueña con un banco a la sombra
de la plaza, «para que Orety tenga donde sentarse cuando se emociona».

**Diálogo propuesto:**

1. «¡No la mires de frente todavía! A esta pata le falta un suspiro.»
2. «La silla del puesto sirve. La mía va a servir y además va a quedar bonita.»
3. «Si me prestas una fibra, te enseño a lijar. Si no, te enseño a esperar.»
4. «{player}, cuando tengas casa de verdad, la silla entra por la puerta. Lo medí.»

---

## Bruma

Espíritu del pozo. Figura delgada de niebla azul-gris, ojos como gotas,
un chal que parece tejido de vaho. No es un fantasma de sábana ni un
aldeano animal: es el agua cuando decide tener voz.

**Rasgos:** pausada, literal, afectuosa en voz baja.

**Lazo con Orety:** vive en el pozo de la plaza. Recuerda cada pez que
alguien se lleva. Cuando el pozo «está tranquilo», es porque Bruma
descansa, no porque esté vacío. Conoce a Orety desde antes de que el
pueblo tuviera nombre; lo llama «el que habla con las flores».

**Diálogo propuesto:**

1. «El agua te oyó llegar, {player}. Yo también, un poco después.»
2. «Los peces no se van. Se dan una vuelta y vuelven cuando dejo de soñar.»
3. «Si hablas bajito, el pozo contesta. Si hablas como Orety, el pozo sonríe y se hace el sordo.»
4. «Puedes llevarte un pez. Deja el silencio. Ese no se vende.»

---

## Notas para integrarlos después

Cuando se decida meterlos al juego, el otro agente puede copiar el patrón
de Mango/Orety en `npcs.json` (`id`, `name`, `description`, `sprite`,
`scale`, `position`, `wander_radius`, `dialogue`). Estas líneas ya usan
`{player}`.

Sugerencia de ancla, solo como idea (no está puesta en la escena):

| id | ancla aproximada | nota |
|---|---|---|
| luma | cerca de un farol de la plaza, de tarde | de noche podría quedarse quieta, como el descanso que ya tienen los NPCs |
| tilo | junto al puesto, sin tapar el área del comercio | no es vendedor |
| bruma | junto al pozo, radio corto | no sustituye la pesca; el pozo sigue entregando peces |

Los PNG de esta carpeta son concept art, no sprites de juego. Si se
integran, conviene recortarlos a un idle transparente del mismo tamaño
relativo que `mango_casual.png` / `orety_idle.png` y, si hace falta,
una hoja de caminar como las de `assets/characters/`.
