# TheIsland — contexto del proyecto

## Qué es

Proyecto FPS multijugador de Roblox. El repositorio local se sincroniza mediante Rojo con el MatchPlace de una experiencia cuyo Lobby es otro place independiente.

## Estructura principal

```text
MatchPlace/default.project.json
MatchPlace/src/
├── ReplicatedStorage/
│   ├── Modules/
│   │   ├── CombatState.lua
│   │   └── ViewportRenderer.lua
│   ├── Weapons/
│   │   ├── AssaultRifle/
│   │   │   ├── Shoot.client.lua
│   │   │   └── Damage.server.lua
│   │   └── Sword/
│   ├── WeaponData.lua
│   └── ZoneData.lua
├── ServerScriptService/
│   ├── SpawnManager.server.lua
│   ├── RoundSystem.server.lua
│   ├── CombatServer.server.lua
│   └── ZoneResetManager.lua
├── StarterPlayer/StarterPlayerScripts/
│   ├── MobileCombatController.client.lua
│   ├── ViewModelController.client.lua
│   ├── WeaponController.client.lua
│   └── Sprint.client.lua
├── StarterGui/
└── Workspace/
    ├── MapZones/
    └── Decoration/
```

## Flujo de combate

```text
PC: mouse/teclado ─┐
                   ├─> CombatState ─> Shoot / ViewModelController
Móvil: botones ────┘
```

En móvil, mantener `FireButton` activa ADS, espera `ADSReady` y luego dispara. Soltarlo detiene el fuego y sale de ADS si `ADSLocked` está desactivado. `AimButton` alterna el ADS bloqueado. `ReloadButton` solicita una recarga.

## Objetos esperados en Studio

```text
PlayerGui
└── MobileFireGui
    ├── FireButton
    ├── AimButton
    └── ReloadButton
```

`ReloadButton` puede estar dentro de un Frame, pero debe llamarse exactamente así.

## Rojo y recuperación

El respaldo local es `TheIsland.rbxl`. Para recuperar el MatchPlace se publicó ese archivo sobre el place existente `MatchPlace`, sin crear un place nuevo.

Rojo debe conectarse al proyecto correspondiente: `MatchPlace/default.project.json` para el MatchPlace y `Lobby/default.project.json` para el Lobby. Los servicios principales del MatchPlace están configurados para conservar instancias que aún no están representadas en el repositorio, incluyendo Terrain, modelos del mapa, assets de Brushtool y objetos antiguos del HUD.

## Verificación mínima después de cambios

1. Ejecutar `rojo build MatchPlace/default.project.json`.
2. Ejecutar `rojo build Lobby/default.project.json` si el cambio afecta al Lobby.
3. Ejecutar `git diff --check`.
4. En Studio, detener y reiniciar Play.
5. Probar equipamiento, ADS antes y después de respawn, disparo PC/móvil y recarga.
