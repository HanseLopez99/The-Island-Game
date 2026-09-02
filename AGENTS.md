# TheIsland — instrucciones para agentes

## Contexto rápido

TheIsland es un FPS de Roblox sincronizado con Rojo 7.7.0. El archivo `default.project.json` representa el MatchPlace, no el Lobby. El MatchPlace contiene rondas, zonas de captura, armas, ViewModels, HUD, brújula y minimapa.

## Reglas importantes

- No sincronizar este proyecto sobre el Lobby.
- Antes de aceptar una sincronización de Rojo, revisar que no haya papeleras rojas. Las líneas verdes son adiciones y las azules son actualizaciones.
- El MatchPlace original está respaldado en `TheIsland.rbxl`.
- Las instancias del mapa y assets que aún no están en `src` deben conservarse. La configuración usa `$ignoreUnknownInstances` y archivos `init.meta.json` para evitar borrados accidentales.
- Mantener el contenedor real `StarterPlayer.StarterPlayerScripts`; no crear una carpeta genérica duplicada con ese nombre.
- Usar rutas existentes y conservar cambios del usuario que no estén relacionados con la tarea.
- Validar cambios con `rojo build default.project.json` y `git diff --check`.

## Arquitectura de combate actual

- `src/ReplicatedStorage/Modules/CombatState.lua`: estado compartido del cliente (`Aiming`, `ADSLocked`, `ADSReady`, `Firing`, `Reloading`) y eventos de comandos.
- `src/StarterPlayer/StarterPlayerScripts/MobileCombatController.client.lua`: controles táctiles de Fire, Aim y Reload.
- `src/StarterPlayer/StarterPlayerScripts/ViewModelController.client.lua`: ViewModel, ADS, FOV, recoil y animación de recarga.
- `src/ReplicatedStorage/Weapons/AssaultRifle/Shoot.client.lua`: disparo, munición, recarga y controles de PC; no debe leer directamente botones móviles.

## Pendientes conocidos

- La munición sí recarga, pero la animación visual de recarga y el comando desde `ReloadButton` todavía deben verificarse/corregirse en Studio.
- No asumir que una compilación de Rojo equivale a una prueba dentro de Studio; probar respawn, ADS, disparo y recarga en Play.
