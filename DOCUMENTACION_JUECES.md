# Ocean VR: Guardianes de la Profundidad

**Game Jam UABCS · Prototipo inmersivo en Godot 4.7 · 10 de septiembre de 2026**

## Propuesta

Ocean VR sitúa a la persona jugadora dentro de una cabina submarina. Con un puntero XR captura residuos, administra una economía limitada y decide qué peces capturar. Cada decisión modifica la Salud del Océano, que afecta la iluminación, el audio y la posibilidad de continuar la partida.

La experiencia traduce dos problemas ambientales en reglas claras: retirar basura recupera el ecosistema, mientras que capturar peces valiosos produce dinero pero puede empeorar el océano. El objetivo no es únicamente conseguir monedas, sino sostener el ecosistema para llegar más profundo.

## Cómo jugar

1. Apunta con el mando derecho y mantén el gatillo para capturar. En PC, el ratón permite probar la misma interacción sin casco.
2. Limpia basura para recuperar Salud del Océano y ganar monedas.
3. Captura peces para obtener dinero. Los peces grandes, raros y con aura dorada pagan más, pero son más lentos de capturar y dañan más el ambiente.
4. Compra cebo para aumentar recompensas o compra Filtrobots para automatizar la limpieza.
5. Cada seis acciones se avanza de nivel. Cada cinco niveles la cabina desciende automáticamente y el Filtrobot evoluciona.

## Sistemas de juego

| Sistema | Función y relación con el tema |
|---|---|
| Salud del Océano | Va de 100 a 0. Al bajar, el mundo se oscurece, el audio pierde volumen y tono, y se activa una alarma. A 0 termina la partida. |
| Economía | Las monedas permiten comprar mejoras. El precio de filtros aumenta con la profundidad, por lo que limpiar a tiempo importa. |
| Filtrobots | Hasta diez unidades activas. Nivel 1 limpia con ritmo base; nivel 2 mejora velocidad y enfriamiento; nivel 3 es el más eficiente. Todos producen burbujas y explotan al terminar 60 segundos. |
| Evolución del Filtrobot | Nivel 1: niveles 1–4. Nivel 2: desde el nivel 5. Nivel 3: desde el nivel 10. Los robots activos también se actualizan. |
| Profundidad | Aumenta cada cinco niveles. Oscurece el entorno y aumenta basura, caracoles y tamaño/valor de peces. |
| Riesgos | La basura vuelve no aptos a los peces. Los caracoles bloquean la vista hasta ser arrojados fuera. La anguila enfadada contamina peces cercanos. El pez globo aturde y apaga las luces temporalmente. |
| Evento de foca | La foca activa Fiebre de Peces: un evento temporal, dorado y muy visible con peces rápidos y doble recompensa. |
| Pez Oracle | Desde la primera profundidad puede aparecer. Al capturarlo ralentiza durante cinco segundos peces, basura, peligros, robots y aparición de entidades, dando un breve respiro táctico. |

## Diseño audiovisual

El fondo utiliza un entorno oceánico 360 y la cabina procede de un modelo submarino. Los sprites 2D se integran mediante `Sprite3D`, profundidad simulada, iluminación por rareza y una estética de contornos de dibujo animado. Los efectos de luz, viñeta, alarmas, burbujas y monedas visibles comunican cambios del sistema sin depender de menús planos.

## Tecnología y accesibilidad

- Motor: Godot 4.7, GDScript y OpenXR.
- XR: `XROrigin3D`, `XRCamera3D`, `XRController3D` y `RayCast3D`.
- Prueba sin visor: la cámara y el ratón replican el puntero.
- Rendimiento: peces, basura y peligros usan `Area3D` fantasma. No colisionan entre sí; solo son detectados por el puntero. Los objetos que salen de vista y los efectos temporales se liberan.
- UI: los indicadores esenciales y alarmas son geometría 3D integrada a la cabina, legible dentro del visor.

## Recorrido recomendado para la demostración

1. Recoger basura para mostrar recuperación de salud y monedas.
2. Capturar un pez raro y observar la moneda que vuela al contador.
3. Comprar un Filtrobot y dejar que limpie basura automáticamente.
4. Mostrar una bajada de salud para activar oscuridad y alarma.
5. Alcanzar nivel 5 para enseñar el descenso y la evolución del robot.

## Controles

- **VR:** mando derecho, puntero láser y gatillo.
- **PC:** ratón para apuntar e interactuar.
- **Reinicio:** aparece al agotarse la Salud del Océano.

## Estructura relevante

- `autoload/GameManager.gd`: economía, progresión, salud y audio global.
- `scripts/InteractableEntity.gd`: peces, basura, foca, rareza y estados no aptos.
- `scripts/OceanSession.gd`: iluminación, riesgos, profundidad y efectos de sesión.
- `scripts/ReefCleaner.gd`: movimiento, limpieza, evolución visual y burbujas del Filtrobot.
- `scenes/Main.tscn`: cabina, controles XR, tienda, mundo y recursos visuales.
