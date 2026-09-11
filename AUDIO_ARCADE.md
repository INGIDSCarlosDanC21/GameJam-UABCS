# Dirección sonora: caricaturesca y arcade

## Música y ambiente

La partida utiliza **Going Up** de Ansimuz; la fiebre cambia a **Chiptune Loop - Crazy** de MatiasVME mediante una transición de medio segundo. Ambas son pistas OGG en bucle. La música entra progresivamente al iniciar y se desvanece al terminar. Durante alarmas, compras y cambios de nivel baja temporalmente para dejar oír los avisos.

La contaminación reduce el volumen del mundo y baja ligeramente el tono de la música. La profundidad filtra sus agudos; el pez globo la amortigua aún más. Un motor suave sintetizado acompaña la cabina. El retumbo de descenso continúa en el bus de ambiente.

## Efectos

Los sonidos activos predeterminados proceden del paquete CC0 **Interface Sounds** de Kenney. Captura de peces: nota corta; basura: cristal; botones: clic, confirmación y error distintos. Pez globo, caracoles, niveles y poderes tienen señales propias. Las capturas y clics varían ligeramente su tono para evitar una repetición idéntica.

Los robots, la llegada de caracoles y las explosiones usan fuentes 3D. La alarma de dos notas nace junto al botón inferior y tiene su propio reproductor, sin competir con otros efectos. Los caracoles no emiten sonido continuamente mientras están pegados al cristal.

Hay límites de simultaneidad: ocho voces generales, dos de interfaz y cuatro espaciales, más una voz independiente de alarma. Las repeticiones rápidas se limitan por evento; el feedback de compras puede reemplazar otra voz de interfaz si ambas están ocupadas.

## Ajustar desde Godot

1. Abre `Main.tscn` y selecciona `SoundHub/AudioDirector`.
2. Ajusta **Music Volume Db** (predeterminado -20) y **Ambience Volume Db** (-28).
3. Para sustituir canciones, arrastra OGG a **Expedition Music** y **Fever Music**. El director activa su bucle sobre una copia del recurso.
4. En `SoundHub`, puedes sustituir **Button Touch**, **Button Success**, **Button Error**, **Explosion** y **Alarm** por otros AudioStream. Dejar un campo vacío conserva el sonido arcade predeterminado.
5. Abre el panel Audio: `Music`, `Ambience` y `SFX` envían a `World`; `UI` y `Alarm` envían directamente a `Master`. La salud modifica `World`, por lo que las alarmas y los controles siguen siendo claros. El volumen elegido para `Master` se respeta.
6. `Music` contiene un filtro y `Master` un limitador con techo de -1 dB. No añadas una segunda copia del antiguo pitch shift global: ahora el tono se controla en los reproductores de música/ambiente.

Para un nuevo sonido espacial, emite `GameManager.sound_at_requested.emit("robot", posicion_global)` usando un nombre definido en `SoundHub.gd`. Para UI o avisos, utiliza `sound_requested`.

## Recursos y permisos

- [Going Up — Ansimuz](https://opengameart.org/content/going-up-adventure-chiptune), CC0 en su página; licencia del paquete conservada.
- [Chiptune Loop - Crazy — MatiasVME](https://opengameart.org/content/chiptune-loop-crazy), CC0.
- [Interface Sounds — Kenney](https://kenney.nl/assets/interface-sounds), CC0.

Los detalles, nombres originales y archivos de licencia están en `assets/audio/arcade/licenses`. El motor y la alarma son síntesis propia del proyecto. Los archivos de audio anteriores se conservan, pero no se cargan de forma predeterminada y están excluidos de los presets de exportación. Si vuelves a asignarlos, revisa sus permisos y el filtro del preset.

## Comprobación

`tests/audio_smoke.gd` comprueba bucles, transiciones, aislamiento de alarmas/UI, efectos espaciales y reinicio. Graba seis segundos de la mezcla real en `.godot/arcade-audio-preview.wav` y mide su pico. `tests/session_smoke.gd` verifica las mecánicas generales.

No se generaron APK ni EXE. Falta la escucha de balance y localización física en Quest 2/3; una prueba en PC no valida los altavoces ni la comodidad sonora del visor.
