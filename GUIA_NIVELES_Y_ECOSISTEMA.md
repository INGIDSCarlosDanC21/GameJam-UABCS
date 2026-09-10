# Niveles, foca, limpieza y profundidad

## Jugar y ajustar dificultad

Los peces normales empiezan a 0.23 m/s y las anguilas a 0.32 m/s. El agarre inicial tarda unos 0.16–0.27 s y admite 0.30 m de separación entre el hueso y el punto del rayo. La garra gris conserva una inercia más ligera, cierra sus extremos y muestra una barra verde de progreso.

Cada seis capturas o limpiezas manuales sube un nivel. La dificultad aumenta 5 % por nivel y 12 % por descenso, con límite 2.3. La tienda y robots no dan experiencia automáticamente. Cambia estos valores en GameManager.difficulty(), progress() e InteractableEntity._ready().

## Foca y fiebre

La primera foca puede aparecer tras 12 segundos; después, cada 28 segundos aproximadamente. Al capturarla comienza una fiebre de 10 segundos: solo se generan peces capturables, velocidad multiplicada por 5.5, aparición cada 0.23 s, monedas dobles y daño ecológico cero. La garra tarda 0.06 s y su recuperación 0.15 s. Las luces se vuelven doradas. La basura presente se retira al comenzar el bonus, sin dar recompensas. Máximo 35 entidades simultáneas.

## Peces no aptos y anguila

OceanSession comprueba cajas por proximidad cada 0.2 s sin activar colisiones físicas entre entidades. Cuando un pez toca basura cambia a su PNG noapto, pierde la interacción, baja lentamente y desaparece al salir de cámara o tras 12 s como límite.

Se conectaron pez azul noapto, pez naranja noapto y pez dorado noapto (alias de pez dorado millonario). El código acepta sufijos ` noapto`, `noapto` y `_noapto`. Si falta una variante, usa tinte gris y etiqueta NO APTO. Puedes asignar una textura explícita en Noapto Texture del nodo raíz de una entidad. No se encontró variante de anguila ni de pez linterna: estos usan ese fallback. La imagen foca noapta.jpg se conserva; la foca es un power up y no se contamina en esta versión.

Al pulsar sobre la anguila cambia al dibujo enojado y vuelve no aptos a los peces a menos de 0.85 m. No da premio al molestarla. Sale de escena normalmente; no permanece para siempre.

## Filtros y robots

Cada compra de filtro sube su nivel y crea un robot aspiradora. Costes: 20, 30, 40… monedas. Las primeras tres calidades mejoran velocidad y frecuencia de recogida; compras posteriores conservan calidad 3. Máximo tres robots simultáneos.

Patrullan, buscan basura también a distintas profundidades y la retiran automáticamente. Cada robot dura 60 segundos desde su compra. Entonces desaparece con el vídeo explosion.mp4 convertido en una hoja de sprites y el sonido deltarune-explosion.mp3. No hacen daño ni producen monedas al explotar. La mejora pasiva del filtro permanece tras perder al robot.

La explosión original tiene fondo verde: explosion_key.gdshader lo elimina al renderizar. Explosion.gd reproduce la hoja de 8×8 a 16 fps, usando los primeros 31 fotogramas. El vídeo original se conserva. Para cambiar el efecto puedes asignar Explosion Frames o Explosion Texture en Main/OceanSession.

## Sonidos editables

1. Selecciona Main/SoundHub.
2. Arrastra AudioStream a Button Touch, Button Success y Button Error para apuntar a botones, comprar y fallar.
3. Explosion y Alarm también son asignables. Sin sonido asignado se usa un pitido generado de respaldo.
4. Los efectos de subir nivel, quitar pez, quitar basura y bajar más profundo ya están enlazados.

Los archivos .mpeg suministrados contenían audio MPEG: se copiaron a .mp3 para que el importador de Godot los reconozca. Los originales permanecen. El volumen y pitch globales siguen respondiendo a la salud del océano.

## Descenso, iluminación y derrota

A niveles 5, 10, 15… aparece DESCENDER. Cada hito autoriza un descenso, incluso si se reclama más tarde. El fondo pierde un 25 % de luminosidad por descenso. Se incrementa la dificultad y empieza a aparecer el pez linterna, con OmniLight3D que ilumina sprites cercanos. Los peces ahora reciben iluminación.

El shader submarine_gray.gdshader sustituye los tonos blancos poco saturados por gris dentro de los materiales opacos del submarino, sin editar su GLB. El vidrio se conserva. Al perder salud se atenúan las luces y el fondo. Bajo 30 % aparece el aviso inferior rojo con pulso de 1 Hz y pitido cada 1.2 s.

Al llegar a cero se detienen las mecánicas, se retiran peces y robots, se oculta la tienda y aparece REINICIAR PARTIDA. El visor mantiene el seguimiento de cabeza. El botón recarga Main y restablece monedas, salud, nivel, profundidad, filtros y fiebre.

