# Arrecife 3D — guía de ajuste

El fondo utiliza modelos descargados de Quaternius, MiniPoly, Poly by Google y
Device Lab. Consulta [fuentes y licencias](assets/models/reef/CREDITS.txt).
Todos los modelos están guardados en el proyecto: jugar no requiere conexión.

## Composición y movimiento

`Main.gd` crea `OceanWorld`, que añade `ReefLife`. El canal central queda libre de
plantas cercanas; las algas, corales y rocas forman grupos laterales y un fondo más
lejano. El cielo submarino es continuo y sustituye el antiguo plano de superficie.

- Tres bancos de peces con esqueletos y clips originales `Swim`.
- Una mantarraya y delfines en recorridos más lejanos.
- Trayectorias elípticas sin desapariciones en los extremos. La orientación sigue
  la tangente del recorrido y añade una inclinación leve en los giros.
- Algas con raíces quietas y puntas que oscilan. Cada planta lleva una fase distinta.
- Corales con movimientos muy pequeños, paleta cálida y reflejos de agua.
- La iluminación disminuye con la profundidad y la salud del ecosistema.

La fauna del fondo es decorativa: no tiene colisiones, no intercepta el puntero,
no da monedas y no participa en el sistema de peces no aptos.

## Ajustes para arte

En `scripts/ReefLife.gd`, `_plant_model` controla la cantidad, posición y altura de
la vegetación. `_swimmer` recibe el largo en metros, centro del recorrido, radios,
fase y velocidad angular. Los modelos se normalizan automáticamente usando sus
dimensiones; no es necesario modificar los FBX/GLB originales.

Para variar el nado cambia la velocidad del recorrido y el `speed_scale` del clip.
Los recorridos deben mantenerse detrás de z=-8 para conservar la separación con
los sprites jugables. El shader `reef_model.gdshader` controla el balanceo y el
color; `sway` está expresado en metros. Evita grandes amplitudes en los corales.

Los GLB tienen desactivada la generación de LOD: son modelos de pocos polígonos,
y las mallas diminutas originales ampliadas con MultiMesh perdían su silueta con
los LOD automáticos. Conserva sus archivos `.import` en el repositorio.

## Presupuesto y comprobación

PC: 27 peces pequeños, una mantarraya y dos delfines. Quest: 15 peces pequeños,
una mantarraya y un delfín. La vegetación se agrupa con MultiMesh, con menos
instancias en Android. Los modelos decorativos no proyectan sombras dinámicas.
El cielo no recalcula un cubemap animado por cada frame.

`tests/reef_smoke.gd` comprueba clips, población, cinco minutos de trayectorias,
separación del juego, oscuridad por salud/profundidad y presupuesto reducido.
Genera capturas en `.godot/reef-shallow.png`, `reef-deep.png` y
`reef-unhealthy.png`. Se debe completar la revisión de rendimiento y comodidad
en Quest 2 real antes de distribuir. No se ha generado APK ni EXE para este cambio.

Validación del 11/09/2026: pruebas del arrecife sin errores en Compatibility
(OpenGL) y Mobile (Vulkan) sobre PC. También pasaron las pruebas de partida y
selección de modos, incluida la apertura y cierre de créditos. Esto no sustituye
una medición en el visor.
