# Variantes de color de peces

Los peces azules y naranjas reciben al aparecer uno de cuatro patrones: rayas,
puntos, degradado o manchas, con seis paletas base y una fase aleatoria estable.
El efecto sigue las mismas coordenadas que la deformación de nado y no cambia
de color cada frame. Conserva el alfa, los trazos negros y las zonas blancas.

En InteractableEntity, **Color Variety** controla la intensidad (0 desactiva el
efecto; predeterminado 0.7). **Color Pattern** permite elegir un patrón concreto
o dejarlo aleatorio. La paleta está en `_setup_color_pattern()`.

No cambia monedas, daño, rareza ni tiempo de captura. Las especies especiales
conservan su aspecto y el efecto se desactiva al pasar a no apto. Los peces 3D
decorativos del fondo conservan sus materiales originales.

Implementado en `shaders/sprite_ink.gdshader`, sin texturas adicionales ni nuevos
draw calls. `tests/fish_patterns_smoke.gd` genera una muestra en
`.godot/fish-patterns.png`. Pendiente revisión visual en el visor real.
