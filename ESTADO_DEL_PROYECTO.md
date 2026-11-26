# Estado del proyecto — Terraform Toss

> Este archivo es la bitácora compartida del equipo (los 2 cofundadores y sus respectivos Claude).
> Al abrir una sesión nueva de Claude en este repo: **lee este archivo primero** para saber en qué
> se quedó el proyecto, qué sigue y qué está roto. Al terminar algo relevante, **añade una entrada
> nueva arriba del todo** (no borres el historial de abajo) con fecha y qué cambió.
>
> Fuente de verdad del diseño: `docs/CONTEXTO_PROYECTO.md` y `docs/PLAN_MAESTRO.pdf`.
> Reglas técnicas obligatorias: `CLAUDE.md` (raíz del repo).

---

## 2026-11-25 (11) — Sesión larga de pruebas dinámicas + 3 PR nuevos (#2, #3, #4)

**Importante — Rojo sigue sin reconectar:** confirmado varias veces a lo largo de la sesión que el
plugin de Rojo en Studio no se reconecta solo (se desconectó cuando terminó la sesión de terminal
de la entrada (5)/(7)) y esta sesión no tiene forma de hacer clic en "Connect" de su panel (el MCP
solo simula input de JUGADOR durante Play, no clics en la UI del editor). **Hace falta que alguien
abra Studio y haga clic en "Connect" en el panel de Rojo** para poder probar de verdad dentro de
Studio lo de abajo (correr `TestRunner.run()` real, ver el botón "Índice", confirmar la tienda
oculta los primeros 3 minutos). Mientras tanto, el place abierto en Studio sigue en el estado de la
entrada (5) — sin el PR #1 ni ninguno de los PR nuevos de hoy — y toda la lógica nueva se validó
pegándola directo por `execute_luau` contra los módulos ya cargados, más `selene`/`stylua` limpios.

**Hecho — jugué una partida real en Studio (Play, sin Rojo) para probar dinámicamente lo que la
auditoría estática de la entrada (8) no cubría:** `RateLimiter` (ráfagas reales en 5 RemoteEvents
distintos), `Validate` (claves con estilo SQL-injection, strings de 100 caracteres, tipos erróneos),
`PolicyGate` (fallback restrictivo simulando que falla `GetPolicyInfoForPlayerAsync`), cooldowns con
el reloj del servidor. **Nada crasheó, nada se saltó ningún límite.** Repetida también la auditoría
de backdoors (`loadstring`, `getfenv`, `setfenv`, `_G`, `HttpService`, `InsertService`,
`TeleportService`, `RemoteFunction`) con `script_grep` sobre el juego YA CARGADO en Studio, no solo
el repo: limpio. Releí también el 100 % de `src/` (los 33 archivos) buscando discrepancias entre el
código y `docs/CONTEXTO_PROYECTO.md`.

