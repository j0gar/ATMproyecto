# M&J Core 0.9.3 — Multiuser Identity

- Nueva API común de almacenamiento (`core/storage.lua`).
- Separación entre almacenamiento, inventario del jugador y logística de máquinas.
- Servicio permanente de logística, también en modo servidor sin monitor.
- Registro modular de máquinas en `mjcore/machines/`.
- Primera máquina: Emerald Furnace de Iron Furnaces.
- Extracción automática del output, carbón mantenido en 32 y entrada de materiales con tag `c:raw_materials`.
- Nueva app LOGISTICA con estado del Storage Controller, máquinas, trabajo y combustible.
- GUARDAR TODO solo deposita objetos que ya existen en Functional Storage; los desconocidos permanecen en el jugador.
- El updater preserva cualquier archivo existente bajo `/mjcore/config`, `/mjcore/data` y `/mjcore/logs`.

# M&J Core 0.7.1 — Inventory Manager Fix

- Corrige la detección de Inventory Managers en Advanced Peripherals 0.7.62b.
- Usa `peripheral.hasType` y una comprobación de métodos como respaldo.
- Normaliza el nombre del propietario para que no afecten mayúsculas/minúsculas.
- Añade un mensaje de diagnóstico con los propietarios detectados cuando no encuentra el solicitado.

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

## v0.7.0 Logistics Network
- Escritorios independientes por ordenador/monitor.
- Nodo principal servidor y terminales secundarios cliente.
- Perfil de terminal con Inventario y Tareas.
- Inventario táctil en baldosas tipo drawer, con botones 1, 16, 32 y 64.
- Peticiones inalámbricas al servidor central.
- Entrega al jugador mediante su Inventory Manager vinculado.

Configuración rápida:
- Principal: `mj setup server left j0gar_ 2 right`
- Secundario: `mj setup terminal left j0gar 2`

El último argumento del servidor (`right`) es el lado, visto desde el Inventory Manager, donde está el inventario fuente. El Storage Controller debe estar accesible físicamente desde ese lado para `addItemToPlayer`.


## Gestion de tareas desde el juego

```
mj task list j0gar
mj task add j0gar Conseguir 64 bloques de hierro
mj task done j0gar 1
mj task remove j0gar 1
```

Los mismos comandos funcionan con el perfil `mia`. En un terminal secundario, los cambios se envian al servidor por la red de M&J Core.


## M&J Pocket

La v0.8.5 incluye un cliente para Advanced Wireless Pocket Computer.

Configuralo una vez con:

```
mj setup pocket left j0gar_ 2
reboot
```

Sustituye `2` por el ID real del servidor. El lado del modem es orientativo: M&J Core busca automaticamente cualquier modem wireless disponible.

Funciones iniciales:
- anadir, completar y eliminar tareas con el teclado del juego;
- buscar objetos y pedirlos al Inventory Manager;
- comprobar la conexion con el servidor;
- salir a la consola sin detener los ordenadores de los monitores.


## Pocket hibrida
La Pocket usa botones tactiles para navegar y el teclado del juego para escribir tareas, busquedas y cantidades personalizadas. Tambien admite flechas, ENTER, rueda y teclas numericas.


## v0.9.1 Logistics Controls

- Configuracion dinamica de combustible por maquina.
- Boton de actualizacion en Pocket y monitor secundario.
- Confirmacion antes de instalar actualizaciones.
- Configuracion persistente en `/mjcore/config/machines`.


## v0.9.3 Multiuser Identity

- Corrige el jugador del Inventory Manager de `j0gar` a `j0gar_`.
- Migra en tiempo de ejecución configuraciones antiguas conservadas en `/mjcore/data/node.lua`.
- Los nuevos nodos usan `j0gar_` por defecto.


## v0.9.5 Pocket Identity and Mia Messages

- Los monitores resuelven el destinatario mediante Player Detector.
- Si hay un jugador, lo seleccionan automaticamente.
- Si hay varios, muestran un selector durante la accion.
- La seleccion se recuerda 15 segundos mientras no cambien los jugadores detectados.
- Cada Inventory Manager puede usar un lado distinto mediante `/mjcore/config/inventory_managers.lua`.
- Valores iniciales: `j0gar_ = bottom`, `MiaWRaW = right`.


## v0.9.5

- Las Pocket siguen vinculadas al propietario configurado en `node.lua`; no existe un jugador fijo en el código.
- Los monitores compartidos resuelven el jugador mediante Player Detector.
- La detección personalizada de Mia usa `isPlayerInCoords` con fallback compatible.
- Los mensajes privados para `MiaWRaW` usan la API de Chat Box 0.8 y soporte UTF-8.
- Se mantiene compatibilidad con `sendMessageToPlayer` de Advanced Peripherals 0.7.
