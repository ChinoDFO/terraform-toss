# 9. Arquitectura técnica

## 9.1 Árbol de instancias

```text
game
├── ReplicatedStorage
│   ├── Shared                  (src/shared)      módulos compartidos
│   │   ├── Types               tipos de datos (PlayerData, ThrowResult...)
│   │   ├── Net                 acceso a RemoteEvents y ServerState
│   │   ├── Config/             Rarities, Mutations, Zones, Creatures, Products
│   │   └── Util/               Odds, WeightedRandom, Meter, NumberFormat, Formulas
│   ├── Remotes                 (default.project.json) 10 RemoteEvents
│   └── ServerState             Folder con atributos: Planet, PlanetPercent, BloomUntil
├── ServerScriptService
│   └── Server                  (src/server)
│       ├── Main                Script de arranque
│       ├── Services/           DataService, PolicyGate, PurchaseService, CreatureService,
│       │                       TerraformService, EconomyService, ThrowService,
│       │                       DailyService, PlusService
│       └── Util/               Retry, RateLimiter, Validate, Perks
├── ServerStorage
│   └── Tests                   (tests) TestRunner
├── StarterPlayer
│   └── StarterPlayerScripts
│       └── Client              (src/client)
│           ├── Main            LocalScript de arranque
│           ├── Controllers/    HudController, ThrowController, ShopController
│           └── UI/             Ui, UIPool, PriceService
└── Workspace
    ├── PlanetOrigin            (lo coloca Dev B) inicio de la cuadrícula
    ├── PlanetCells             (lo crea el servidor) 1.024 partes del planeta
    └── Mapa, plataforma, jardines (Team Create, no Rojo)
```

## 9.2 Contrato de RemoteEvents

**C→S** = el cliente pide. **S→C** = el servidor avisa. Ningún evento lleva valores de juego desde el cliente.

| Evento | Dir. | Argumentos | Validación del servidor | Límite |
|---|---|---|---|---|
| `TrainTap` | C→S | ninguno | Perfil cargado | 8/s |
| `ThrowStart` | C→S | ninguno | Enfriamiento 1,2 s; guarda `os.clock()` | 3/s |
| `ThrowRelease` | C→S | ninguno | Debe existir un `ThrowStart` previo; el medidor se calcula con el reloj del servidor | 3/s |
| `SetAutoLaunch` | C→S | `enabled: boolean` | `typeof == "boolean"` y posee el pase | 3/s |
| `BuyUpgrade` | C→S | `kind: "training" \| "capsule"` | Lista blanca; dinero suficiente (servidor) | 5/s |
| `RequestPurchase` | C→S | `key: string` | Lista blanca de `Products`; `id ≠ 0`; PolicyService si es aleatorio; no comprado ya | 2/s |
| `OpenFreeEgg` | C→S | ninguno | `freeEggs > 0` (servidor) | 2/s |
| `ClaimDaily` | C→S | ninguno | No reclamado hoy (día UTC) | 1/s |
| `ThrowResult` | S→todos | `ThrowResult` (tabla) | — | por lanzamiento |
| `Notify` | S→C/todos | `kind: string, data: table` | — | por evento |

**Estado replicado sin eventos:** el servidor escribe **atributos** en el `Player` (`Cash`, `Power`, `IncomePerSec`, `TrainRate`, `Luck`, `TrainingLevel`, `CapsuleLevel`, `BestZone`, `Discovered`, `FreeEggs`, `EggPity`, `DailyStreak`, `DailyAvailable`, `TurboUnlocked`, `PaidRandomRestricted`, `Pass_<clave>`, `PlusPerk`, `BoostUntil`, `AdLuckUntil`, `StarterPackOwned`, `AutoLaunchOn`) y en `ReplicatedStorage.ServerState` (`Planet`, `PlanetPercent`, `BloomUntil`). Un cambio de atributo hecho en el cliente **no se replica** al servidor, así que no se puede falsificar.

## 9.3 Responsabilidad de cada módulo

