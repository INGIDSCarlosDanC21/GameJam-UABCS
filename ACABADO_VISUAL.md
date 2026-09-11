# Acabado del océano y captura

## Cambios

- Cristal de la nave: el material importado `Glass` era negro con alpha 0.8823 y ocultaba el fondo y los indicadores. `CartoonStyle.gd` crea una copia local con alpha 0.035; el GLB original se conserva.
- Arrecife: 48 rocas, 90 ramas de coral y vegetación de alturas variadas (100 plantas en Android, 220 en PC). Rocas, corales y algas usan un MultiMesh por tipo. El entorno completo utiliza cinco nodos de geometría, sin colisiones ni sombras dinámicas propias.
- Materiales: rocas con estratos y reflejos animados, corales de tonos variables y agua animada. Los brillos disminuyen con la profundidad y la salud del océano.
- Cursor: gris en reposo, color de cada mando al señalar, dorado al capturar y anillo segmentado de progreso. Al activar un objeto hace un pequeño destello; las compras rechazadas lo muestran rojo. El progreso desaparece al interrumpir una captura.
- El anillo usa un MultiMesh por puntero. Estos efectos no desplazan la cámara XR.

## Ajustes

### Movimiento de sprites y agua

- **Peces:** `Body Bend` en `InteractableEntity.gd` controla cuánto se dobla el dibujo (0 lo desactiva). El shader ondula las coordenadas de la textura y conserva su contorno; no necesita nuevos PNG ni frames. La cola se mueve más que la cabeza. La anguila tiene mayor flexibilidad. Los giros ocasionales, inclinación y animación siguen el tiempo del juego; al quedar no aptos se detiene la ondulación del cuerpo. La fiebre conserva el avance rápido sin nuevos cambios aleatorios de rumbo.
- **Robots:** `ReefCleaner.gd` interpola el giro horizontal hacia su destino, inclina el sprite al subir/bajar y añade un balanceo pequeño. La calidad, limpieza y duración de 60 segundos siguen funcionando.
- **Caracoles:** entran por debajo de la vista y suben a 0.18 m/s. Reservan posiciones separadas en 15 lugares posibles para el máximo actual de 10 hostiles. Si se suelta uno dentro del área, vuelve hacia un lugar libre. Los que comparten columna entran con separación vertical. La retirada por arrastre sigue funcionando durante la llegada.
- **Agua exterior:** `water_motion.gdshaderinc` desplaza ligeramente la geometría exterior (hasta 1.2 cm por eje), con intensidad gradual detrás de la ventana. Es una aproximación estilizada de ondulación, no refracción óptica de toda la escena. No usa textura de pantalla y no deforma la UI, la cabina ni los caracoles. El colisionador del pez permanece estable, con su margen de captura existente.
- **Interior:** se reduce el sol y se añade `WindowWaterLight`, un foco azul suave hacia el interior. El material gris del submarino y el marco reciben reflejos animados de agua. Los reflejos bajan con salud/profundidad y se apagan durante el bloqueo del pez globo. Las luces siguen el sistema existente de derrota y fiebre. El GLB original no se modifica.

La distorsión exterior es deliberadamente leve para no desalinear la captura. Estos efectos se han ejecutado en PC; la comodidad y coste final se deben comprobar físicamente en Quest.

Referencia técnica: [shaders espaciales de Godot](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html).

La densidad y distribución del arrecife están en `scripts/OceanWorld.gd`. Los materiales están en `shaders/reef_rock.gdshader`, `reef_coral.gdshader`, `kelp.gdshader`, `ocean_floor.gdshader` y `water_surface.gdshader`.

El color base de cada cursor se ajusta con **Pointer Color** en los controladores de `Main.tscn`. La transparencia del cristal se ajusta en la rama `Glass` de `scripts/CartoonStyle.gd`.

## Validación

Pruebas de sesión en PC, con Forward+ y Compatibility, incluyendo cristal, captura parcial y cancelación. Las capturas permiten comprobar la legibilidad desde la cabina. El estilo sigue siendo procedural y estilizado; no es un entorno fotorrealista.

No se han exportado APK ni EXE. Quedan pendientes la medición de rendimiento y la comprobación estereoscópica en Quest 2 y Quest 3. Reducir nodos repetidos no sustituye medir el tiempo de GPU en el visor.
