# M&J Core 0.6.1 — Aurora Fix

- Corrige el envío privado a jugadores en Advanced Peripherals 0.8+ y mantiene compatibilidad con 0.7.
- El botón CERRAR se dibuja siempre al final, abajo a la derecha y en rojo en todas las aplicaciones.
- Mejora los mensajes de error de la Chat Box.

# M&J Core 0.6.0 - Aurora UI

Actualización visual y funcional para monitores 4x2:

- Interfaz más limpia y compacta.
- Ocho aplicaciones visibles por página cuando el ancho lo permite.
- Botón CERRAR fijo en la barra inferior de todas las ventanas.
- Botones compactos de una línea.
- Paleta oscura personalizada con mejor contraste.
- Iconos pixelados 3x3 para aplicaciones y materiales.
- Motor común de iconos en `mjcore/core/icons.lua`.
- Conserva tareas, mensajes y configuración personal durante la actualización.

Instalación:

    wget run https://raw.githubusercontent.com/j0gar/ATMproyecto/main/install.lua


## Correccion 0.6.4
- Envio privado a MiaWRaW usando exactamente `sendMessageToPlayer(mensaje, jugador)`.
- Eliminado el tercer argumento que provocaba el error de nombre o UUID.
