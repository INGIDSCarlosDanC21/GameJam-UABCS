# Guía de ampliación de Ocean VR

Documento de implementación para el proyecto actual, 10 de septiembre de 2026.
Este documento describe cambios pendientes; crear esta guía no instala las mecánicas. Aplica cada apartado y comprueba su resultado antes de continuar. Los valores de balance son propuestas de juego, no medidas ecológicas reales.

## 1. Música dinámica según la salud del océano

### Preparar los audios

1. Crea `assets/audio/music/` y guarda `healthy.ogg`, `danger.ogg` y `critical.ogg`.
2. Usa tres capas musicales con idéntico tempo, duración y punto de inicio. Diseña sus finales para conectar sin clics con el principio.
3. Selecciona cada OGG en Godot, activa Loop en sus opciones de importación y pulsa Reimport.
4. En el panel Audio crea el bus Music, dirigido a Master. Guarda el diseño de buses como `res://default_bus_layout.tres`.
5. Añade bajo Main un Node llamado MusicDirector. Dentro coloca tres AudioStreamPlayer: Healthy, Danger y Critical. Asigna los OGG correspondientes, Bus = Music y Autoplay desactivado. Usa AudioStreamPlayer para música global; reserva AudioStreamPlayer3D para motores de robots u otros sonidos localizados.
6. Adjunta este script como `scripts/MusicDirector.gd`:

```gdscript
extends Node

@onready var tracks: Array[AudioStreamPlayer] = [$Healthy, $Danger, $Critical]
var mix_tween: Tween

func _ready() -> void:
    for track in tracks:
        track.volume_db = -60.0
        track.play()
    GameManager.ocean_health_changed.connect(_mix)
    _mix(GameManager.ocean_health)

func _mix(health: float) -> void:
    var h := clampf(health / 100.0, 0.0, 1.0)
    var healthy := smoothstep(0.4, 0.8, h)
    var critical := 1.0 - smoothstep(0.1, 0.4, h)
    var danger := maxf(0.0, 1.0 - healthy - critical)
    var gains := [healthy, danger, critical]
    if mix_tween:
        mix_tween.kill()
    mix_tween = create_tween().set_parallel(true)
    for i in range(tracks.size()):
        var db := linear_to_db(maxf(float(gains[i]), 0.001)) - 6.0
        mix_tween.tween_property(tracks[i], "volume_db", db, 1.5)
```

Las pistas siguen reproduciéndose aun cuando no se oyen. Evita detenerlas al cambiar de estado. El inicio conjunto es suficiente para capas ambientales del prototipo; no constituye sincronización musical de precisión a nivel de muestra.

### Conservar la degradación global existente

`autoload/GameManager.gd` ya reduce Master y aplica AudioEffectPitchShift según ocean_health. Conserva `_ensure_pitch_fx()` y `_apply_audio()`: afectan también al bus Music. No vuelvas a bajar el pitch_scale de cada reproductor, porque duplicarías el efecto. AudioServer no tiene una propiedad pitch_scale global: en este proyecto pertenece al efecto del bus.

Actualmente Master baja hasta 0.12 de volumen lineal y el efecto hasta pitch_scale = 0.55. Escucha esos extremos en el visor; si la música resulta ininteligible, prueba 0.75 como mínimo de pitch. El nivel crítico debe seguir audible y acompañar la alarma visual.

Comprobación: desde el Inspector remoto cambia la salud mediante un evento de juego y verifica el fundido. Cambiar directamente la variable desde el Inspector no emite ocean_health_changed; para pruebas usa temporalmente `GameManager._set_health(20.0)` desde un botón de depuración. Retira ese botón al terminar.

## 2. Sustituir los placeholders por PNG

### Preparación de arte e Inspector

1. Exporta peces mirando todos hacia el mismo lado, con fondo transparente y márgenes pequeños. No fuerces el lienzo a ser cuadrado.
2. Guarda `assets/art/fish.png` y `assets/art/trash.png`.
3. En `scripts/InteractableEntity.gd` añade:

```gdscript
@export var fish_texture: Texture2D
@export var trash_texture: Texture2D
@export var base_width_m: float = 0.32
var size_factor: float = 1.0
```

4. Abre `scenes/InteractableEntity.tscn`, selecciona el nodo raíz y arrastra los PNG a Fish Texture y Trash Texture. Guarda la escena. Así todas las instancias del Spawner heredarán esos recursos.
5. En `_apply_placeholder()`, antes de generar el bloque de color, añade lo siguiente. Mantén el resto de la función como fallback:

