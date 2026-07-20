# M&J Core v0.4.0 — TouchUI

La primera versión pensada para manejarse completamente desde el monitor táctil.

## Cambios principales

- Botones del escritorio más pequeños y compactos.
- Tarjetas de 3 columnas con mejor aprovechamiento del monitor 4×4.
- Fondo técnico discreto y barra de estado inferior.
- Aplicación de inventario real para Functional Storage.
- Inventario con:
  - paginación táctil;
  - ordenar por cantidad;
  - ordenar por nombre;
  - ordenar por mod;
  - sincronización manual;
  - cantidades combinadas por objeto.
- Nueva aplicación Sistema.
- Reinicio y apagado desde el monitor.
- Actualizador gráfico mantenido.
- Uso diario sin comandos ni teclado.

## Instalación

Sube el contenido de este ZIP a la raíz del repositorio y usa una vez el botón ACTUALIZAR de la versión instalada.

Después de actualizar, M&J Core arrancará como v0.4.0.

## Estructura esperada en GitHub

```text
ATMproyecto/
├── install.lua
├── manifest.json
├── version.json
├── startup.lua
├── mj.lua
└── mjcore/
```

## Notas del inventario

El sistema busca primero un periférico de tipo:

```text
functionalstorage:storage_controller
```

También intenta encontrar automáticamente un inventario compatible como alternativa.
