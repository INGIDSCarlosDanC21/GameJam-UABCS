# Manos y mandos en Quest

## Controles

- Ambos mandos funcionan a la vez: apunta con el cursor y mantén el gatillo para capturar o comprar. El cursor izquierdo es azul y el derecho verde.
- Sin mandos: activa el seguimiento de manos en los ajustes del visor. Apunta con la mano y junta índice y pulgar; mantén la pinza hasta llenar la barra de captura. Se utilizan los perfiles de interacción OpenXR del visor.
- Para retirar un caracol, captúralo, arrástralo hacia fuera de la vista y suelta el gatillo o la pinza. Cada caracol queda asociado al puntero que lo tomó.
- En PC sin VR se conserva el ratón y clic izquierdo; el segundo cursor se oculta.

La representación actual de cada mano es su cursor, no un modelo de mano articulada. La disponibilidad y el cambio entre manos y mandos dependen del runtime del visor; no se exige usar una mano desnuda y un mando simultáneamente.

## Vibración

Hay pulsos suaves al señalar objetos, activar una captura y descender. En `Main.tscn`, selecciona `XROrigin3D/RightController` o `LeftController` y ajusta **Haptic Strength** (0 desactiva, 1 intensidad completa; predeterminado 0.5). Las manos desnudas conservan el feedback visual, sin vibración.

## Preparación Android

Se incluye Godot OpenXR Vendors **5.1.0-stable**, con sus licencias, en `addons/godotopenxrvendors`. Requiere Godot 4.6 o posterior. La GDExtension se carga al importar el proyecto; no necesita un `plugin.cfg`.

El preset **Meta Quest** habilita el complemento Meta, Gradle y seguimiento de manos opcional, permitiendo seguir jugando con mandos. El proyecto habilita hand tracking y los perfiles EXT y Microsoft de interacción manual; este último cubre el runtime nativo de Meta.

**No se ha generado ningún APK ni EXE con estos cambios.** El APK anterior no contiene estas funciones. Cuando se autorice exportar, habrá que instalar la plantilla de compilación Android correspondiente a la versión de Godot, completar el SDK Android requerido por esa plantilla y comprobar el preset Meta Quest. La configuración anterior sin Gradle no incorpora el complemento de Meta.

## Validación pendiente en visor

Las pruebas automáticas en PC comprueban los dos punteros, que un pez no se cobre dos veces, el resaltado compartido y la propiedad del caracol. No sustituyen las pruebas físicas.

Cuando se autorice una versión de prueba, verificar en Quest 2 y Quest 3:

1. Capturar peces distintos con ambos mandos y sentir los pulsos en el lado correcto.
2. Señalar el mismo botón con ambos cursores y retirar uno: debe seguir resaltado.
3. Dejar los mandos, activar manos y capturar/comprar mediante pinza con cada mano.
4. Arrastrar y soltar caracoles con cualquiera de las manos.
5. Ocultar una mano: su cursor debe desaparecer y la captura interrumpirse. Volver a mostrarla y comprobar recuperación.
6. Reiniciar la partida y alternar de nuevo entre mandos y manos.

La vibración, precisión de la pinza y transición de fuentes aún no están verificadas en hardware. El seguimiento de manos por Link depende del runtime y no equivale a probar la versión nativa.

## Referencias

- [Seguimiento de manos en Godot](https://docs.godotengine.org/en/stable/tutorials/xr/openxr_hand_tracking.html).
- [Extensiones de manos de Meta](https://godotvr.github.io/godot_openxr_vendors/manual/meta/hand_tracking.html).
- [Distribución oficial del complemento](https://github.com/GodotVR/godot_openxr_vendors/releases/tag/5.1.0-stable).