```gdscript
    var art: Texture2D = fish_texture if kind == Kind.FISH else trash_texture
    if art != null:
        _sprite.texture = art
        var width_m := base_width_m * (size_factor if kind == Kind.FISH else 1.0)
        _sprite.pixel_size = width_m / float(art.get_width())
        _sprite.scale = Vector3.ONE
        _sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        var box := BoxShape3D.new()
        box.size = Vector3(width_m,
            float(art.get_height()) * _sprite.pixel_size, 0.08)
        $CollisionShape3D.shape = box
        return
```

El return evita que el generador actual vuelva a sobrescribir el PNG. Crear un BoxShape3D por instancia evita cambiar simultáneamente las cajas de todos los peces.

### Tamaño sin deformación

El ancho visible es `ancho_png × pixel_size`; el alto es `alto_png × pixel_size`. Un PNG de 512 × 256 con pixel_size = 0.001 mide 0.512 × 0.256 metros y conserva automáticamente su relación 2:1.

Para ajustes manuales modifica solo Pixel Size en Sprite3D o usa Scale uniforme, por ejemplo (1.5, 1.5, 1.5). No uses valores distintos en X e Y. Deja también la escala de sus padres uniforme. El código anterior recalcula Pixel Size al iniciar: modifica Base Width M en la raíz si quieres que el cambio persista al jugar.

Activa mipmaps en la importación para sprites que se ven a distintas distancias. En Sprite3D elige Texture Filter = Linear With Mipmaps para pintura suave. El filtrado se configura en el nodo en Godot 4, no mediante una casilla Filter del importador.

## 3. Rareza, tamaño, recompensa y coste ecológico

### Datos iniciales propuestos

- Común: probabilidad 65 %, multiplicador económico 1, multiplicador de daño 1, halo blanco tenue.
- Poco común: 25 %, dinero ×2, daño ×2, halo cian.
- Raro: 8 %, dinero ×4, daño ×4, halo violeta.
- Legendario: 2 %, dinero ×8, daño ×8, halo dorado.

Tamaños independientes de la rareza:

- Pequeño: 50 % de probabilidad, size_factor = 0.75.
- Mediano: 35 %, size_factor = 1.0.
- Grande: 15 %, size_factor = 1.5.

Añade `var rarity: int = 0` a InteractableEntity.gd. Dentro de setup(), después de asignar kind y direction, sortea solo para peces:

```gdscript
    if kind == Kind.FISH:
        var r := randf()
        rarity = 0 if r < 0.65 else (1 if r < 0.90 else (2 if r < 0.98 else 3))
        var s := randf()
        size_factor = 0.75 if s < 0.50 else (1.0 if s < 0.85 else 1.5)
```

Mantén estos valores fijos durante la vida del pez. El Spawner ya llama setup() antes de add_child(), por lo que estarán disponibles en _ready(). No sortees dentro de `_apply_placeholder()`: una actualización visual no debe cambiar el precio.

### Conectar el balance a GameManager

Reemplaza catch_fish() en GameManager.gd por:

```gdscript
func catch_fish(rarity: int = 0, size_factor: float = 1.0) -> void:
    if ocean_health <= 0.0:
        return
    var tier := clampi(rarity, 0, 3)
    var factor := clampf(size_factor, 0.75, 1.5)
    var multipliers := [1.0, 2.0, 4.0, 8.0]
    var reward := maxi(1, roundi((3 + bait_level * 2) * multipliers[tier] * factor))
    var damage := 6.0 * multipliers[tier] * factor
    _add_coins(reward)
    _set_health(ocean_health - damage)
```

En InteractableEntity.on_click(), cambia la llamada del caso FISH a `GameManager.catch_fish(rarity, size_factor)`. Los argumentos por defecto mantienen compatibles las llamadas antiguas.

Sin cebo: común pequeño = 2 monedas y 4.5 de daño; común mediano = 3 y 6; raro grande = 18 y 36; legendario grande = 36 y 72. El daño aumenta de forma deliberadamente severa: capturar ejemplares valiosos debe ser una decisión visible.

Añade un Label3D pequeño o una ficha de información al apuntar: rareza, tamaño, monedas y daño. Calcula su texto con las mismas fórmulas; centralízalas después en una función compartida para no mostrar precios diferentes del pago real.

En Spawner limita fish_chance con `clampf(0.45 + float(GameManager.bait_level) * 0.08, 0.45, 0.80)`. De otro modo suficientes compras de cebo eliminan la aparición de basura y alteran toda la economía.

## 4. Brillo artificial por rareza, apto para VR

Usa un halo pintado para que el efecto siga visible sin depender del bloom del renderizador.

