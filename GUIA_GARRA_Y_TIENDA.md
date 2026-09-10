# Garra, profundidad, tienda y música

## Controles
- VR: apuntar con la mano derecha y mantener trigger_click hasta completar el agarre. Soltar o perder alineación reinicia el progreso.
- PC: mover el ratón y mantener clic izquierdo. No hace falta casco.
- Después de cada captura o compra, soltar y volver a pulsar; hay 0.65 s de recuperación para evitar acciones duplicadas.

El hueso tiene dos extremos móviles que se cierran al pulsar. El rayo sigue la dirección con retraso suave y la figura sigue su punto con un resorte amortiguado. Para capturar debe estar a menos de 0.18 m del punto del impacto. La cámara VR conserva seguimiento directo, sin inercia.

En RightController se pueden ajustar stiffness (65), damping (15) y max_speed (7 m/s). Más damping amortigua la oscilación; más stiffness hace que alcance antes el objetivo. Eliminar el retraso de la cabeza es intencional: solo tiene peso la garra.

## Peces y estadísticas
Tres franjas de profundidad: aproximadamente 2.5, 3.9 y 5.6 metros. Conservan tamaño físico: los más lejanos se ven menores. Se añade un movimiento suave en Y y Z; la rareza aumenta la frecuencia y amplitud vertical. Siguen siendo sprites planos en un espacio 3D, no mallas volumétricas.

Al apuntar se muestran especie, rareza, monedas, daño, velocidad, tiempo de agarre y profundidad. GameManager.fish_stats() es la fuente compartida para el pago y la ficha. El tiempo de agarre es 0.35 + rareza * 0.14 + (tamaño - 0.75) * 0.2 segundos; basura 0.25 s. El tiempo de vida cubre unos seis metros de recorrido para no castigar solo a los peces lentos.

## Botones
Panel azul oscuro y borde negro, resaltado al apuntar, gris si falta dinero, verde al comprar y rojo al fallar. La caja de interacción corresponde al fondo. Los paneles se sitúan frente a la cámara a 1.5 m para poder probarlos en PC; su colocación se configura en ShopItem._ready().

## Música
El MP3 suministrado de UnderWater World Theme se reproduce en AmbientAudio en bucle, con entrada de 2.5 segundos y volumen -14 dB. Pasa por Master: el sistema existente de salud reduce el volumen y el tono cuando el océano empeora. Es una sola pista dinámica por procesamiento, no tres composiciones separadas. Su ruta está en Main._setup_music().

## Validación
Render Vulkan en PC sin errores de scripts. Prueba controlada de objetivo frente al rayo: captura completada, monedas abonadas una sola vez; comprobados cálculo de estadísticas, capas fantasma y reproductor musical en bucle. Falta ajustar sensación de peso y legibilidad en el visor real.