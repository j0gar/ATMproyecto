# M&J Core

Sistema modular para CC:Tweaked diseñado para un monitor avanzado de 4x4 bloques.

## Versión 0.2.1

Novedades:

- Instalador desde GitHub.
- Actualizador automático.
- Comando `mj`.
- `manifest.json` para controlar archivos.
- `version.json` para comprobar versiones.
- Copia de seguridad antes de actualizar.
- Aplicación de actualización en el escritorio.

## Preparar GitHub

Sube todo el contenido de esta carpeta a la raíz del repositorio:

```text
MJ-Core/
├── install.lua
├── manifest.json
├── version.json
├── startup.lua
├── mj.lua
└── mjcore/
```

El repositorio debe ser público para que CC:Tweaked pueda descargar los archivos sin autenticación.

El proyecto apunta a:

```text
https://github.com/j0gar/ATMproyecto
```

Si tu nombre de usuario es distinto, cambia `owner` en:

```text
install.lua
mjcore/core/config.lua
```

## Instalación en CC:Tweaked

Con HTTP activado:

```text
wget run https://raw.githubusercontent.com/j0gar/ATMproyecto/main/install.lua
```

Después se reiniciará solo.

## Comandos

```text
mj start
mj update
mj version
mj help
```

## Actualizaciones

Cuando subas una versión nueva a GitHub:

1. Cambia la versión en `version.json`.
2. Cambia `version` en `mjcore/core/config.lua`.
3. Añade cualquier archivo nuevo a `manifest.json`.
4. En Minecraft ejecuta:

```text
mj update
```

Las versiones anteriores se guardan temporalmente en:

```text
/mjcore_backup
```
