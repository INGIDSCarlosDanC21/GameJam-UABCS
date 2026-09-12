# Red, descenso y señales visuales

La tienda inferior contiene cebo, red y Filtrobot, fijos en la cabina.
La red tiene cinco mejoras de 15, 30, 45, 60 y 75 monedas. Su factor de rapidez
es `1 + nivel * 0.45`: una captura de 0.8 s baja hasta aproximadamente 0.25 s.
Se mantiene un mínimo de 0.10 s y no afecta a basura, botones ni caracoles.
El progreso de mejora se reinicia con la partida.

Los robots aportan una unidad de progreso y un residuo retirado por cada limpieza,
incluido el paso automático de nivel/profundidad. La limpieza manual conserva
su recompensa de monedas; los robots conservan la recuperación de salud.

Los mandos usan intensidad predeterminada 1.0, pulso de nivel de 0.22 s y pulsos
de descenso de 0.20 s. Un toque de hover no interrumpe un pulso más fuerte.
`Haptic Strength` sigue siendo ajustable en cada mando. Falta probar la sensación
física en Quest; el modo de manos no intenta emitir vibración.

El descenso genera durante 3.5 s una cortina de burbujas 3D situada fuera de la
ventana. El entorno sube y se acerca ligeramente; el seguimiento de la cámara XR
permanece intacto. La traslación acumulada está limitada para evitar que el fondo
alcance las líneas de juego. La primera base de escenarios usa el arrecife inicial,
basalto emergente entre profundidades 1 y 3 y paleta abisal entre 3 y 6. Todavía no
son mapas independientes: esta estructura permite añadirlos después.

Oracle lleva un icono de reloj; al activarlo aparece también en los instrumentos
durante los cinco segundos. El icono desaparece si el pez deja de ser apto.
La fauna decorativa usa óvalos, recorridos en ocho y ondulaciones verticales,
en ambos sentidos, con corrección de orientación del modelo importado.

Se redujeron las estadísticas junto al cursor, la tienda y el panel superior.
Se conservan los objetivos educativos y los resultados de partida para que
la experiencia siga explicando su propósito. Red y reloj son SVG originales.

Pruebas: `tests/net_smoke.gd`, `tests/reef_smoke.gd`, `tests/session_smoke.gd`
y `tests/modes_smoke.gd`. Sin exportaciones APK/EXE.