| Módulo | Responsabilidad | Depende de |
|---|---|---|
| `DataService` | Cargar/guardar con UpdateAsync, bloqueo de sesión (TTL 5 min), backoff, autoguardado (2 min), `BindToClose` (25 s), recibos | Retry |
| `PolicyGate` | `GetPolicyInfoForPlayerAsync`; si falla, modo restrictivo | — |
| `PurchaseService` | Pases (`UserOwnsGamePassAsync`), avisos de compra, `ProcessReceipt` idempotente | DataService, PolicyGate, CreatureService |
| `CreatureService` | Índice, jardín (reemplazo/venta), mutaciones, huevos con pity | Formulas, Odds |
| `TerraformService` | Cuadrícula compartida, Bloom, planeta restaurado | Zones |
| `EconomyService` | Bucle de 1 s: poder, ingresos, sincronización; mejoras; offline | DataService, Terraform, Creature |
| `ThrowService` | Medidor autoritativo, combo, distancia, rareza, resultado; Auto-Lanzar | Todo lo anterior |
| `DailyService` | Racha, Turbo gratis (día 3), huevo gratis (día 7) | DataService, CreatureService |
| `PlusService` | `HasRobloxSubscription` → ventaja | — |
| Cliente (`Hud`, `Throw`, `Shop`) | Solo mostrar y pedir | Shared |

## 9.4 Decisiones técnicas importantes

- **Sin RemoteFunction.** Todo con RemoteEvent de ida y otro de vuelta. Elimina riesgos de `InvokeClient` y bloqueos.
- **Medidor determinista.** `Meter.valueAt(t)` es la misma función en cliente (dibujar) y servidor (decidir). Latencia: el tiempo medido en el servidor incluye la diferencia de latencia entre los dos mensajes, que suele ser de unos pocos milisegundos. Si los jugadores con mala conexión fallan mucho la zona verde, amplíenla (≥ 0,85).
- **Probabilidades = código compartido.** `Odds.forLuck` y `Odds.forEgg` se usan para mostrar y para tirar. Imposible que la tienda diga una cosa y el servidor haga otra.
- **Números grandes:** `number` de Luau (doble precisión) llega a ~10^308, suficiente. `NumberFormat.short` hasta "Dc" (10^33).
- **Rendimiento:** 1.024 partes ancladas sin colisión ni sombras para el planeta. El HUD se refresca 4 veces por segundo (no por señal) y los avisos y proyectiles usan **pools** (`UIPool`).
- **Datos:** un solo registro por jugador `{ data, lock }`. Cambiar `STORE_NAME` borra a todos: no se toca en producción. Para migraciones, `reconcile` rellena campos nuevos; cambios de formato requieren subir `version` y migrar en `reconcile`.

## 9.5 Pruebas

1. **Automáticas** (`tests/TestRunner.luau`, 10 casos): sumas de probabilidades, monotonía de la suerte, pity, mutaciones, distribución del aleatorio, medidor, formato de números, contenido, zonas. Se ejecutan con MCP:

```luau
return require(game:GetService("ServerStorage").Tests.TestRunner).run()
```

2. **Prueba de juego guiada por Claude** (prompt del anexo A.4): inicia la prueba, simula mantener Espacio 0,8 s y soltar 5 veces, lee la consola, comprueba que `Cash` y `PlanetPercent` subieron, captura de pantalla, detiene.
3. **Prueba con 2–4 jugadores** (Studio → Test → Clients and Servers): combos, Bloom, barra compartida.
4. **Prueba de datos:** jugar, salir, volver a entrar en DEV: el progreso debe estar. Cerrar el servidor a la fuerza durante el juego y comprobar que no se pierde (BindToClose).
5. **Prueba de compras en Studio:** las compras en Studio son simuladas y no cobran. Probar cada producto y comprobar que `ProcessReceipt` no entrega dos veces.

## 9.6 Código completo

El código de todos los módulos está en el **anexo B** y en `terraform-toss-starter.zip`. Está escrito para `--!strict`, pero **no se pudo compilar en este entorno** (no hay Roblox Studio aquí). El primer trabajo de Dev A en la semana 0 es: sincronizar con Rojo, abrir la pestaña *Script Analysis* de Studio y la extensión Luau de VS Code, y pedir a Claude que corrija cualquier aviso de tipos que aparezca. Es normal que salgan algunos menores; la lógica está revisada.
