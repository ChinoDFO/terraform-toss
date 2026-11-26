# Estado del proyecto — Terraform Toss

> Este archivo es la bitácora compartida del equipo (los 2 cofundadores y sus respectivos Claude).
> Al abrir una sesión nueva de Claude en este repo: **lee este archivo primero** para saber en qué
> se quedó el proyecto, qué sigue y qué está roto. Al terminar algo relevante, **añade una entrada
> nueva arriba del todo** (no borres el historial de abajo) con fecha y qué cambió.
>
> Fuente de verdad del diseño: `docs/CONTEXTO_PROYECTO.md` y `docs/PLAN_MAESTRO.pdf`.
> Reglas técnicas obligatorias: `CLAUDE.md` (raíz del repo).

---

## 2026-11-25 (2) — Rokit instalado y verificado

**Hecho:**
- Rokit instalado en la máquina vía `winget install Rojo.Rokit` (v1.2.0).
- `rokit.toml` completado: se añadieron `stylua = "JohnnyMorganz/stylua@2.6.0"` y
  `selene = "Kampfkarren/selene@0.32.0"` (antes solo tenía `rojo`). Pendiente de commit (todavía no
  hay primer commit en el repo).
- `rokit install` corrido con éxito: los tres binarios (`rojo` 7.6.1, `selene` 0.32.0, `stylua` 2.6.0)
  quedaron en `~/.rokit/bin`. Se añadió esa carpeta al PATH de usuario (antes solo estaba la carpeta
  del `rokit.exe` de WinGet, que por sí sola no expone `rojo`/`selene`/`stylua`). **Hay que abrir una
  terminal nueva para que el PATH actualizado tenga efecto** (esta sesión lo usó con la ruta
  explícita porque la variable de entorno no se recarga en un proceso ya abierto).
- Validado que `selene src` y `stylua --check src tests` corren sin errores de la herramienta:
  - `selene`: 0 errores, 1 warning (`manual_table_clone` en `src/shared/Util/Odds.luau:41`,
    sugiere `table.clone(...)`).
  - `stylua --check`: varias líneas superan el ancho configurado y stylua propone reformatear
    (p. ej. `src/client/UI/Ui.luau`, `PriceService.luau`, `CreatureService.luau`, `PlusService.luau`,
    `PurchaseService.luau`, `HudController.luau`).
- **Formateo aplicado:** se corrió `stylua src tests` (dos pasadas — la primera no converge del
  todo cuando hay llamadas con tablas anidadas, es un detalle conocido de StyLua; la segunda pasada
  sí deja `stylua --check src tests` limpio, exit 0). `selene src` sigue en 0 errores / 1 warning
  (el `manual_table_clone` de `Odds.luau:41`, no se tocó — es una sugerencia de código, no de
  formato). Cambios de formateo sin commitear todavía (sigue sin haber primer commit en el repo).

**Bloqueos / pendiente técnico actualizado:**
- Resuelto: Rokit + Selene + StyLua ya instalados (ver arriba). Lo que seguía bloqueado en la entrada
  de abajo (MCP de Studio sin verificar, pruebas de `TestRunner.luau` sin correr, código nunca abierto
  en Studio) **sigue igual, no se tocó en esta sesión.**

**Siguiente paso sugerido (en orden):**
1. Decidir nombre/reparto de equipo (pendiente de los cofundadores, ver entrada de abajo).
2. Primer commit (`git commit`, ya incluiría el formateo de StyLua) + crear repo privado en
   GitHub + invitar al otro cofundador.
3. Abrir Studio, activar el MCP, confirmar conexión, correr las 10 pruebas de `TestRunner.luau`.
4. Seguir con la Semana 1 del calendario (`docs/CONTEXTO_PROYECTO.md` §6).

---

## 2026-11-25 — Semana 0: arranque local

**Hecho:**
- Se descomprimió `terraform-toss-starter.zip` en esta carpeta (`terraform-toss/`).
- Repo git **inicializado localmente** (`git init`, archivos en *staging*). **Todavía NO hay commit
  ni remoto en GitHub.**
- Se validó con `rojo build` / `rojo sourcemap` que `default.project.json` compila sin errores
  (sin necesidad de abrir Studio) — la estructura de carpetas → servicios de Roblox es correcta.
- Auditoría rápida de patrones prohibidos (`RemoteFunction`, `wait()/spawn()/delay()` crudos,
  `loadstring`, `getfenv/setfenv`, etc.) sobre todo `src/`: **limpio**. Todo usa `task.*` como exige
  `CLAUDE.md`. Los 33 archivos `.luau` en `src/` tienen `--!strict`.
- Se registró el servidor MCP de Roblox Studio en **Claude Code** (`claude mcp add ... Roblox_Studio`).

**Bloqueos / pendiente técnico:**
- **Herramientas no instaladas en esta máquina:** `rokit`, `selene`, `stylua` (sí están `git` y
  `rojo`, pero `rojo` se instaló por winget, no por Rokit — hay que reinstalar vía Rokit para que
  los dos cofundadores usen exactamente la misma versión).
- **Hueco en `rokit.toml`:** solo fija la versión de `rojo`. Le faltan las entradas de `selene` y
  `stylua` (se añaden con `rokit add JohnnyMorganz/StyLua` y `rokit add Kampfkarren/selene`, y hay
  que comitear el `rokit.toml` resultante para que el otro cofundador tenga las mismas versiones).
- **MCP de Studio: configurado pero NO verificado en vivo.** Claude Code tiene la entrada
  `Roblox_Studio` en su config, pero al listarla (`claude mcp list`) da
  `Connected · tools fetch failed — Request timed out`. Eso pasa porque Roblox Studio no estaba
  abierto / el interruptor "Enable Studio as MCP server" no estaba activado durante la prueba.
  **Falta:** abrir Studio, activar ese interruptor (Assistant → … → Manage MCP Servers), y repetir
  `claude mcp list` para confirmar que queda en verde con clientes conectados.
- **Las 10 pruebas de `tests/TestRunner.luau` no se han corrido todavía** (necesitan Studio + MCP
  conectado, o correrlas a mano dentro de Studio con `execute_luau`).
- El código del starter **nunca se abrió dentro de Studio**, así que Script Analysis (errores de
  tipos de `--!strict`) no se ha verificado de verdad — la validación de arriba fue solo estructural
  (Rojo), no de tipos Luau.

**Decisiones de equipo pendientes (no son técnicas, son de los 2 cofundadores):**
- Nombre definitivo del juego y del estudio/grupo.
- Reparto de ingresos entre cofundadores (acuerdo por escrito, ver `docs/src/04_setup.md` §6.2).
- Quién es "Dev A" (crea el grupo de Roblox y la organización de GitHub) y quién "Dev B".
- Verificar en Creator Hub el precio actual de crear un grupo y los requisitos vigentes de
  Kids & Select antes de pagar nada.

**Siguiente paso sugerido (en orden):**
1. Instalar Rokit en esta máquina y correr `rokit install` dentro de esta carpeta.
2. Decidir nombre/reparto (lo de arriba) para poder nombrar bien el grupo y el repo.
3. Primer commit (`git commit`) + crear repo privado en GitHub + invitar al otro cofundador.
4. Abrir Studio, activar el MCP, confirmar conexión, correr las 10 pruebas de `TestRunner.luau`.
5. Seguir con la Semana 1 del calendario (`docs/CONTEXTO_PROYECTO.md` §6): bucle central, HUD,
   plataforma.

---
