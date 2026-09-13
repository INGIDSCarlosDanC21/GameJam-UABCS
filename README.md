> Estado actual: **1.0.0-rc2**, candidata de cierre. Consulta [validación y pendientes](docs/RELEASE_1_0.md), [Quest 2](docs/QUEST2.md) y [créditos completos](assets/CREDITS.txt). Las instrucciones históricas de arte que siguen no describen todas las mecánicas actuales.

# Ocean VR — guía de arte 2D (Godot 4.x)

**Fondo 3D actualizado:** [guía del arrecife, animaciones y ajustes para Quest](FONDO_MARINO_3D.md).
[Créditos de los modelos descargados](assets/models/reef/CREDITS.txt), también disponibles al elegir modo de juego.

**Fecha del prototipo: 10 de septiembre de 2026.**  
Prototipo: cabina estática, puntero láser VR, peces/basura flotantes y **Salud del Océano**.  
Abrir la carpeta del proyecto en **Godot 4.3+** (probado en 4.7) con OpenXR. Escena principal: `scenes/Main.tscn`.  
Los sprites actuales son **placeholders** (rectángulos de color generados en código). Esta guía explica cómo sustituirlos por `.png` finales **sin distorsionar** la relación de aspecto.

---

## 1. Convención de archivos

Crea (o usa) estas rutas:

| Uso | Ruta recomendada | Notas |
|-----|------------------|--------|
| Pez | `assets/art/fish.png` | Fondo **transparente**. PNG-8 o PNG-32. |
| Basura | `assets/art/trash.png` | Igual. Silueta clara, se lee a ~2–6 m. |
| Cielo 360 (opcional) | `assets/sky/ocean_360.ogv` | Vídeo equirectangular en bucle (Theora `.ogv` en Godot). |

Nombres extra (variantes): `fish_01.png`, `trash_bottle.png`, etc. El código base espera **una** textura por tipo; las variantes se asignan en el Inspector o ampliando `_apply_placeholder()`.

**Exportación 2D**

- Recorta el lienzo al bounding box del dibujo (sin márgenes enormes).
- No estires el PNG para “cuadrarlo”: exporta el **aspect ratio real** (p. ej. pez 256×128, botella 96×160).
- Resolución útil en VR: **128–512 px** en el lado mayor. Más de 1024 suele ser desperdicio a esta escala.
- Pixel art: múltiplos de 8/16 y filtro **Nearest**. Pintura suave: **Linear**.

---

## 2. Importar el PNG en Godot

1. Copia el `.png` a `assets/art/`.
2. En el FileSystem de Godot, selecciona el archivo.
3. Import dock:
   - **Compress → Mode:** `Lossless` (UI/sprites nítidos) o `VRAM Compressed` si hay muchos.
   - **Fix Alpha Border:** on.
   - Pixel art: **Filter** off (o `Nearest` en el Sprite3D).
4. **Reimport**.

---

## 3. Reemplazar el Sprite3D (peces y basura)

Escena: `scenes/InteractableEntity.tscn` → nodo `Sprite3D`.

### Opción A — Inspector (recomendado para arte)

1. Abre `InteractableEntity.tscn`.
2. Selecciona `Sprite3D`.
3. En **Texture**, arrastra `fish.png` o `trash.png`.
4. En el script `InteractableEntity.gd`, comenta o elimina la línea que pisa la textura en runtime:

```gdscript
_sprite.texture = _make_block_texture(color, kind == Kind.FISH)
```

Sustitúyela por algo así (dos texturas exportadas):

```gdscript
@export var fish_texture: Texture2D
@export var trash_texture: Texture2D

func _apply_placeholder() -> void:
	_sprite.texture = fish_texture if kind == Kind.FISH else trash_texture
	_sprite.pixel_size = 0.004
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
```

En el Inspector de la escena, asigna `Fish Texture` y `Trash Texture`.

### Opción B — Instancias distintas

Duplica `InteractableEntity.tscn` → `Fish.tscn` / `Trash.tscn`, cada una con su PNG en `Sprite3D.texture`, y cambia el spawner para instanciar según `kind`.

---

## 4. Aspect ratio automático (sin deformar)

`Sprite3D` ya respeta el tamaño en píxeles de la textura:

```
ancho_mundo = texture.get_width()  * pixel_size
alto_mundo  = texture.get_height() * pixel_size
```

El ratio **ancho/alto** es el del PNG. No hay que calcular nada a mano.

### Qué hacer

1. Deja **Scale** del `Sprite3D` en `(1, 1, 1)`.
2. Ajusta **solo** `pixel_size` hasta que el objeto se vea del tamaño correcto en la cabina.
3. No uses Scale X ≠ Scale Y para “encajar” en un cuadrado: eso **estira** la imagen.

### Valor de partida

| `pixel_size` | Efecto (textura 256 px de ancho) |
|--------------|-----------------------------------|
| `0.002` | ~0.51 m de ancho (pequeño, UI cercana) |
| `0.004` | ~1.02 m (default del prototipo) |
| `0.006` | ~1.54 m (se lee desde más lejos) |

Si el pez se ve enorme o minúsculo al cambiar de 64×32 (placeholder) a 256×128 (arte), **baja o sube `pixel_size`**, no el scale. Ejemplo: placeholder 64 px a `0.004` → 0.256 m; arte 256 px al mismo `pixel_size` → 1.024 m (4×). Compensa: `0.004 * (64/256) = 0.001`.

Fórmula para **mantener el mismo ancho en metros** al cambiar de textura:

```
nuevo_pixel_size = pixel_size_actual * (ancho_png_viejo / ancho_png_nuevo)
```

### CollisionShape3D

Tras el arte final, ajusta el `BoxShape3D` al tamaño visual (Inspector → Shape → Size) para que el láser no “falle” fuera del dibujo ni requiera clics en el vacío.

---

## 5. Billboard y recorte

En `Sprite3D` del prototipo:

- **Billboard:** Enabled (mira a la cámara; correcto para sprites 2D en falso 3D).
- **Alpha Cut:** Discard (siluetas limpias en VR).
- **Pixel Size:** ver tabla.
- **Centered:** on.

No actives `double_sided` si no hace falta; el billboard ya orienta el quad.

---

## 6. Vídeo 360 del cielo

1. Exporta equirectangular (2:1), p. ej. 2048×1024, codec **Theora** `.ogv`.
2. Colócalo en `assets/sky/ocean_360.ogv`.
3. `Main.gd` lo carga solo si el recurso existe; si no, el `ColorRect` del `SubViewport` hace de cielo plano.
4. En `SkyViewport/VideoStreamPlayer`, deja **Loop** y **Expand** activados. El nodo está `visible = false` a propósito (alimenta el `ViewportTexture`, no la UI).

---

## 7. Checklist rápido

- [ ] PNG con alpha, recortado al dibujo.
- [ ] Scale del Sprite3D = `(1,1,1)`.
- [ ] Solo `pixel_size` para el tamaño en mundo.
- [ ] Box colliders retocados al nuevo tamaño.
- [ ] Filtro Nearest (pixel) o Linear (pintado).
- [ ] Probar a 1.5–2 m de la cabina con el láser.

Si una imagen se ve “aplastada”, casi siempre hay un Scale no uniforme o un PNG ya estirado en el export del DCC. Corrige el archivo, no el nodo.
