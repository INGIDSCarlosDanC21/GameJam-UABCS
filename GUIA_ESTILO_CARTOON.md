# Estilo cartoon y catálogo de arte

Los diez PNG de assets/art se asignan automáticamente por su nombre original, incluidos los nombres anginla e inferiror. No se encontraron otras carpetas llamadas sprites. No se modifican los dibujos: Sprite3D usa la región con alpha y una caja individual ajustada. El cálculo de regiones se almacena en caché por textura. Los sprites están alineados al plano frontal del juego.

- Pez azul y naranja: comunes, pesos 40 y 30.
- Anginla: poco común, peso 18, mayor longitud y velocidad.
- Anginla enojada: rara, peso 10, más rápida; es una variante independiente.
- Pez dorado millonario: legendario, peso 2, brillo dorado y movimiento lento.
- Botella rota inferior/superior, lata, montón de basura y soporte de cerveza: basura, seleccionada uniformemente. El montón es más ancho.

Los pesos de peces suman 100. Tamaños 0.75, 1 y 1.5 con igual probabilidad. Rarezas multiplican dinero y daño por 1, 2, 4 y 8. El cebo no puede eliminar toda la basura del spawner.

CartoonStyle.gd aplica Toon a materiales opacos StandardMaterial3D del submarino conservando sus texturas. Los transparentes, como cristales, se conservan. El contorno usa geometría expandida (ink_outline.gdshader); evita efectos de pantalla dependientes de una sola cámara. Dos luces sin sombras dinámicas añaden relleno cálido y azul. El contorno añade un pase de dibujo por superficie opaca; medir rendimiento en el visor.

sprite_ink.gdshader dibuja borde negro a partir del alpha con nueve muestras. Mantiene los colores pintados y añade emisión moderada según rareza. No depende de bloom. Los márgenes vacíos se excluyen en ejecución, conservando los PNG originales.

scenes/AmongUs.tscn es una figura 3D editable hecha de cápsulas, esfera y mochila, basada en amongus.png. No es una reconstrucción automática exacta del dibujo. Main contiene AmongUsEasterEgg en Cabin, como figura pequeña al lado derecho de la consola. Selecciona ese nodo para moverlo en el Inspector. La escena independiente puede reutilizarse en otros lugares.

Validación: importación, ejecución y render Vulkan en PC. Comprobar en visor que las líneas no parpadeen y que la figura quede bien situada respecto a la cabina y tu altura real.