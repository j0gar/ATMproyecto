# M&J Core v0.4.3 — Botón de cierre

## Cambio principal

Todas las aplicaciones muestran ahora un botón rojo `X` en la esquina superior derecha.

Al tocarlo:

- se cierra la aplicación actual;
- se vuelve al escritorio;
- ya no es necesario tocar la barra superior.

El botón forma parte del núcleo de interfaz, por lo que las aplicaciones nuevas pueden añadirlo usando:

```lua
table.insert(self.buttons, ui.closeButton(monitor, theme))
```

Esta versión mantiene:

- tareas separadas de J0gar y Mia;
- inventario con texto grande;
- detector de Mia por coordenadas;
- mensajes diarios rotatorios.