1. Crea un PNG `assets/art/fish_halo.png`: mancha suave blanca, centro tenue y bordes completamente transparentes.
2. Añade Halo como Sprite3D hermano del Sprite3D principal en InteractableEntity.tscn. Así heredará el movimiento del Area3D.
3. Asigna la textura, activa Billboard, desactiva Shaded y las sombras. Colócalo ligeramente detrás del pez (por ejemplo Z = -0.015 para la vista frontal). No desactives la prueba de profundidad: no debe verse a través de la cabina.
4. Al terminar de asignar el arte, ajusta el ancho del halo a 1.3 veces el ancho real del pez: `halo.pixel_size = ancho_pez_m * 1.3 / halo.texture.get_width()`.
5. Usa Modulate con blanco alpha 0.08, cian alpha 0.18, violeta alpha 0.25 o dorado alpha 0.32 según rarity. Aplica el mismo flip_h que al pez si el halo sigue su silueta.
6. Oculta Halo para Kind.TRASH. Si deseas pulsación, cambia suavemente su alpha alrededor del valor base; evita destellos bruscos.

Esto es un brillo visual artificial, no una luz que ilumina el entorno. Para emisión real se puede preparar un material emissive; el bloom depende del renderer y sus ajustes. Empieza con el halo para mantener el resultado consistente en el visor. Godot documenta que los materiales Unshaded no reciben iluminación y que la transparencia tiene coste: [materiales 3D](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html).

Limita los peces simultáneos y evita muchos halos grandes superpuestos. Verifica ambos ojos: Billboard no garantiza que dos superficies transparentes cercanas se ordenen siempre como esperas. Si hay parpadeo, integra el halo en el PNG del pez y conserva la escala por dimensiones totales del PNG.

## 5. Tienda: tres calidades de robots limpiadores de arrecife

La tienda actual solo ofrece Cebo y Filtro. Añade tres productos distintos; no los presentes como implementados hasta conectar sus compras y limpieza.

### Calidades propuestas

- Básico — 25 monedas. Velocidad 0.35 m/s, radio de recogida 0.30 m, intervalo mínimo entre recogidas 5 s. Retira una basura y recupera 4 de salud. Carcasa gris con indicador verde.
- Avanzado — 60 monedas. Velocidad 0.55 m/s, radio 0.45 m, intervalo 3 s. Una basura y 6 de salud. Carcasa azul con dos herramientas visibles.
- Élite — 120 monedas. Velocidad 0.75 m/s, radio 0.60 m, intervalo 2 s. Una basura y 8 de salud. Carcasa blanca y dorada con tres herramientas.

Los robots no capturan peces. No generan monedas ni salud por segundo: solo recuperan salud cuando retiran basura existente. Mantén la limpieza manual en +5 monedas para que el jugador tenga una vía sostenible de compra. Máximo tres robots activos; las compras adicionales deben rechazarse sin cobrar.

### Escena y patrulla

1. Crea `scenes/ReefCleaner.tscn` con raíz Node3D, un MeshInstance3D sencillo o Sprite3D para el cuerpo, y opcionalmente AudioStreamPlayer3D para el motor. No necesita cuerpo físico ni colisiones.
2. Añade bajo Main un Node3D ReefCleaners y dos Marker3D, PatrolLeft y PatrolRight, a los lados del área de juego frente a la ventana.
3. En su script guarda quality, speed, pickup_radius y cooldown. Alterna el objetivo entre los dos Marker3D. En `_physics_process(delta)` usa `global_position.move_toward(destino.global_position, speed * delta)` y cambia de extremo cuando la distancia sea menor que 0.03 m.
4. Mantén marcadores y robots en coordenadas globales al calcular distancias. No mezcles position local con global_position.
5. Mientras esté en cooldown continúa patrullando. Cuando pueda limpiar, consulta las entidades del grupo trash y elige una dentro de pickup_radius. Si no hay basura cerca no restaures salud ni reinicies el cooldown.
6. Sitúa la basura en una franja que los robots puedan alcanzar. Actualmente el Spawner usa profundidades entre -6.2 y -2.4: una patrulla sobre un solo plano no alcanza todo ese volumen. Para la pantalla flotante agrupa basura y patrulla alrededor de la misma profundidad; por ejemplo basura Z entre -3.2 y -2.8, patrulla Z = -3.0. Ajusta después al plano real de la ventana del modelo.

### Retirada de basura sin duplicar recompensas

En `_ready()` de InteractableEntity añade `add_to_group("trash")` cuando kind sea TRASH. Añade una función pública específica:

```gdscript
func collect_by_robot(healing: float) -> bool:
    if kind != Kind.TRASH or _clicked or GameManager.ocean_health <= 0.0:
        return false
    _clicked = true
    GameManager.restore_from_robot(healing)
    queue_free()
    return true
```

Añade en GameManager:

```gdscript
func restore_from_robot(amount: float) -> void:
    if ocean_health > 0.0:
        _set_health(ocean_health + clampf(amount, 0.0, 8.0))
```

El robot solo inicia cooldown si collect_by_robot() devuelve true. Usa is_instance_valid() antes de llamar a un objetivo guardado. `_clicked` bloquea que el láser, otro robot y la expiración cuenten la misma basura varias veces, incluso antes de que queue_free() se complete.

### Compra y conexión

1. Amplía ShopItem.Item conservando los valores actuales: `BAIT, FILTER, ROBOT_BASIC, ROBOT_ADVANCED, ROBOT_ELITE`.
2. Crea tres Area3D de tienda con CollisionShape3D y Label3D; usa collision_layer = 2, collision_mask = 0 y grupo interactable, igual que los botones existentes.
3. Añade una señal `robot_purchased(quality: int)` y un método `buy_robot(quality: int) -> bool` en GameManager.
4. Valida índice 0..2, salud mayor que cero, límite de tres activos y monedas suficientes ANTES de modificar nada. Usa costes [25, 60, 120]. Al aceptar, descuenta una vez, incrementa el contador, emite coins_changed y robot_purchased y devuelve true.
5. En Main conecta robot_purchased antes de permitir compras. El receptor instancia ReefCleaner.tscn, configura su calidad antes de add_child(), lo añade a ReefCleaners y le asigna los marcadores de patrulla. Precarga esa escena para detectar un recurso ausente al iniciar, antes de cobrar.
6. En ShopItem.on_click() llama buy_robot(0), buy_robot(1) o buy_robot(2) según producto. Muestra precio, calidad y límite ocupado en Label3D. Informa si faltan monedas o se alcanzó el límite.
7. En reinicio, elimina robots y restablece su contador. Si incorporas destrucción o venta, decrementa el contador exactamente una vez al retirar cada robot.

El filtro existente reduce daño de basura ignorada; conserva esa función como mejora pasiva independiente. No multipliques automáticamente la curación de los robots por filter_level: haría difícil ajustar la economía.

## 6. Derrota y conservación

Actualmente ocean_health puede volver a subir después de llegar a cero. Si cero significa derrota definitiva, establece esa regla de forma consistente: bloquea pesca, limpieza manual, compras y recuperación por peces que escapan; detén Spawner y robots al recibir defeat_changed(true). Mantén la música y alarma en estado crítico hasta reiniciar. Los guardas de los fragmentos anteriores cubren pesca y limpieza robótica; aún debes aplicarlos a las otras acciones.

No restaures salud solo por patrullar. Dejar escapar peces puede conservar el bonus actual de +2 mientras la partida siga activa. Comprueba que el aumento de aparición por cebo no permita recuperar salud ilimitadamente dejando pasar una cantidad desproporcionada de peces; limita su nivel o ajusta ese bonus tras probar.

## 7. Orden de implementación y comprobaciones

1. PNG: confirmar que al ejecutar no vuelven los bloques, que una botella alta no se deforma y que el láser coincide con su caja.
2. Tamaños: forzar temporalmente 0.75, 1.0 y 1.5 en setup y comparar silueta y selección.
3. Rarezas: forzar cada rarity de 0 a 3; verificar halo y pagos. Con 25 monedas iniciales, un raro grande sin cebo deja 43 monedas y salud 64.
4. Música: probar salud 100, 60, 20 y 0; comprobar fundidos sin reinicios y que no se duplica la reducción de pitch.
5. Robots: comprar cada calidad por separado. Con dinero insuficiente o tres activos no debe cobrar. Sin basura no debe curar. Dos robots sobre la misma basura deben contar una sola limpieza.
6. Derrota: tras cero no deben reaparecer salud ni nuevos peces hasta reiniciar, si aplicaste la regla definitiva.
7. Probar el conjunto en PC y en VR, con varios peces y tres robots. Confirmar legibilidad de etiquetas, transparencia de halos y fluidez. Mantén el arranque OpenXR corregido en Main.gd.

Referencias de Godot: [SpriteBase3D y pixel_size](https://docs.godotengine.org/en/stable/classes/class_spritebase3d.html), [AudioStreamPlayer](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html), [AudioEffectPitchShift](https://docs.godotengine.org/en/stable/classes/class_audioeffectpitchshift.html).