# Fotografías, luz y dificultad

Las nuevas fotografías usan el mundo real y la posición de la cámara del jugador. El encuadre se orienta hacia el centro del animal y ajusta el campo de visión a su tamaño, conservando el entorno. No se genera un recorte transparente ni se clona el animal. El visor secundario solo renderiza al disparar. La interfaz de estado y los punteros se excluyen de la foto. Las fotos guardadas antes de este cambio conservan su formato.

Las luces de fauna, linterna y flash tienen el grupo `self_lit`: el oscurecimiento general no les cambia la energía. Dos luces de medusas mantienen su escala mundial para evitar que el tamaño reducido del animal reduzca el alcance; dos peces linterna y dos líderes de sus cardúmenes iluminan alrededor. Todas estas luces carecen de sombras y la cantidad permanece acotada. Las medusas conservan su emisión visible en la niebla.

La basura activa con al menos ocho segundos de edad provoca presión ambiental cada dos segundos cuando se acumulan dos o más residuos. El daño escala con profundidad y cantidad, con máximo siete puntos por pulso en arcade; educación recibe el 65%. Siguen vigentes las protecciones de tutorial, práctica y recuperación tras parálisis. Limpiar manualmente recupera 3,5 puntos y los robots 0,65, con un pequeño extra limitado por mejoras. La basura ignorada causa mayor daño. Los límites de población no aumentan.

Los grandes pulpos animados dejan quince metros libres hasta su superficie delantera; los otros pasos laterales, ocho metros. El tiburón se aproxima de frente y gira antes de alcanzar el cristal. Los delfines alternan vocalización y chasquidos; las ballenas usan canto de ballena. Fuentes y licencias en `assets/audio/effects/CETACEAN_CREDITS.txt`.

Se elimina el panel superior. Nivel, salud, monedas y profundidad aparecen en un indicador inferior izquierdo, con barra de salud y progreso de nivel. Las misiones educativas quedan debajo de la vista. No exige inclinar la cabeza hacia arriba.

Validación: pruebas de ecología, fotografías con renderizado, pausa, sesión completa, fauna y rendimiento. Una prueba antigua de sesión necesitaba fijar profundidad 12 antes de instanciar un pez linterna; actualizada para respetar su desbloqueo. La sesión completa pasa. Carga a 20 km en RTX 4050: mediana 14,5 ms y p95 22,9 ms en 180 cuadros después de calentamiento. Comprobación física de Quest/PCVR pendiente.
