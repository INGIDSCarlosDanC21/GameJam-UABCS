# Consolas laterales y contacto de manos

La tienda queda fija junto a la silla: cebo y red a la izquierda, Filtrobot a la
derecha. Las selecciones de modo también están a los lados. La alarma inferior
queda despejada durante la partida. Los controles incluyen carcasa con grosor,
marco metálico, tornillos, ranuras, acentos de color y desplazamiento de pulsación.

En PC, mantén el botón derecho del mouse y arrastra para mirar alrededor.
Q mira a la consola izquierda, E a la derecha y R vuelve al frente.
El clic izquierdo conserva la interacción habitual. Estos movimientos de cámara
están desactivados cuando el visor XR está activo.

En modo de manos, acerca el índice por delante del botón y empuja su superficie.
Un pequeño marcador muestra la punta del dedo detectada. No necesitas hacer pinza.
Retira el dedo para volver a pulsar. Entrar con el dedo ya dentro, perder tracking,
mantenerlo apoyado o tocar un control oculto no debe generar compras. Un intervalo
compartido evita compras dobles por ambas manos y el láser. La interacción a
distancia con manos/mandos continúa disponible.

Implementación: `HandTouchButtons.gd` usa XRHandTracker, la articulación INDEX_FINGER_TIP
y las banderas de posición válida y activamente rastreada. Transforma la punta
desde el espacio XR mediante XROrigin3D y comprueba contacto en el espacio local
del botón. Solo acepta seguimiento real de manos, no articulaciones inferidas
de los mandos. No usa colisiones entre cuerpos ni un viewport adicional.
Referencia: https://docs.godotengine.org/en/stable/classes/class_xrhandtracker.html

`tests/buttons_smoke.gd` simula aproximación, pulsación, retirada, dos manos,
láser y controles ocultos. La simulación valida la lógica, no el tracking óptico:
queda pendiente ajustar alcance y umbrales en un Quest real. Esta entrega no
genera APK ni EXE. Las posiciones están en ShopItem.gd y ModeMenu.gd; son fijas
y pueden ajustarse para la altura de asiento de la instalación.
