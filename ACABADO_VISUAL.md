# Acabado del océano y captura

## Cambios

- Cristal de la nave: el material importado `Glass` era negro con alpha 0.8823 y ocultaba el fondo y los indicadores. `CartoonStyle.gd` crea una copia local con alpha 0.035; el GLB original se conserva.
- Arrecife: 48 rocas, 90 ramas de coral y vegetación de alturas variadas (100 plantas en Android, 220 en PC). Rocas, corales y algas usan un MultiMesh por tipo. El entorno completo utiliza cinco nodos de geometría, sin colisiones ni sombras dinámicas propias.
- Materiales: rocas con estratos y reflejos animados, corales de tonos variables y agua animada. Los brillos disminuyen con la profundidad y la salud del océano.
- Cursor: gris en reposo, color de cada mando al señalar, dorado al capturar y anillo segmentado de progreso. Al activar un objeto hace un pequeño destello; las compras rechazadas lo muestran rojo. El progreso desaparece al interrumpir una captura.
- El anillo usa un MultiMesh por puntero. Estos efectos no desplazan la cámara XR.

## Ajustes

La densidad y distribución del arrecife están en `scripts/OceanWorld.gd`. Los materiales están en `shaders/reef_rock.gdshader`, `reef_coral.gdshader`, `kelp.gdshader`, `ocean_floor.gdshader` y `water_surface.gdshader`.

El color base de cada cursor se ajusta con **Pointer Color** en los controladores de `Main.tscn`. La transparencia del cristal se ajusta en la rama `Glass` de `scripts/CartoonStyle.gd`.

## Validación

Pruebas de sesión en PC, con Forward+ y Compatibility, incluyendo cristal, captura parcial y cancelación. Las capturas permiten comprobar la legibilidad desde la cabina. El estilo sigue siendo procedural y estilizado; no es un entorno fotorrealista.

No se han exportado APK ni EXE. Quedan pendientes la medición de rendimiento y la comprobación estereoscópica en Quest 2 y Quest 3. Reducir nodos repetidos no sustituye medir el tiempo de GPU en el visor.
