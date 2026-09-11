# Ocean VR — prueba autónoma en Quest

Se generó `export/quest/OceanVR.apk` con Godot 4.7.2. Es una compilación de depuración firmada para instalación local, no una publicación en la tienda Meta.

## Estado verificado

- Exportación y verificación de firma terminadas correctamente.
- Paquete `org.oceanvr.education`, versión `1.1.0-quest-preview`.
- Arquitectura ARM64 y argumento de arranque `--xr_mode_openxr` presentes en el APK.
- Android usa Compatibility/OpenGL; Windows conserva Forward+.
- Efecto de fiebre/aturdimiento alternativo sin lectura de pantalla en Android. El aturdimiento oscurece la vista; no aplica el blanco y negro de PC.
- 40 partículas ambientales en Android y sin segunda pasada de contornos del submarino.

No se ha probado en un visor físico: ADB no detectó dispositivos conectados. Quest 2 y Quest 3 son los objetivos, no dispositivos ya certificados por estas pruebas. La altura de cámara, controladores y rendimiento deben verificarse en tu Quest 2.

## Instalar desde este equipo

1. Activa el modo desarrollador del Quest desde la configuración de Meta y conecta el visor al PC mediante USB de datos.
2. Dentro del visor, acepta la autorización de depuración USB para este equipo.
3. Abre PowerShell en la carpeta del proyecto y ejecuta:

```powershell
& '.godot/quest-tools/sdk/platform-tools/adb.exe' devices
& '.godot/quest-tools/sdk/platform-tools/adb.exe' install -r 'export/quest/OceanVR.apk'
```

Si aparece `unauthorized`, acepta la autorización en el visor. Si hay varios dispositivos, usa `adb -s SERIAL install -r ...` para elegir el Quest correcto. Abre Ocean VR desde la biblioteca de aplicaciones de origen desconocido; la ubicación de esa sección depende de la versión de Horizon OS.

Para obtener un registro después de probar:

```powershell
& '.godot/quest-tools/sdk/platform-tools/adb.exe' logcat -d > 'export/quest/quest-log.txt'
```

## Primera prueba

Comprueba que la aplicación entra en VR, muestra ambos ojos correctamente y permite apuntar, capturar, comprar y reiniciar. Prueba fiebre, Oracle y aturdimiento. Observa si los botones fijos se alcanzan sentado y si hay tirones con diez robots y muchos peces.

## Reconstruir el APK

Godot tiene configuradas las rutas del SDK local en `.godot/quest-tools/sdk` y del JDK instalado. La clave de depuración está en `.godot/quest-tools/debug.keystore`; no se incluye en Git. Antes de exportar por terminal establece:

```powershell
$env:GODOT_ANDROID_KEYSTORE_DEBUG_PATH = "$PWD/.godot/quest-tools/debug.keystore"
$env:GODOT_ANDROID_KEYSTORE_DEBUG_USER = 'androiddebugkey'
$env:GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD = 'android'
```

Exporta el preset **Meta Quest** con depuración activada. Conserva esa clave para poder actualizar la instalación de prueba sin cambiar la firma. La caché `.godot` y el APK no están versionados.

La ruta genérica OpenXR de Godot 4.7 permite esta prueba sin el plugin de fabricantes. Antes de distribuir en la tienda, revisar el plugin OpenXR Vendors y sus ajustes específicos de Meta.

Referencia: https://docs.godotengine.org/en/stable/tutorials/xr/deploying_to_android.html