## Verificación

Prueba reproducible: ejecutar Godot desde el proyecto con `--xr-mode off --script res://tests/session_smoke.gd`. Comprueba 16 condiciones de progreso, contaminación, assets, robots, fiebre, iluminación, derrota y recarga real. Guarda una captura de derrota en .godot/defeat-preview.png. Validada con Vulkan en PC; falta revisar sensación de garra, iluminación del interior y legibilidad en el visor físico.
## Actualización: zigzag, auras y cursor

- Peces con zigzag vertical triangular de 0.44 m de recorrido y oscilación de profundidad de 0.20 m. La frecuencia aumenta al descender.
- Tamaño multiplicado por 1 + profundidad × 0.22, limitado a 2.6. El tamaño grande también aumenta pago y tiempo de captura.
- Probabilidad de aura: 18 % en superficie, +8 puntos por descenso, máximo 65 %. Tres intensidades: azul pálido a dorado. Cada nivel añade 60 % a la recompensa y 0.17 s al agarre. Durante fiebre se conserva el agarre rápido del bonus.
- Botellas rotas caen desde Y=3.2; al pasar Y=-0.5 cuentan como basura ignorada. El resto de basura conserva deriva lateral y caduca a los 12 s.
- Basura independiente de peces: intervalo max(0.28, 2.3/(1+profundidad×0.75)). Daño de ignorarla: (8+profundidad×2) × dificultad / (1+filtro×0.4). Máximo 65 entidades. Durante fiebre no aparece basura.
- La mira circular sustituye al hueso y se sitúa justo delante del punto de impacto del asset señalado. No hay ajuste manual de profundidad ni resorte. Mantén gatillo/clic para llenar la barra; perder el objetivo reinicia el agarre.
- Capturas y activaciones mediante la mira generan siete burbujas durante 1.5 s. Máximo doce grupos simultáneos.

Pruebas: 20 verificaciones en PC/Vulkan, incluidas crecimiento, recompensa del aura, zigzag y caída vertical. Falta ajustar el balance mediante partidas reales en VR.

## Actualización: enemigos, avisos y entradas curvas

- Ancho base de peces reducido de 0.43 a 0.25 m; anguilas de 0.65 a 0.40 m. El crecimiento por profundidad es +10 % y tiene límite 1.55. Conservan zigzag y auras.
- Entrada con giro y aparición gradual de 0.8 s. Al alcanzar el borde lateral giran en un arco hacia el fondo y se desvanecen durante 2.5 s antes de liberar recursos.
- La luz local de la anguila solo es visible mientras está enojada y apta. El pez linterna apaga su luz al quedar no apto. Se asignaron las variantes no aptas nuevas.
- Peces millonarios: 0.5 % en el sorteo normal, 1.5 % durante fiebre. Fiebre con marco dorado, fondo teñido y anuncio con cuenta atrás.
- Robots: +10 monedas de coste por profundidad, además del coste por mejora. Máximo diez activos; conservan su vida útil de 60 segundos.
- Alarma: FNAF 3 ventilation error tiene reproductor exclusivo; no compite por las seis voces de efectos. Repite mientras haya salud inferior a 30, sin reiniciar el clip cada pitido. Se detiene al recuperar salud o perder.
- Pez globo: aparece cerca del cursor, describe una órbita lenta durante cinco segundos y se va si se ignora. Al tocarlo se infla, bloquea la interacción cinco segundos, reduce iluminación y aplica blanco y negro; después se aleja y desaparece. La cabeza VR mantiene siempre su seguimiento.
- Caracoles: tres variantes adheridas a una posición relativa a la cámara. Mantén el gatillo/clic para sujetar, lleva el cursor hacia el borde y suelta. Se desprenden si están fuera del radio central de 0.40 m a la distancia de agarre. Si sueltas en el centro se vuelven a pegar. Máximo tres hostiles; aparece uno cada 18 s aproximadamente.
- Ayuda: texto sin recuadro opaco. Visible durante el primer minuto, luego se desvanece y vuelve tras cinco segundos sin actividad; la ficha del objeto señalado continúa disponible. Cursor con pulsación suave.

Sonidos conectados: botones (laser1, burbuja pop, laser2), foca (foca talvez), pez globo (se infla pez globo), caracol (Gary the Snail), lanzamiento (lancer-splat), derrota y linterna no apta (pez linterna muere). M4A convertidos a MP3 para Godot; originales conservados. Los otros clips quedan disponibles para asignar desde el Inspector.

Validación: 27 comprobaciones en PC/Vulkan, incluidas hostiles, lanzamiento, apagado de linterna y precios/límite de robots. Se revisaron capturas del filtro dorado y del blanco y negro. Falta la prueba binocular en el visor físico, especialmente el shader de pantalla y la distancia de agarre de caracoles.
