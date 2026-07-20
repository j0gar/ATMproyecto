# M&J Core

Sistema de control para CC:Tweaked, diseñado para un monitor avanzado de 4x4 bloques.

## Version 0.1.0

Esta primera version incluye:

- Pantalla de arranque.
- Deteccion automatica del monitor.
- Escritorio adaptable a la resolucion.
- Control tactil.
- Control con flechas y Enter.
- Tema visual comun.
- Sistema modular de aplicaciones.
- Aplicaciones provisionales:
  - Inventario
  - Jugadores
  - Tareas
  - Energia
  - Alarmas
  - Ajustes

## Instalacion manual

La estructura en el ordenador debe quedar asi:

```text
/startup.lua
/mjcore/boot.lua
/mjcore/desktop.lua
/mjcore/core/...
/mjcore/apps/...
```

Copia `startup.lua` y la carpeta `mjcore` a la raiz del ordenador.

Despues ejecuta:

```text
reboot
```

## Controles

- Tocar un boton en el monitor: abrir aplicacion.
- Flechas: cambiar seleccion.
- Enter o espacio: abrir aplicacion.
- Q: cerrar el escritorio.

## Configuracion

Edita:

```text
/mjcore/core/config.lua
```

La escala por defecto es:

```lua
textScale = 0.5
```

Para un monitor 4x4 suele funcionar bien. Si el texto sale demasiado pequeño o grande, prueba `1`, `0.5` o `1.5`.

## Siguiente fase

La siguiente aplicacion sera el inventario conectado al Storage Controller de Functional Storage.