**3 Pull Requests nuevos (ninguno mergeado todavía — cada uno necesita revisión del otro
cofundador, como siempre; yo no mergeo PRs):**
- [`#2`](https://github.com/ChinoDFO/terraform-toss/pull/2) `test/pruebas-dinamicas-servidor`: las
  pruebas de arriba + 5 pruebas permanentes nuevas en `TestRunner.luau` (10→15) + un bug real pero
  menor: `Formulas.luck()` no recortaba al tope de diseño (`Rarities.MAX_LUCK=5`). **Sin riesgo real
  para la jugabilidad** porque `Odds.forLuck` ya tenía su propio recorte interno — el único efecto
  era que el atributo `Luck` que ve el jugador en el HUD podía mostrar un número por encima del
  tope documentado una vez hubiera más contenido. Arreglado reusando `Rarities.MAX_LUCK` (sin
  inventar una constante nueva). De paso, agregué `.gitattributes` (stylua.toml ya pedía LF pero sin
  `.gitattributes` Git en Windows revisa con CRLF, así que `stylua --check` marcaba sucio TODO el
  repo sin ningún cambio real).
- [`#3`](https://github.com/ChinoDFO/terraform-toss/pull/3) `feat/indice-criaturas` (**sale del #2,
  mergear ese primero** — su prueba nueva da por hecho las 15 del #2): primer pedazo de "índice" de
  la Semana 2 (`docs/CONTEXTO_PROYECTO.md` §6) — botón nuevo en el HUD que lista las 30 criaturas y
  marca cuáles ya se descubrieron (nombre+rareza) o "???" si siguen bloqueadas. Un solo atributo
  numérico nuevo (`DiscoveredMask`, un bit por criatura, decodificado con `bit32`) en vez de un
  RemoteEvent nuevo.
- [`#4`](https://github.com/ChinoDFO/terraform-toss/pull/4) `feat/ftue-tienda-delay`
  (independiente de los otros dos, sale de `master`): la regla de FTUE "sin ventanas de compra los
  primeros 3 minutos" (`docs/CONTEXTO_PROYECTO.md` §2) estaba documentada pero **no implementada**
  — la tienda estaba disponible desde el segundo 0 de cada sesión. Arreglado servidor (rechaza
  `RequestPurchase` con aviso amable) + cliente (botón oculto hasta que toca), mismo patrón de
  `os.time()` que ya usa `BloomUntil`. Diario y Huevos gratis NO se tocaron (el FTUE documentado solo
  habla de compras).

**Pendiente / decisiones abiertas:**
- Reconectar Rojo (clic manual, ver arriba) y correr `TestRunner.run()` real + un playtest de cada
  PR nuevo antes de aprobarlos.
- Los mismos pendientes de siempre: invitar al segundo cofundador (falta su usuario de GitHub),
  nombre/reparto del equipo, revisar el PR #1 (HUD/sonidos — sigue abierto, intacto, sin tocar en
  esta sesión).

**Siguiente paso sugerido (en orden):**
1. Abrir Studio y hacer clic en "Connect" en el panel de Rojo (es el plugin de Rojo, un panel
   aparte del MCP de Studio — éste último ya está bien, no hace falta tocarlo).
2. Con Rojo conectado: correr `TestRunner.run()` (debería dar 16/16 sumando el #2 y el #3) y hacer
   un playtest manual de cada PR antes de aprobarlo (especialmente el botón "Índice" y que la
   tienda tarde de verdad 3 minutos en aparecer).
3. Revisar y mergear en el orden que tiene más sentido por las dependencias: `#2` → `#3` (depende
   del #2) → `#4` (independiente) → `#1` (el más viejo, HUD/sonidos, independiente de todo esto).
4. Seguir con el resto de la Semana 1/2 (`docs/CONTEXTO_PROYECTO.md` §6).

---

## 2026-11-25 (10) — Confirmado: el MCP de Studio YA carga en esta sesión (app de escritorio) tras mover el directorio

**Hecho:**
- Se confirma la hipótesis de la entrada (9): el problema era solo el directorio de trabajo de la
  sesión, no el registro del MCP. Tras moverla a la carpeta del repo, las herramientas de
  `Roblox_Studio` (`execute_luau`, `search_game_tree`, `start_stop_play`, `get_console_output`,
  `screen_capture`, y varias más de generación de mallas/materiales/texturas) aparecen con
  normalidad en esta sesión de la **app de escritorio**.
- Corridas las 10 pruebas de `tests/TestRunner.luau` vía `execute_luau`
  (`return require(game:GetService("ServerStorage").Tests.TestRunner).run()`):
  **10 OK, 0 fallos** — mismo resultado que la sesión de terminal (entrada 5).
- Studio tiene un solo place abierto (`Place1`, sin publicar — `persistedToCloud: false`, esperado
  para pruebas locales con `game.GameId == 0`), en modo **Edit** (datamodel disponible: solo
  `Edit`; no está en modo Play).
- **Corrección a lo dicho en las entradas (5) y (8):** no es cierto que el registro de
  `Roblox_Studio` sea exclusivo de la sesión de terminal. El MCP está en `~/.claude.json` **a nivel
  de proyecto** (ruta exacta del repo) y lo puede usar cualquier sesión —de terminal o de la app de
  escritorio— siempre que arranque (o se mueva, con la herramienta de cambio de directorio) parada
  en la carpeta del repo.

**Esta sesión queda para:** playtest (`start_stop_play`), pruebas, generación de mallas/materiales,
y auditoría del place vía MCP — como pedía la tarea que la creó. Para git/GitHub/planeación sigue
sirviendo la otra sesión (app de escritorio, sin MCP de Studio).

**Siguiente paso sugerido (en orden):**
1. Playtest manual (`start_stop_play`) para confirmar que el bucle central sigue íntegro tras los
   últimos cambios de HUD/sonidos del PR #1 (todavía sin mergear).
2. Seguir con el resto de la Semana 1 (`docs/CONTEXTO_PROYECTO.md` §6) usando esta sesión para la
   parte que necesite Studio.
3. Sigue pendiente: invitar al segundo cofundador al repo de GitHub (falta su usuario).

---

## 2026-11-25 (9) — Diagnóstico: por qué esta sesión (otra pestaña Code) tampoco tenía el MCP de Studio

**Importante — esto corrige/completa la entrada (8):** no era (solo) que hiciera falta "reiniciar la
sesión" en abstracto. Esta sesión nueva de la app de escritorio (pestaña Code) **arrancó con el
directorio de trabajo en `C:\Users\dfofl`** (la carpeta de usuario), **no** en la carpeta del repo.
El MCP `Roblox_Studio` está registrado en `~/.claude.json` **a nivel de proyecto**, bajo la clave
exacta `C:/Users/dfofl/PP/ROBLOX GAMES/TERRAFORM/terraform-toss` (apunta a
`%LOCALAPPDATA%\Roblox\mcp.bat`). Como la sesión no estaba parada en esa carpeta, nunca cargó esa
config — ni `execute_luau` ni el resto de herramientas de Studio aparecieron (confirmado con
`ToolSearch` buscando "roblox"/"execute_luau"/"studio" → nada, y con `claude mcp list` desde el
Bash de esta sesión → solo Docs/Notion/Google Drive, sin `Roblox_Studio`).

**Hecho:**
- Confirmado leyendo `~/.claude.json` a mano que el MCP `Roblox_Studio` SÍ existe, pero registrado
  solo para la ruta de proyecto exacta del repo, no para la carpeta de usuario donde arrancó esta
  sesión.
- Usada la herramienta de la app (`change_directory`) para mover esta sesión a la carpeta del repo
  (`C:\Users\dfofl\PP\ROBLOX GAMES\TERRAFORM\terraform-toss`). El resultado de la herramienta es
  explícito: el cambio queda aplicado **recién al terminar este turno**, y esta sesión **no se
  vuelve a invocar sola** cuando eso pasa. Por eso la confirmación real de que las herramientas de
  Studio cargan (y correr las 10 pruebas) queda pendiente para el siguiente mensaje/turno, no de
  esta misma entrada.

**Pendiente (siguiente turno, en esta misma sesión):**
- Verificar de nuevo las herramientas de Studio (`execute_luau`, `search_game_tree`,
  `start_stop_play`, `get_console_output`, `screen_capture`) ahora que el directorio de trabajo es
  el correcto.
- Si cargan: correr `return require(game:GetService("ServerStorage").Tests.TestRunner).run()` y
  confirmar 10/10 (como en la sesión de terminal de la entrada (5)).
- Si SIGUEN sin cargar: el problema no era (solo) el directorio — probar cerrar y reabrir esta
  sesión por completo (no solo cambiar de carpeta) para que la app de escritorio relea
  `mcpServers` de `~/.claude.json`.

**Siguiente paso sugerido (en orden):**
1. Escribir cualquier mensaje a esta sesión para que arranque un turno nuevo ya en la carpeta del
   repo, y repetir la verificación de las herramientas de Studio.
2. Si confirma: correr las 10 pruebas y dejar esta sesión como la de playtest/Studio (el objetivo
   original de la tarea que la creó).
3. Si no confirma: cerrar y volver a abrir esta sesión (no solo cambiar de carpeta) para forzar la
   relectura del MCP registrado; si tampoco así aparece, revisar si `%LOCALAPPDATA%\Roblox\mcp.bat`
   existe y corre bien a mano (fuera de Claude) antes de seguir sospechando de la sesión.

---

## 2026-11-25 (8) — PR del HUD/sonidos abierto + auditoría de código (sesión de la app de escritorio)

**Importante sobre las dos sesiones de Claude en esta máquina:** hay una sesión de **terminal**
(`claude` en una consola) con el MCP `Roblox_Studio` conectado — esa es la única que puede usar
`execute_luau`, `start_stop_play`, etc. Esta sesión (la de la **app de escritorio**, pestaña Code)
registró el mismo MCP en su propia config (`claude mcp add ... Roblox_Studio`), pero **no carga
las herramientas de Studio en caliente**: haría falta reiniciar esta sesión para tenerlas, y aun
así cada `claude mcp add` es local a quien lo corrió. En resumen: **para playtest/pruebas en
Studio, usa la sesión de terminal; para git/GitHub/revisión de código, cualquiera de las dos
sirve.** Dile esto a tu cofundador si abre su propia sesión aquí para que no se confunda buscando
herramientas de Studio donde no están.

**Hecho:**
- Revisados los cambios sin commitear que dejó la sesión de terminal (HUD 2 decimales + barra
  mínima, sonidos y partículas del lanzamiento: `Config/Sfx.luau`, `UI/Sfx.luau`, `UI/Vfx.luau`,
  `HudController.luau`, `ThrowController.luau`). Todo limpio: `--!strict`, sin patrones prohibidos,
  solo cliente/cosmético, no toca nada autoritativo del servidor.
- `selene src` (0 errores, el único warning es el preexistente de `Odds.luau`, no relacionado) y
  `stylua --check src tests` (limpio) — confirmado desde esta sesión con los binarios de Rokit
  (`%USERPROFILE%\.rokit\bin\`; nota: esa carpeta no estaba en el PATH de esta sesión aunque la
  otra sesión ya la instaló — hubo que llamarlos por ruta completa).
- Commit `1b0a01b` en la rama `feat/hud-planeta-sonidos` + push + **PR abierto**:
  [`#1`](https://github.com/ChinoDFO/terraform-toss/pull/1) — estado `OPEN`, `MERGEABLE`, sin
  revisión todavía (correcto: lo tiene que revisar el otro cofundador, no lo fusiono yo). No hay
  CI configurado en el repo (esperado, no es un bloqueo en esta etapa).
- **Auditoría de seguridad/correctitud** de todo el código del servidor y la lógica compartida
  crítica (`DataService`, `PurchaseService`, `PolicyGate`, `ThrowService`, `EconomyService`,
  `CreatureService`, `TerraformService`, `DailyService`, `PlusService`, `Main.server`, `Net`,
  `Formulas`, `Odds`, `WeightedRandom`, `Validate`, `RateLimiter`, `Perks`, `Retry`, `Meter`,
  `Zones`) y de la tienda del cliente (`ShopController`, `PriceService`): **no se encontraron
  bugs.** Confirmado explícitamente que SÍ se cumplen las reglas no negociables de `CLAUDE.md`:
  servidor autoritativo en todo, `RateLimiter`/`Validate` en cada RemoteEvent, bloqueo de sesión +
  backoff + `BindToClose` en `DataService`, `ProcessReceipt` idempotente, `PolicyGate` con modo
  restrictivo por defecto si falla la consulta, pity del Huevo Estelar, confirmación en dos pasos
  ≥ 400 R$ (`Products.CONFIRM_THRESHOLD_ROBUX`, usado en `ShopController`), botón de compra activo
  recién después de 1 s, precios siempre vía `GetProductInfoAsync` (`PriceService`, con caché de
  60 s), probabilidades visibles con el *pity* y el aviso de redondeo. Pesos verificados a mano:
  rarezas 62+25+10+2.7+0.3 = 100, huevo 75+22+3 = 100, mutaciones suman 100.
- Revisado `repos/ChinoDFO/terraform-toss/collaborators`: **solo está `ChinoDFO`.** El segundo
  cofundador todavía NO está invitado — falta su usuario de GitHub para invitarlo.

**Pendiente / decisiones abiertas (sin cambios de fondo, solo para que no se pierdan):**
- Invitar al segundo cofundador al repo de GitHub (falta su usuario).
- Nombre definitivo del juego/estudio y reparto de ingresos (decisión de los 2, no de Claude).
- Balance del ritmo del planeta: con solo lanzamientos Comunes (peor caso) son ~9.216 lanzamientos
  entre todos para llegar a 100 %; en la práctica la suerte sube con las criaturas descubiertas
  (hasta ×5), así que el ritmo real debería ser más rápido que ese peor caso. No se tocó ningún
  número de `Config/Rarities.luau` — es una decisión de balance que conviene confirmar con un
  playtest real de varios jugadores a la vez, no con matemática de escritorio.

**Siguiente paso sugerido (en orden):**
1. El otro cofundador revisa y aprueba (o pide cambios) en el [PR #1](https://github.com/ChinoDFO/terraform-toss/pull/1).
2. Conseguir su usuario de GitHub e invitarlo como colaborador.
3. Con los dos conectados: decidir nombre/reparto, y repartirse Semana 1 (`docs/CONTEXTO_PROYECTO.md`
   §6) — código para quien tenga Claude en terminal con Studio conectado, mapa/arte en Team Create
   para el otro.

---

## 2026-11-25 (7) — Playtest confirmado + arreglo de la barra del planeta

**Hecho:**
- Playtest real en Studio (vía MCP desde terminal, `start_stop_play` + trazas temporales sin tocar
  `src/`): el lanzamiento llega al servidor, el servidor decide (rareza, zona, celdas) y el cliente
  recibe `ThrowResult` bien. El dinero y el Poder suben con normalidad. **El bucle central funciona
  de punta a punta.**
- **Encontrado (no era un bug de lógica, sí de interfaz):** con 1.024 celdas visuales, el primer
  lanzamiento solo sube `PlanetPercent` ~0,03 %, y `HudController` lo redondeaba a 1 decimal → se
  veía "0.0 %" aunque el valor real ya había subido. Sensación de "esto no sirve de nada" en los
  primeros lanzamientos.
- **Arreglado** en `HudController.luau`: ahora muestra 2 decimales mientras el porcentaje sea menor
  a 1 % (p. ej. "0.03 %"), y la barra visual tiene un ancho mínimo del 1 % en cuanto hay algo de
  avance (puramente cosmético, el valor real que manda el servidor no cambia). `selene`/`stylua`
  limpios.
- Confirmado que el error de consola `rbxassetid://203785492` ("Pop Close Sound") **no viene de
  nuestro código** (no está en `src/`, nuestros sonidos usan `rbxasset://sounds/...` del motor) —
  es de un plugin de Studio o la UI interna, se puede ignorar.

**Siguiente paso sugerido (en orden):**
1. Repetir el playtest para confirmar que el porcentaje del planeta ya se ve bien desde el primer
   lanzamiento, y que los sonidos/efectos de la entrada anterior se sienten bien jugando.
2. Seguir con el resto de la Semana 1 (`docs/CONTEXTO_PROYECTO.md` §6): más pulido del bucle central
   si aparece algo raro, y coordinar con Dev B la plataforma/mapa (no es código).
3. Invitar al segundo cofundador como colaborador del repo (pendiente de entradas anteriores).

---

## 2026-11-25 (6) — Semana 1, tarea 1: sonidos y efectos del lanzamiento

**Hecho (solo cliente, cosmético — no toca nada del servidor ni las pruebas):**
- `src/shared/Config/Sfx.luau`: tabla de sonidos con rutas `rbxasset://sounds/...` (built-in del
  motor de Roblox, gratis y sin licencia) marcados como **TEMPORALES** — sustituir por audio
  propio/licenciado antes de publicar. Verificadas contra una lista de rutas clásicas confirmadas
  (no inventadas): `electronicpingshort.mp3` (carga/bloom), `switch.mp3` (suelta), `splat.mp3`
  (aterrizaje), `snap.mp3` (revelación de rareza Épica/Legendaria), `victory.mp3` (planeta
  restaurado).
- `src/client/UI/Sfx.luau`: helper para reproducir sonido de un solo disparo (`play`) y en bucle
  controlable (`startLoop`/`stopLoop`), con limpieza automática vía `Debris`.
- `src/client/UI/Vfx.luau`: estallido de partículas al aterrizar una cápsula, con el color de la
  rareza; usa el `ParticleEmitter` sin textura propia (círculo blanco del motor), cero assets
  nuevos.
- `ThrowController.luau`: sonido de carga en bucle con el tono subiendo según el medidor, sonido de
  suelta al lanzar, y sonido + partículas al aterrizar la cápsula (propia o de otro jugador).
- `HudController.luau`: sonido extra cuando tu propio lanzamiento sale Épico o Legendario, y
  sonidos distintos para Bloom y Planeta Restaurado.
- `selene src` (0 errores, mismo warning preexistente de `Odds.luau`) y `stylua --check src` (limpio).

**Pendiente de verificar (necesita Studio — hazlo en la sesión de terminal con `claude`):**
- Jugar una ronda real: cargar y soltar LANZAR (oír el tono subir y el "click" de suelta), ver el
  estallido de partículas al aterrizar, y si sale Épico/Legendario o toca un Bloom/100 %, confirmar
  que se oyen los sonidos nuevos y no se cruzan mal entre sí con varios jugadores lanzando a la vez.
- Las 10 pruebas de `TestRunner.luau` no deberían verse afectadas (nada de esto es servidor), pero
  conviene correrlas de nuevo después del próximo cambio de servidor.

**Siguiente paso sugerido (en orden):**
1. Playtest manual de este cambio (sonidos/efectos) en Studio.
2. Seguir con el resto de la Semana 1 (`docs/CONTEXTO_PROYECTO.md` §6): pulir bucle central/HUD si
   algo se siente raro al jugar, y coordinar con Dev B la plataforma/mapa (no es código).
3. Invitar al segundo cofundador como colaborador del repo (pendiente de entradas anteriores).

---

## 2026-11-25 (5) — MCP de Studio confirmado y 10/10 pruebas pasadas

**Hecho:**
- Confirmado que el MCP `Roblox_Studio` conecta bien desde una sesión de terminal con el CLI
  `claude` (Studio abierto + interruptor "Enable Studio as MCP server" activo). **Importante:** esa
  conexión es un registro *local* del CLI (`claude mcp add ... Roblox_Studio`, scope "Local config,
  private to you in this project") — **no** se ve desde la app de escritorio de Claude Code (ahí no
  aparece como conector de la sesión). Para usar `execute_luau`/`start_stop_play`/etc. hay que hacerlo
  desde una terminal normal corriendo `claude`, no desde el chat de la app de escritorio.
- Corridas las 10 pruebas de `tests/TestRunner.luau` vía `execute_luau` desde esa sesión de terminal:
  **10 OK, 0 fallos** (rarezas base suman 100 %, `Odds.forLuck` suma 100 % para toda suerte, más suerte
  nunca baja la probabilidad de Legendario, Huevo Estelar con mínimo Raro y pity a Legendario, mutaciones
  suman 100 %, `WeightedRandom` respeta pesos en 10.000 tiradas ±1,5 %, medidor en rango [0,1] con
  multiplicador correcto, `NumberFormat`, 30 criaturas con zona/rareza válidas, zonas ordenadas por
  distancia).
- Rojo ya conectado y sincronizando el place completo: `ServerScriptService.Server` (16 descendientes)
  y `StarterPlayerScripts.Client` (9 descendientes) están arriba. El place queda listo para playtest.

**Siguiente paso sugerido (en orden):**
1. Playtest manual en Studio (`start_stop_play` o manual) para validar el bucle central end-to-end.
2. Empezar Semana 1 del calendario (`docs/CONTEXTO_PROYECTO.md` §6, 30 nov – 6 dic): bucle central
   sólido, plataforma, HUD, efectos, sonidos.
3. Seguir invitando al segundo cofundador como colaborador del repo (pendiente de la entrada anterior).

---

## 2026-11-25 (4) — Repo en GitHub creado y sincronizado

**Hecho:**
- Se instaló GitHub CLI (`gh` 2.105.0, vía winget) y el usuario inició sesión con su cuenta
  (`ChinoDFO`) vía `gh auth login` (dispositivo/navegador).
- Repo creado en GitHub: **privado**, bajo la cuenta personal del usuario —
  `https://github.com/ChinoDFO/terraform-toss`. Remoto `origin` configurado, rama `master`
  pusheada y en seguimiento de `origin/master`. Commits `080d781` y `d1e6c6b` ya están en remoto.
- **Pendiente:** invitar al segundo cofundador como colaborador del repo (Settings → Collaborators
  en GitHub), y decidir si en algún momento se mueve a una organización/grupo en vez de la cuenta
  personal.

**Siguiente paso sugerido (en orden):**
1. Invitar al otro cofundador como colaborador del repo.
2. Decidir nombre/reparto de equipo (pendiente de los cofundadores, ver entrada de abajo).
3. Abrir Studio, activar el MCP, confirmar conexión, correr las 10 pruebas de `TestRunner.luau`.
4. Seguir con la Semana 1 del calendario (`docs/CONTEXTO_PROYECTO.md` §6).

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
