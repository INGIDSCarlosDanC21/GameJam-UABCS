# Ocean VR — Quest 2

El preset `Meta Quest` genera una aplicación Android ARM64 nativa con OpenXR y el proveedor Meta. Incluye interacción con controladores y seguimiento de manos opcional. La configuración base usa el renderizador Compatibility; Windows conserva Forward+. El código limita fauna y luces adicionales en Android.

## Compilar e instalar

1. Usar Godot 4.7.2 con sus plantillas de exportación de la misma versión.
2. Configurar Java y Android SDK en Editor Settings > Export > Android. Instalar las plataformas y herramientas indicadas por la plantilla (API 36, Build Tools 36.1.0 en esta versión).
3. En Project > Install Android Build Template, instalar la plantilla Gradle. `android/` es generado y no se versiona.
4. Ejecutar `tools/build_quest.ps1 -Godot "ruta/al/godot.exe"`. Produce `export/quest/OceanVR-Quest2.apk`, firmado para pruebas, no para publicar en la tienda.
5. Con Quest 2 en modo desarrollador y autorización USB aceptada, añadir `-Install -Adb "ruta/al/adb.exe"`, o instalar el APK mediante SideQuest.

## Comprobación en el visor

La compilación no sustituye pruebas físicas: comprobar ambos ojos, altura sentado, manos/controladores, botones de compra y pausa, audio, alarma al 50 %, fotografías y fluidez a profundidad 20–30. No se ha conectado un Quest durante esta entrega.

## Modelos y futura realidad aumentada

`SpeciesCatalog.model()` devuelve modelos centrados y normalizados, y `MarineMaterials.prepare()` conserva los materiales y texturas independientes de cada superficie sin modificar los recursos originales. Se pueden reutilizar fuera del escenario submarino. El almanaque actual muestra una vista 3D dentro de VR; todavía no activa passthrough ni representa la habitación real. Oracle mantiene un aviso de modelo pendiente.

Para un modo de realidad aumentada real falta integrar y probar el blend alpha de OpenXR y passthrough Meta, ocultar el entorno submarino durante esa vista y restaurarlo al cerrarla. En Quest 2 el passthrough es monocromo. Referencias: [Godot Android XR](https://docs.godotengine.org/en/stable/tutorials/xr/deploying_to_android.html), [passthrough](https://docs.godotengine.org/en/stable/tutorials/xr/ar_passthrough.html).
