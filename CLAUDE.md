# Terraform Toss — reglas para Claude (leer siempre)

Juego de Roblox cooperativo: lanzas cápsulas de semillas para restaurar un planeta compartido
(0 % → 100 %). Lanzamiento con medidor, criaturas por rareza, jardín con ingresos/s, suerte por colección.
Equipo: 2 cofundadores. Presupuesto $0 de API. Detalle completo: docs/PLAN_MAESTRO.pdf.

## Stack
- Luau `--!strict` en TODOS los archivos. Rojo 7 (default.project.json) + Git/GitHub. Rokit para herramientas.
- Servidor MCP de Roblox Studio para: inspeccionar, ejecutar Luau, playtest, consola, capturas.
- El código vive en `src/` (fuente de verdad). NO edites scripts dentro de Studio: Rojo los sobrescribe.

## Estructura
- `src/server/` → ServerScriptService.Server (Services/, Util/, Main.server.luau)
- `src/shared/` → ReplicatedStorage.Shared (Types, Net, Config/, Util/)
- `src/client/` → StarterPlayerScripts.Client (Controllers/, UI/, Main.client.luau)
- `tests/` → ServerStorage.Tests (TestRunner.luau)
- RemoteEvents declarados en default.project.json (ReplicatedStorage.Remotes)

## Reglas de seguridad (no negociables)
1. El cliente PIDE, el servidor VALIDA y DECIDE. Nunca confíes en valores del cliente.
2. Todo RemoteEvent: validar tipo (typeof), rango, NaN/inf, lista blanca y RateLimiter.
3. Prohibido: RemoteFunction:InvokeClient, `wait()`, `spawn()`, `delay()`, `Model:SetPrimaryPart`,
   `loadstring`, `getfenv/setfenv`, `require(<número>)`. Usa task.wait/task.spawn/task.delay, PivotTo.
4. DataStore: solo UpdateAsync vía DataService (bloqueo de sesión, backoff, BindToClose).
5. Nada de modelos gratuitos sin pasar el protocolo de auditoría (docs, sección Seguridad).

## Reglas de monetización (no negociables)
- Precios SIEMPRE desde GetProductInfoAsync (precios regionales + descuento Plus). Nunca escritos a mano.
- Artículo aleatorio pagado ⇒ PolicyService (ArePaidRandomItemsRestricted) en servidor, probabilidades
  numéricas visibles ANTES de comprar (suman 100 %), mínimo garantizado, alternativa gratuita.
- La suerte NO se vende (los modificadores de probabilidad pagados cuentan como aleatorio pagado).
- Sin dark patterns: sin temporizadores falsos, sin botones engañosos, confirmación ≥ 400 R$,
  botón de compra activo tras 1 s. Lo pagado acelera lo PERSONAL, nunca bloquea lo compartido.
- Avatares solo R15 (Avatar Settings > R15 Only) para la tasa DevEx EE. UU. 18+.
- Comercio entre jugadores: NO en el MVP.

## Cómo trabajar
- Una tarea pequeña por sesión. Cambios puntuales (edit), no reescribas archivos enteros.
- Antes de codificar: lee el módulo afectado y Types.luau. Después: ejecuta las pruebas:
  `execute_luau` → `return require(game:GetService("ServerStorage").Tests.TestRunner).run()`
- Para probar en juego: start_stop_play → simula input → get_console_output → screen_capture.
- Fórmulas de balance solo en `src/shared/Util/Formulas.luau` y `Config/`.
- Comentarios y textos de UI en español. Nombres de código en inglés.
- Commits: `feat:`, `fix:`, `chore:`, `docs:`. Rama por tarea, PR revisado por el otro cofundador.

## Comandos
- `rokit install` · `rojo serve` · `rojo sourcemap default.project.json -o sourcemap.json`
- `selene src` (lint) · `stylua src tests` (formato)
