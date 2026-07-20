# M&J Core v0.3.1 — Foundation

La primera versión con arquitectura modular real.

## Novedades

- Nueva pantalla de arranque inspirada en el logo.
- Escritorio rediseñado.
- Gestor dinámico de aplicaciones mediante `apps.json`.
- API base para aplicaciones.
- Sistema de notificaciones.
- Logger del sistema.
- Widgets reutilizables:
  - Botones
  - Bordes
  - Barras de progreso
  - Diálogos
  - Notificaciones
- Copia de seguridad durante las actualizaciones.
- Comando `mj logs`.

## Repositorio

Este paquete está configurado para:

```text
j0gar/ATMproyecto
```

## Instalación nueva

```text
wget run https://raw.githubusercontent.com/j0gar/ATMproyecto/main/install.lua
```

## Actualizar una instalación existente

Después de subir estos archivos a GitHub:

```text
mj update
```

## Comandos

```text
mj start
mj update
mj version
mj logs
mj help
```

## Registro de aplicaciones

Las aplicaciones se declaran en:

```text
/mjcore/data/apps.json
```

Añadir una nueva aplicación ya no requiere modificar el escritorio.

## Controles

- Tocar una aplicación: abrir.
- Flechas: seleccionar.
- Enter o espacio: abrir.
- Escape o retroceso: volver desde una app.
- Q: cerrar el escritorio.

## Próxima versión

La v0.4 estará centrada en el inventario conectado al Storage Controller de Functional Storage.


## Cambio v0.3.1

- Nuevo logo pixel art en el arranque.
- Emblema hexagonal gris con letras M y J.
- Barra de carga animada de aproximadamente 2,7 segundos.
- Transición automática al escritorio.
