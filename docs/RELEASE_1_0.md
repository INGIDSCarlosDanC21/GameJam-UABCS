# Ocean VR 1.0 — candidata de cierre

La numeración visible se unifica como `1.0.0-rc2`. Android conserva un versionCode creciente (7) para que los APK de prueba sigan actualizándose. RC significa candidata: no declara completadas las pruebas manuales ni los permisos de los recursos.

## Comprobaciones técnicas

Se ejecutaron las pruebas de audio, botones, asignación de robots, expansión de profundidad, equilibrio ecológico, extras, variantes, linterna, fauna, modos, red, pausa, rendimiento, calidad de vida, alarma, arrecife, investigación, sesión, telemetría y rotación del abismo. Las pruebas históricas de audio, precios y fauna se actualizaron para reflejar el tutorial, los precios actuales, las transiciones suaves y la fauna limitada por profundidad.

La prueba de persistencia usa dos procesos independientes y un archivo de prueba: verifica ajustes, descubrimientos y una imagen PNG después de volver a abrir el programa. La prueba gráfica de investigación verifica una fotografía renderizada y los menús.

PC, escena de carga a 20 km: Compatibility p95 11.821 ms, Forward+ p95 11.798 ms en el equipo de desarrollo. Son pruebas de escritorio, no mediciones de PCVR.

## Prueba del Quest

`ReleaseSoak.gd` sólo se activa en compilaciones debug cuando existe `user://qa_soak.flag`. Consume la bandera al arrancar, usa práctica y un archivo de progreso separado, crea 30 robots y alterna tormentas. Recorre profundidades altas durante 300 segundos de simulación y escribe `user://qa_soak.log`. El avance normal puede aumentar la profundidad dentro de cada tramo. No se activa en una compilación release. El usuario debe mantener la aplicación activa en el visor.

Resultado completado el 13 de septiembre: 300 segundos de simulación, 59 muestras cada cinco segundos, profundidad observada hasta 48 km, máximo 42 entidades además de 30 robots. Mediana 70 FPS, mínimo observado 50, máximo 73. No equivale a 72 FPS constantes. Memoria estática de Godot entre 74.7 y 79.9 MB; la memoria total del proceso (PSS) pasó aproximadamente de 953 MB a 1057 MB durante calentamiento. Esto no demuestra ausencia de fugas en sesiones largas. No se registró un cierre inesperado; el cierre final fue solicitado por la prueba.

Los registros y resúmenes de cada ejecución se conservan localmente en `.godot/release-qa/`. Una pausa o suspensión no cuenta como una sesión completa.

## Firma y distribución

`tools/build_release.ps1` recibe la ruta a Godot y un JSON privado con `path`, `alias` y `password`. Usa las variables de entorno de exportación de Godot; no escribe contraseñas en el preset ni las imprime. Genera APK release, exportación Windows y SHA256SUMS en `export/release/`.

La clave de firma propia y sus credenciales están fuera del repositorio, en la carpeta privada `.ocean-vr-signing` del usuario de Windows. Hay que respaldar esa carpeta en almacenamiento privado: perderla impide firmar actualizaciones con la misma identidad. Nunca subirla a GitHub.

El APK release tiene una firma distinta a las pruebas debug ya instaladas. No se instala encima de ellas ni se desinstala automáticamente: primero se deben respaldar fotos y progreso y acordar una migración. El APK debug conserva la continuidad de la instalación actual.

## Pendientes de aceptación

- La sesión Quest de 300 segundos está completada. Quedan caídas puntuales hasta 50 FPS y falta una sesión humana prolongada para aceptar la estabilidad térmica y de memoria.
- El usuario confirmó comodidad en VR tanto con mandos como sin mandos. Quedan por comprobar explícitamente suspensión y retirada/colocación del visor.
- El usuario confirmó PCVR real funcionando bien, sin tirones perceptibles o constantes.
- Autor, fuente exacta y permisos de los recursos originales identificados como Seatruck/Subnautica, FNAF 3, Deltarune y sprites aportados. Los créditos no sustituyen una licencia. Ver `assets/CREDITS.txt`.
- Passthrough/realidad aumentada queda fuera del alcance de 1.0; el almanaque ofrece visualización 3D dentro del juego.

No crear una etiqueta `v1.0.0` definitiva mientras queden pendientes de aceptación. La candidata puede conservarse como `v1.0.0-rc2`.

## Revisión RC2

Tutorial reducido a dos acciones reales (limpiar y comprar un robot), seguido de ayudas contextuales breves con marcadores sobre objetos. Reiniciar ocupa una fila separada encima de Pausa, sin coincidir con la cámara ni Diario/Ajustes. Confirmación visual en escritorio y pruebas automáticas de separación, reinicio, tutorial y referencias eliminadas.

Los paquetes actualizados se generan en `export/release/1.0.0-rc2/`, con ZIP de Windows, APK firmado, créditos, notas y sumas SHA256. El visor está desconectado: esta exportación no equivale a una nueva prueba ni instalación en Quest.

La revisión local confirma que el submarino Seatruck sigue referenciado por Main.tscn y que SoundHub conserva los audios originales como alternativas de carga. No se han inventado permisos ni sustituido el arte principal sin recursos equivalentes. Sigue pendiente la aceptación del último tutorial y la disposición del botón en el visor.

## Demo para presentación

El usuario aprobó el funcionamiento de RC2. Se prepara `1.0.0-demo` (Android code 8) para evaluación del cliente, con los mismos sistemas jugables aprobados. No es una certificación de derechos para comercializar o reutilizar los recursos; permanecen los créditos y pendientes arriba.
