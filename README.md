# M&J Core v0.5.2 — Texto español en monitor

- La app Detector de Mia muestra correctamente `ñ`, `Ñ`, vocales con tilde, `ü`, `¿` y `¡`.
- La `ñ` se representa en el monitor como una `n` con virgulilla en la fila superior, evitando los caracteres UTF-8 corruptos de CC:Tweaked.
- Corregido el usuario predeterminado a `MiaWRaW`.
- Corregido el grosor de la zona del detector: `corner2.z = 74`.
- Se conservan los archivos personales durante la actualización.

## Instalación

```
wget run https://raw.githubusercontent.com/j0gar/ATMproyecto/main/install.lua
```

> El actualizador preserva `mjcore/data/m-Mia.lua`, `mia_detector.lua` y las listas de tareas.
