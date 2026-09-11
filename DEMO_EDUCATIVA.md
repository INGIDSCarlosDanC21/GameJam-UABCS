# Preparación de la experiencia educativa

## Versión de trabajo

Esta revisión incorpora instrumentos de salud animados, marco fijo de observación, partículas ambientales, iconos recortados y un resumen de impacto al terminar. Conserva el control de ratón, los botones fijos y el arranque sin tutorial.

La versión entregada en la Game Jam está en el commit `0867a63`. Los ejecutables de la raíz corresponden a esa entrega hasta que se vuelvan a exportar. Para probar esta revisión desde el editor, abrir `project.godot` y ejecutar la escena principal.

## Guion breve

La expedición tiene un límite de cinco minutos. Sus objetivos son retirar 15 residuos (manualmente o con robots), desplegar al menos un Filtrobot y después mantener salud de 70% o más durante 30 segundos consecutivos. Bajar de ese umbral reinicia la racha. Es posible ganar antes del límite; agotarlo muestra un cierre de misión incompleta. Llegar a cero de salud conserva la derrota por contaminación.

Un pequeño arrecife geométrico recupera color y altura conforme aumenta la limpieza y se conserva la salud. Es una representación simbólica: no reproduce los tiempos reales de recuperación coralina.

La revisión de misión pasó 39 comprobaciones en Godot desde el editor, incluida victoria, límite de tiempo y reinicio. No se exportaron APK ni ejecutables para esta revisión, por petición del equipo.

1. Observar la salud inicial y retirar residuos: cada objeto retirado cuenta en el resumen.
2. Capturar peces y comparar el ingreso económico con el cambio de salud.
3. Comprar un Filtrobot y observar cómo automatiza parte de la limpieza.
4. Comparar las consecuencias de limpiar y de dejar residuos en el agua.
5. Al terminar, discutir las decisiones usando los residuos retirados y peces capturados del resumen.

Las reglas son una metáfora educativa, no un modelo científico. La fiebre de peces, Oracle, la anguila y el pez globo son elementos de fantasía del prototipo. Antes de una presentación educativa conviene explicitar esta distinción al público.

## Validación

Pruebas ejecutadas en Godot 4.7.2 con render Vulkan en PC: 31 comprobaciones, sin fallos. Cubren economía, contaminación, evolución de Filtrobots, descenso, Oracle, peligros, derrota y reinicio. Se revisaron capturas del inicio y final de partida.

Pendiente de validación física: lectura, alcance de botones, altura de usuario y rendimiento en Quest 2 y Quest 3. No se ha medido todavía la tasa de fotogramas en estos visores. La exportación existente es para Windows/OpenXR; no equivale a un APK autónomo de Quest.

## Antes del lunes

- Confirmar si se usará PC con Link/Air Link o instalación autónoma en Quest.
- Probar una expedición completa en el Quest 2 disponible, incluyendo reinicio.
- Revisar con una persona nueva si identifica el objetivo ambiental sin explicación extensa.
- Confirmar el tiempo de demostración y el público para ajustar dificultad y contenidos.
