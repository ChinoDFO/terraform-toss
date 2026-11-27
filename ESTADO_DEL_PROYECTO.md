# Estado del proyecto — Terraform Toss

> Este archivo es la bitácora compartida del equipo (los 2 cofundadores y sus respectivos Claude).
> Al abrir una sesión nueva de Claude en este repo: **lee este archivo primero** para saber en qué
> se quedó el proyecto, qué sigue y qué está roto. Al terminar algo relevante, **añade una entrada
> nueva arriba del todo** (no borres el historial de abajo) con fecha y qué cambió.
>
> Fuente de verdad del diseño: `docs/CONTEXTO_PROYECTO.md` y `docs/PLAN_MAESTRO.pdf`.
> Reglas técnicas obligatorias: `CLAUDE.md` (raíz del repo).

---

## 🧭 Si acabas de abrir esto (para Claude)

1. Lee esta sección y las dos siguientes (conectar Studio, GitHub) antes de tocar nada.
2. Lee `CLAUDE.md` (reglas técnicas obligatorias) y, si hace falta contexto de diseño/negocio,
   `docs/CONTEXTO_PROYECTO.md`.
3. Si es la primera vez que hablas con esta persona en este proyecto (o simplemente parece que no
   ha visto esto todavía), dale un resumen corto **antes** de ponerte a trabajar: qué se hizo en la
   entrada más reciente de abajo, cuántos PR siguen abiertos y sin revisar, y cuál es el siguiente
   paso sugerido (sección "Qué sigue" más abajo). No hace falta leerle el archivo entero — con 4-6
   líneas alcanza.
4. No asumas que lo que dice una entrada vieja sigue siendo cierto si algo más nuevo lo contradice
   (por ejemplo: el estado de los PR cambia en cuanto alguien los revisa/mergea). Si tienes `gh`
   disponible, `gh pr list` y `gh pr view <n>` te dan el estado real en vez de lo que diga aquí.

---

## 🔌 Cómo conectar Claude Code a Roblox Studio

Esto hay que hacerlo **una vez por máquina** (cada cofundador, en su propia compu). Sin esto,
Claude solo puede editar archivos de texto — no puede ejecutar Luau de verdad, hacer playtest, ni
ver la consola de Studio.

1. **Instalar Rokit** (administra `rojo`/`selene`/`stylua` con la misma versión para los dos):
   `winget install Rojo.Rokit`. Después, dentro de la carpeta del repo: `rokit install`.
2. **Abrir Roblox Studio** con el place de este proyecto. Activar el MCP integrado de Studio:
   Assistant → ⋯ → **Manage MCP Servers** → activar **"Enable Studio as MCP server"**.
3. **Registrar el servidor MCP en Claude Code** (una terminal normal, parada **dentro de la
   carpeta del repo** — esto importa, ver el punto 4):
   ```
   claude mcp add Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat
   ```
   (Esto es para Windows. En Mac la ruta del bridge de Roblox es otra — si tu cofundador usa Mac,
   que revise la documentación de "Roblox Studio Assistant/MCP" en vez de copiar esto literal.)
4. **Importante — por qué a veces "no aparecen las herramientas":** este registro queda guardado
   para la ruta EXACTA de la carpeta donde corriste el comando. Si abres Claude Code (terminal o
   app de escritorio) parado en una carpeta distinta (p. ej. tu carpeta de usuario en vez de la del
   repo), las herramientas de Studio simplemente no van a estar ahí — no es que esté roto, es que
   esa sesión no está "parada" en el lugar correcto. Si usas la app de escritorio de Claude Code,
   puedes mover una sesión ya abierta a la carpeta correcta sin reiniciarla.
5. **Las versiones de Rojo tienen que coincidir.** El plugin de Rojo *dentro* de Studio se
   autoactualiza solo (viene de la Toolbox, no de Rokit); el `rojo` de línea de comandos que instala
   Rokit NO se actualiza solo. Si al hacer clic en "Connect" en el panel de Rojo (dentro de Studio)
   sale un error como `attempt to index number with 'protocolVersion'`, es exactamente esto: compara
   `rojo --version` (en una terminal) contra el número que muestra el panel de Rojo arriba del todo
   (p. ej. "Rojo 7.7.1"), edita la línea `rojo = "rojo-rbx/rojo@X.Y.Z"` en `rokit.toml` para que
   coincida, y corre `rokit install` de nuevo.
6. **Arrancar Rojo:** `rojo serve default.project.json` (puerto 34872 por defecto) desde la raíz
   del repo. Claude puede arrancarlo solo en segundo plano si se lo pides.
7. **En Studio:** panel de Rojo → **Connect**. La primera vez puede aparecer un panel "View
   changes" pidiendo que aceptes el sync a mano (un botón ✓ arriba a la derecha) — acéptalo, y de
   paso entra a **Settings** (al lado de "Disconnect") y pon la confirmación en **automática**, así
   no hay que repetir ese clic cada vez que Claude cambia de rama para probar algo.
8. **Detalle para Claude, no para el humano:** si acabas de pedirle a Rojo que sincronice un
   cambio y corres algo como `TestRunner.run()` en modo **Edit** justo después, puede devolver
   resultados viejos — Luau cachea `require()` por instancia de script y no se invalida solo porque
   el `Source` cambió. Para una lectura de verdad fresca, entra a modo **Play**
   (`start_stop_play`) y corre la prueba ahí.

9. **Si `claude mcp list` dice "Connected" pero "tools fetch failed — Request timed out"** (pasó el
   27 nov): el proxy `StudioMCP.exe` está vivo pero Studio NO se conectó a él (se ve porque en
   `netstat` el puerto 127.0.0.1:13469 solo tiene conexiones del propio `StudioMCP.exe`). Solución
   que funcionó: en Studio, **activar la integración MCP** (Assistant → ⋯ → Manage MCP Servers →
   "Enable Studio as MCP server", o la opción equivalente en Studio Settings) con el place abierto, y
   **reiniciar la sesión de Claude** para que cargue las herramientas (`list_roblox_studios` ya
   lista el place). No hace falta reiniciar Studio ni el proceso `StudioMCP.exe`.
10. **Control de pantalla (computer-use): no hace falta.** Con el MCP conectado todo se hace con
    `execute_luau`, `start_stop_play`, `get_console_output` y `screen_capture`.

Con esto conectado, las herramientas disponibles son (entre otras): `execute_luau`,
`start_stop_play`, `get_console_output`, `screen_capture`, `search_game_tree`, `inspect_instance`,
`script_grep`/`script_read`/`script_search`, `user_mouse_input`/`user_keyboard_input`, y las de
generación (`generate_mesh`, `generate_material`, `generate_texture`, etc.).

---

## 👥 GitHub: invitar a tu cofundador y poder clonar/editar el proyecto

El repo (`ChinoDFO/terraform-toss`) es **privado** — sin invitación, tu cofundador no puede verlo
ni clonarlo, aunque tenga el link.

### Invitarlo (lo hace quien tiene la cuenta `ChinoDFO`)
1. Conseguir su **usuario de GitHub** (sigue pendiente — nadie lo tiene anotado todavía).
2. Ir a <https://github.com/ChinoDFO/terraform-toss/settings/access> → **Add people** → escribir
   su usuario o correo → elegir el rol **Write** (puede clonar, hacer push a sus propias ramas y
   abrir PRs; no puede borrar el repo ni cambiar su configuración) → enviar la invitación.
3. Tu cofundador recibe un correo/notificación de GitHub y tiene que **aceptar la invitación**
   (desde el correo, o en <https://github.com/ChinoDFO/terraform-toss/invitations>).

### Cómo baja el proyecto (ya aceptada la invitación)
- **Más fácil, sin terminal:** [GitHub Desktop](https://desktop.github.com) → iniciar sesión con
  su cuenta de GitHub → "Clone a repository from the Internet" → buscar `ChinoDFO/terraform-toss`
  → elegir una carpeta → Clone. Después puede sincronizar cambios (subir/bajar) con un botón, sin
  usar la terminal para nada.
- **Con terminal:** `git clone https://github.com/ChinoDFO/terraform-toss.git`
- **Evitar** el botón "Code → Download ZIP" si va a editar algo: baja una copia suelta, sin
  historial de git, y no se puede subir de vuelta nada desde ahí. Sirve solo para mirar, no para
  trabajar.

### Después de clonar
1. Seguir la sección "Cómo conectar Claude Code a Roblox Studio" de arriba (Rokit, Studio, MCP).
2. Leer `CLAUDE.md` y `docs/CONTEXTO_PROYECTO.md` antes de tocar código.
3. Nunca hacer push directo a `master`/`main` con código de juego: una rama por tarea, PR revisado
   por el otro cofundador (ver "Cómo trabajar" en `CLAUDE.md`).

---

## 🗺️ Qué sigue (actualizado 2026-11-27)

**Estado de `master`: los 14 Pull Requests (#1–#14) están MERGEADOS.** No queda ningún PR de
funcionalidad abierto (solo el de esta documentación, si aún no se mergeó). Lo primero que hay que
atender ahora es la **revisión cruzada**: el cofundador que no estuvo en esta sesión debería leer lo
mergeado (ver la entrada 16 de abajo) y probarlo jugando, porque se mergeó con pruebas automáticas
y playtest de Claude pero sin revisión humana previa.

**Pendientes inmediatos (técnicos):**
- [ ] Probar con **2 o más jugadores** (Test > Start con varios clientes): combo, aviso de combo,
  jardines de varios jugadores en el círculo, escenografía compartida. No se probó.
- [ ] Probar la **celebración al 100 %** (fuegos artificiales del cliente, recompensa a todos,
  reinicio del planeta a los 8 s con limpieza de la escenografía). No se probó en vivo.
- [ ] Averiguar el aviso `ContentId: rbxassetid://203785492 failed due to: Asset type does not match
  requested type` (sale 3 veces al arrancar Play). No viene de `src/` (ese ID no existe en el
  código); origen desconocido (¿algo del place, de la plantilla o de un plugin?). Es inofensivo,
  pero conviene identificarlo.
- [ ] Ajustar a ojo los **valores visuales** que son primera propuesta: colores/niebla del
  ambiente (`Config/Ambience`), proporciones y colores de criaturas (`CreatureBuilder`), posición y
  tamaño de la plataforma (`LaunchPlatformService`), densidad de escenografía (`Config/Scenery`).
- [ ] Sustituir los **sonidos temporales** del motor por audio propio/licenciado antes de publicar.
- [ ] Arte/mapa real (Dev B): las criaturas, la plataforma y la escenografía son procedurales y
  simples; los letreros de zona siguen siendo placeholder.
- [ ] Guardar el place de Studio una vez (`File > Save to File` / `Save to Roblox`): sigue sin
  guardarse; el place de pruebas se llama `Place1` y usa datos en memoria.

**Roadmap** (`docs/CONTEXTO_PROYECTO.md` §6, fuente de verdad si esto queda desactualizado):
- **Semana 1** (30 nov – 6 dic): bucle central, HUD, efectos, sonidos ✓ (PR #1). Plataforma ✓
  procedural (PR #10/#14); el mapa "de verdad" sigue siendo de Dev B.
- **Semana 2** (7–13 dic): índice ✓ (#3), 30 criaturas ✓, zonas visibles ✓ placeholder (#5), jardín
  3D ✓ (#6/#8, ahora con criaturas procedurales #11), FTUE ✓ (#4 tienda + #12 tutorial/misiones).
  Adelantado además: ambiente (#9/#13), escenografía/partículas/celebración (#10), spawn (#14).
- **Semana 3** (14–20 dic): productos reales en Creator Hub, tienda ética (precios desde
  `GetProductInfoAsync`), invitaciones, Share Links, celebración al 100 % (código hecho, falta probar).
- **Semana 4** (21–25 dic): congelar, prueba cerrada (22 dic), miniaturas, publicar 16+ (jueves 24),
  tarifa Kids & Select. **Lanzamiento público sábado 26 dic** (plan B: sábado 9 ene 2027).
- Después: actualización cada 2 semanas (ver tabla de `docs/CONTEXTO_PROYECTO.md` §6).

**Pendientes de equipo (no técnicos, de siempre):**
- **Invitar al segundo cofundador a GitHub** (falta su usuario de GitHub; ver la sección de arriba)
  y que clone el repo.
- Nombre definitivo del juego/estudio y reparto de ingresos (acuerdo escrito entre cofundadores).
- Verificar en Creator Hub el precio de crear un grupo y los requisitos de Kids & Select vigentes.
- **Revisión cruzada** de lo mergeado el 27 nov (`CLAUDE.md` pide que cada PR lo revise el otro
  cofundador; los 14 se mergearon por decisión explícita del dueño del repo sin esa revisión).

---

## ✅ Pruebas humanas pendientes (lista histórica: los PR #1–#6 ya se mergearon; sigue valiendo como checklist de juego)

Todo lo de aquí necesita ojos/oídos de una persona — nada de esto se puede confirmar solo con
`TestRunner` ni con capturas de pantalla hechas por Claude (ya se probó todo lo automatizable;
esto es lo que falta). Hacerlo con Rojo conectado (sección de arriba) y Play en Studio, revisando
cada PR por separado o todos juntos después de mergear.

**PR #1 — Sonidos y HUD**
- [ ] Jugar varios lanzamientos y escuchar: sonido de carga (tono que sube), de soltar, de
  aterrizaje. ¿Se sienten bien? ¿Algún volumen muy alto o muy bajo?
- [ ] Sacar un Épico/Legendario y un Bloom o Planeta restaurado (o forzarlo) para oír esos sonidos
  especiales al menos una vez cada uno.
- [ ] Con 2+ jugadores lanzando a la vez: ¿los sonidos se pisan mal entre sí?
- [ ] Mirar el HUD con el porcentaje del planeta muy bajo (recién empezado): ¿se lee bien el
  "0.03 %" y se ve razonable la barra con ancho mínimo?

**PR #3 — Índice de criaturas**
- [ ] Abrir el botón "Índice": ¿se lee bien?, ¿el scroll funciona bien con las 30 criaturas?
- [ ] Confirmar que el botón "Índice" no se encima con otros botones del HUD (probar también en
  una ventana angosta, tipo celular, si se puede).

**PR #4 — Tienda oculta los primeros 3 minutos**
- [ ] Entrar y jugar normal durante 3 minutos reales: el botón "Tienda" no debe estar desde el
  inicio, y debe aparecer solo (sin recargar nada) cuando toca.
- [ ] Intentar comprar algo antes de esos 3 minutos si encuentran la forma: debe salir el aviso
  amable, nunca procesar nada.
- [ ] Pendiente para más adelante (no se pudo probar en Studio: los datos de prueba viven en
  memoria y se borran al salir de Play): con una build publicada o datos reales, un jugador que
  YA jugó antes debería ver la tienda de inmediato al volver a entrar, no esperar otros 3 minutos.

**PR #5 — Letreros de zona (placeholder)**
- [ ] Caminar por el planeta: ¿los 6 letreros se leen a buena distancia?, ¿se encimen entre sí o
  con el HUD?

**PR #6 — Jardín 3D (placeholder)**
- [ ] Buscar el jardín propio (lejos del planeta, alrededor en círculo) y confirmar que los cubos
  se ven razonables, no quedan enterrados ni flotando raro.
- [ ] Con 2+ jugadores a la vez: confirmar que los jardines de cada uno no se superponen.

**General (nada de esto se probó con más de 1 jugador real — Claude solo puede controlar uno)**
- [ ] Combo: 2 jugadores lanzando a menos de 30 studs de distancia y con menos de 1 s de
  diferencia — ¿se siente el bonus de distancia/suerte?
- [ ] Sensación general de ritmo jugando varios minutos seguidos (la entrada (8) de la bitácora ya
  pedía esto para el balance del planeta; sigue pendiente).
- [ ] Consola de Studio sin errores nuevos durante una sesión larga con 2+ jugadores reales.

---

## 2026-11-27 (16) — Subida de nivel del juego: x3 celdas, ambiente, mundo y criaturas procedurales, FTUE, spawn; los 14 PR mergeados

**En una frase:** se aceleró el planeta (x3 celdas), se añadieron ambiente, plataforma, escenografía,
partículas, criaturas procedurales, tutorial/misiones/meta y un spawn sobre la plataforma
(PR #7–#14); se verificó TODO junto en Studio (25/25 pruebas + playtest) y Anton pidió mergear los
14 PR a `master`.

**Cómo se trabajó (importante para el siguiente Claude):**
- La sesión de nube NO puede empujar a GitHub; el trabajo se hizo en el PC de Anton con Remote
  Control y las credenciales de `gh` de ese PC. Cada tarea = una rama + un PR en español, con
  commits `feat:`/`fix:`/`docs:` y pie `Co-Authored-By`. Los PR se apilaron cuando dependían de otro.
- Studio + Rojo 7.7.1 (plugin y `rokit.toml` ya coinciden) + MCP integrado de Studio. El MCP estuvo
  caído un rato por "tools fetch failed" (ver el punto 9 de "Cómo conectar"): la solución fue activar
  la integración MCP en Studio y reiniciar la sesión.
- En Windows, `git` sin `.gitattributes` hace ruido de CRLF/LF en `git status` (muchos archivos salen
  " M" aunque no cambien). `.gitattributes` (`* text=auto eol=lf`) llegó con el PR #3 y el índice es
  LF; `stylua` normaliza a LF. No hagas `git add -A` sin mirar `git diff --stat`.

**Orden en que quedó `master` (merge normal, sin squash, sin reescribir historia):**
`#2` (pruebas) → `#3` (índice + `.gitattributes`) → `#6` (jardín 3D, entró vía `#8`) → `#8` (jardín
usa `PlanetOrigin` + resolución del conflicto #3/#6 en `EconomyService`) → `#10` (mundo) → `#11`
(criaturas) → `#14` (spawn) → `#1` (sonidos/HUD) → `#4` (tienda tras 3 min) → `#5` (letreros de
zona) → `#7` (x3 celdas) → `#9` (ambiente) → `#12` (FTUE/misiones) → `#13` (cablear ambiente).
Conflictos: el único real fue `EconomyService` (#3 vs #6: se conservan `CreatureService.syncDiscovered`
Y `GardenVisualService.sync`); el resto fueron triviales en `tests/TestRunner.luau` y los `Main`
(quedarse con ambos lados). Una resolución automática dejó una prueba sin `end)` en #14; lo detectó
`stylua --check` y se corrigió antes de mergear. **Siempre corre `stylua --check src tests` y
`selene src` tras resolver conflictos.**

**Qué hay en cada módulo nuevo (todo en `src/`, `--!strict`, comentarios en español):**
- **x3 celdas (PR #7)** — `Config/Rarities.cellsPerThrow` pasó de 1/2/4/8/20 a **3/6/12/24/60**.
  Por qué: con 1/2/4/8/20 el planeta tardaba ~66 min con 6 jugadores; ahora ~22 min (25 % en ~5,5
  min). Decisión de Anton del 27 nov. Un lanzamiento medio da ≈5,39 celdas ≈ 0,06 % del planeta
  (una prueba exige que esté entre 5 y 6).
- **Ambiente (PR #9 + #13)** — `shared/Config/Ambience` (look "muerto" gris/neblinoso ↔ "vivo"
  cálido/verde; `Ambience.at(percent)` interpola con curva suave y acota fuera de rango / NaN→0) y
  `client/Controllers/AmbienceController` (crea o reutiliza Atmosphere, Bloom, ColorCorrection y Sky
  en `Lighting`; tween de 4 s cuando cambia `ServerState.PlanetPercent`). Solo cosmético y solo
  cliente. OJO: #9 salió sin el `require`/`init()` en `Main.client`; lo arregló #13.
- **Mundo procedural (PR #10)** — `LaunchPlatformService` (base 48×1×24, barandas en 3 lados, 4
  farolas con PointLight, 12 partes, delante del planeta usando `TerraformService.getOrigin()`);
  `SceneryService` + `Config/Scenery` (helecho/duna/cristal/hielo/árbol/lava por zona; aparecen al
  restaurar celdas de su franja, prob. 4 % por celda, **tope de 24 por franja**, ancladas, sin
  colisión, se limpian al reiniciar el planeta); `TerraformService` ganó los hooks
  `onCellRestored(band, pos)` y `onGridReset()`; `client/Controllers/EffectsController` (ráfaga de
  partículas del color de la rareza al aterrizar, con pool y tope de 12 emisores; fuegos artificiales
  al recibir `Notify "PlanetRestored"`).
- **Jardín (PR #6/#8)** — `GardenVisualService` coloca los jardines de los jugadores en círculo
  (radio 220) alrededor de `TerraformService.getOrigin()` (que lee `Workspace.PlanetOrigin` si
  existe; si no, (0,0,120)). Reconstruye el jardín del jugador completo en cada cambio.
- **Criaturas procedurales (PR #11)** — `shared/Util/CreatureBuilder`: `describe(id, mutación)`
  (puro, probado) y `build(...)` (cuerpo esférico + ojos; rasgos acumulativos por rareza: orejas →
  cuernos → alas → aureola; color = mezcla zona+rareza; Épico/Legendario con luz y partículas;
  mutaciones: Neón / Dorado / Gigante ×1,35 / Cristal / Bioluminiscente / Arcoíris). Los modelos
  llevan el tag `Creature`; `client/Controllers/CreatureAnimator` los balancea con `PivotTo` (solo a
  <160 studs de la cámara y a ~30 Hz) y rota el tono del Arcoíris.
- **FTUE / misiones / meta / combo (PR #12)** — `shared/Config/Quests` (3 misiones diarias: lanzar 10,
  comprar 2 mejoras, restaurar 40 celdas; recompensa = 120 s de ingreso, mín. 100, solo dinero
  personal; ventana de combo 1 s / radio 30, que ahora lee también `ThrowService`),
  `server/Util/Progression` (lógica pura y probada: `rollQuests`, `questProgress`,
  `advanceTutorial`, `nextGoal`), `server/Services/ProgressionService` (lo aplica; bucle de 1 s) y
  `client/Controllers/ProgressController` (banner + flecha que rebota, panel "Misiones", etiqueta
  "Próxima criatura/zona", aviso "¡Combo cerca! Lanza YA" con barra real de 1 s). Las misiones miden
  la **diferencia de contadores** que el servidor ya lleva (sin hooks ni confianza en el cliente) y
  se reinician cada día UTC, sin castigo por perder un día. Tutorial: 1 lanza → 2 mejora (se
  garantiza el dinero de la primera mejora, una vez) → 3 mira tu jardín (solo avanza con el botón
  "¡Entendido!") → 4 hecho; jugadores con ≥5 lanzamientos lo saltan. `PlayerData` ganó
  `tutorialStep`, `questDay`, `questBase`, `questClaimed` (con valores por defecto; `reconcile` los
  rellena en cuentas antiguas).
- **Spawn (PR #14)** — `LaunchPlatformService.spawnCFrame(origin)` (puro, probado) y un
  `SpawnLocation` invisible "SpawnPlataforma" (Neutral, `Duration = 0` = sin ForceField) sobre la
  plataforma, mirando al planeta (+Z). Los demás `SpawnLocation` del place (el de la plantilla en
  0,0,0) se desactivan en runtime. Antes el jugador aparecía a ~84 studs de la plataforma.

**RemoteEvents nuevos** (declarados en `default.project.json`, ambos C→S con `RateLimiter` y
`Validate`): `ClaimQuest` (índice entero 1..3; progreso completo y no reclamada; 3/s) y
`TutorialAck` (sin args; solo vale en el paso 3; 2/s). Atributos nuevos del Player (los escribe solo
el servidor): `TutorialStep`, `QuestProgress1..3`, `QuestClaimed1..3`, `GoalText`. El cliente de
ambiente lee el atributo ya existente `ServerState.PlanetPercent` (0–100).

**Pruebas — cómo correrlas y estado:** `TestRunner.run()` = **25 OK, 0 fallos** sobre `master`
(las 10 originales + índice/máscara + getOrigin + escenografía + CreatureBuilder + x3 celdas +
ambiente + misiones + tutorial + meta + plataforma/spawn). Con el MCP: `execute_luau` →
`return require(game:GetService("ServerStorage").Tests.TestRunner).run()`. Trampa: en modo **Edit**,
`require` cachea por instancia y puede devolver resultados viejos tras un cambio de rama; entra a
**Play** (`start_stop_play`) y corre la prueba con `datamodel_type: Server`.

**Cómo se verificó en Studio (real, no solo leído):** rama local de integración con todos los PR →
25/25; playtest con 1 jugador: 47 lanzamientos por los remotes (planeta 0 → 2,44 %, 8 criaturas /
65 partes en el jardín, 8 modelos de escenografía), tutorial 1→2→3→4, misiones reclamadas (+$3.374),
entradas basura (1.5, "x", NaN, 0) ignoradas sin error, ambiente y `ProgressUi` activos, spawn en
(0, 4.9, 84) mirando +Z, consola sin errores nuevos. Tras el merge: `master` 25/25 + playtest corto OK.

**Métricas (Studio, 1 jugador):** Workspace 1.493 instancias / 1.119 partes (1.024 son del planeta);
GUI 408 instancias; Heartbeat 0,39 ms. **FPS ≈15 constantes** en Studio, idénticos con Bloom /
ColorCorrection / Atmosphere apagados y con `PlanetCells` quitado → es un tope de Studio/ventana, NO
del contenido, así que no sirve como métrica.

**Decisiones tomadas:**
1. **Balance x3 celdas** (planeta ~22 min con 6 jugadores) — pedido de Anton.
2. **No se optimizó** nada: no hay cuello de botella medido (FPS 15 = tope de Studio) y tocar sin
   datos arriesga crashes. Los presupuestos ya van en el diseño (partes ancladas y sin colisión,
   tope de escenografía por franja, pools, animación de criaturas limitada por distancia y frecuencia).
3. Misiones y tutorial: todo lo decide el servidor; recompensas solo personales y sin dark patterns.
4. Los PR apilados se mergearon en orden con las bases retargeteadas a `master`.

**Qué NO se probó:** 2+ jugadores; la celebración al 100 % (un intento de forzarla desde
`execute_luau` falló porque `require` creó otra copia del módulo — fue un artefacto de la prueba,
no del juego); el camino "jugador que vuelve" del retraso de la tienda (datos en memoria);
dispositivos móviles; rendimiento fuera de Studio.

**Hallazgos pendientes:** ver "Pendientes inmediatos" en "Qué sigue" (aviso `ContentId
rbxassetid://203785492` de origen desconocido, valores visuales a ajustar, sonidos temporales, arte
real, place sin guardar).

---

## 2026-11-26 (15) — Cierre del día: resumen de toda la sesión

**En una frase:** se diagnosticó y arregló por qué Claude no podía conectarse de verdad a Studio
(tres problemas distintos, uno detrás de otro), y con eso ya funcionando se probaron y ampliaron 6
áreas del juego — todo quedó en 6 Pull Requests, ninguno mergeado, listos para revisión humana.

**El hilo completo de la sesión, en orden:**
1. **Diagnóstico #1:** esta sesión (app de escritorio) no tenía las herramientas de Studio porque
   había arrancado parada en la carpeta de usuario en vez de en la del repo (ver entradas 9-10).
   Solucionado moviendo el directorio de la sesión.
2. **Diagnóstico #2:** una vez movida, el clic en "Connect" del plugin de Rojo fallaba con un error
   de protocolo — versión del plugin de Studio (7.7.1, autoactualizado solo) desincronizada de la
   versión del CLI fijada en `rokit.toml` (7.6.1). Arreglado actualizando `rokit.toml` a 7.7.1.
3. **Diagnóstico #3:** con las versiones iguales, "Connect" funcionaba pero los cambios de rama no
   se reflejaban solos en Studio — Rojo tenía la confirmación manual de cada sync activada. El
   usuario la puso en automática. (Los tres diagnósticos quedaron resumidos arriba en "Cómo
   conectar Claude Code a Roblox Studio" para que no haya que repetir la investigación.)
4. Con todo eso resuelto, se hizo una partida real en Studio (Play) para probar en vivo lo que la
   auditoría estática de sesiones anteriores no cubría: límites de velocidad, validación de
   entradas, política de contenido aleatorio pagado, los 10 RemoteEvents del juego con entradas
   inválidas/de ráfaga. Nada falló. Se encontró y arregló un bug menor (el tope de suerte de
   diseño no se aplicaba al número que ve el jugador) y se agregaron 5 pruebas permanentes nuevas
   → **PR #2**.
5. Se construyó el **Índice de criaturas** (Semana 2) → **PR #3**, probado jugando: se actualiza
   solo al descubrir una criatura.
6. Revisando el código a fondo se encontró que la regla de diseño "sin tienda los primeros 3
   minutos" nunca se había programado → **PR #4**. En una revisión de cumplimiento posterior se
   encontró y corrigió que ese retraso debía ser solo de la primera sesión de cada cuenta, no de
   todas (igual que la regla del primer lanzamiento garantizado).
7. El usuario preguntó por qué ya no sonaba al lanzar: no era un bug, el PR #1 (sonidos) nunca se
   había mergeado y Studio estaba sincronizado con una rama sin él. Se confirmó en vivo, por
   primera vez, que el PR #1 sí funciona.
8. A pedido del usuario, se construyeron dos **placeholders** explícitamente temporales de
   Semana 2 (zonas visibles con letreros flotantes, jardín 3D con cubos de color por criatura) →
   **PR #5 y #6**. Se encontró y arregló un bug real en el camino (`ClearChildren` no existe en
   Roblox; es `ClearAllChildren`) gracias a probarlo en Play real — ni `selene` ni `stylua` lo
   detectan.

**Dónde quedó todo:** 6 PR abiertos (`#1` al `#6`), ninguno mergeado — ver la tabla en "Qué sigue"
más arriba para el detalle y el orden sugerido. Todo lo nuevo de hoy (`#2`–`#6`) quedó probado de
verdad dentro de Studio, no solo leído. Nada de lo que se hizo rompe ninguna regla de
`CLAUDE.md` ni reabre ninguna decisión congelada de `docs/CONTEXTO_PROYECTO.md` §9 (se revisó
explícitamente, ver entrada 13).

---

## 2026-11-26 (14) — Sonido del PR #1 confirmado + 2 placeholders de Semana 2 (PR #5, #6)

**Pregunta del usuario: "¿por qué ya no suena al lanzar?"** No era un bug — Studio estaba
sincronizado con `master`, que nunca tuvo los sonidos (viven solo en el PR #1, sin mergear).
Cambié a esa rama y confirmé en vivo (capturé el `Sound` de "Release" con `IsPlaying = true`
justo al soltar, sin errores en consola): el PR #1 funciona bien, de verdad, por primera vez.
También probé `ClaimDaily` ahí: racha 0→1, $50, notificación correcta, segundo intento el mismo
día correctamente ignorado.

**Evaluación de lo que falta de Semana 1/2:** "bucle central sólido" y "sonidos/efectos" ya están
(este último esperando revisión en el PR #1); "plataforma" es de Dev B (mapa/arte, no código).
De Semana 2 faltaban "jardín 3D" y "zonas visibles" — ambos dependen del mapa/arte real. Le
pregunté al usuario cómo seguir; eligió: **placeholders simples y claramente temporales**, para
que Dev B tenga algo sobre qué iterar.

**2 PR nuevos, ambos placeholders explícitos (sin arte final, solo formas simples):**
- [`#5`](https://github.com/ChinoDFO/terraform-toss/pull/5) `feat/zonas-visibles-placeholder`:
  un letrero flotante (`BillboardGui`) con el nombre de cada zona, coloreado igual que sus
  celdas. Verificado en vivo (texto y color exactos vía `inspect_instance`).
- [`#6`](https://github.com/ChinoDFO/terraform-toss/pull/6) `feat/jardin-3d-placeholder`: un
  `GardenVisualService` nuevo que dibuja un cubo de color por criatura del jardín de cada
  jugador (coloreado por rareza, igual que el HUD/Índice), en un punto fijo alrededor del
  planeta. Se sincroniza desde `CreatureService.grant` y desde la carga inicial.

**Bug real encontrado y arreglado en vivo (PR #6):** usé `folder:ClearChildren()`, que no existe
en Roblox (el método real es `ClearAllChildren`) — crasheaba la sincronización del jardín cada
vez que se llamaba. `selene`/`stylua` no lo detectan (ninguno valida nombres de métodos de la
API de Roblox); solo lo agarré porque lo probé en Play real. **Esto confirma, otra vez, que
probar en vivo dentro de Studio encuentra cosas que el lint no puede.**

**Estado de los PR (6 abiertos, ninguno mergeado todavía):**
`#1` HUD/sonidos · `#2` pruebas+suerte · `#3` índice (depende del #2) · `#4` tienda FTUE ·
`#5` zonas visibles (placeholder) · `#6` jardín 3D (placeholder). Los últimos 4 ya están
verificados en vivo dentro de Studio con Rojo conectado.

**Siguiente paso sugerido:** con 6 PR abiertos, probablemente conviene que el equipo se ponga a
revisar/mergear antes de seguir acumulando más — no hay nada técnico bloqueando, es cuestión de
revisión humana.

---

## 2026-11-26 (13) — Revisión de cumplimiento contra el plan (CLAUDE.md + docs) — 1 corrección real

A pedido del usuario, releí los 3 PR nuevos (#2, #3, #4) línea por línea contra las reglas no
negociables de `CLAUDE.md` y las decisiones congeladas de `docs/CONTEXTO_PROYECTO.md` §9.

**Resultado: todo en orden, con UNA corrección real** (PR #4, ya corregida y pusheada): el retraso
de "sin tienda los primeros 3 minutos" se estaba aplicando en CADA sesión, pero "FTUE" (primera
experiencia) es, igual que la regla hermana ya existente (el primer lanzamiento siempre es Poco
común, con `data.totalThrows == 0`), algo de la PRIMERA vez que juega esa cuenta — no algo que se
repite cada vez que alguien que ya jugó antes vuelve a entrar. Corregido: ahora solo se retrasa si
`data.totalThrows == 0` al cargar; quien ya jugó antes ve la tienda de inmediato
(`ShopAvailableAt = 0`). Reconfirmado en vivo que el caso de jugador nuevo sigue funcionando.

**Checklist repasado (todo en verde salvo lo de arriba):**
- Servidor autoritativo / cliente nunca confiable: `IndexController` es 100 % lectura, no decide
  nada.
- RemoteEvents y patrones prohibidos: sin `RemoteFunction`, sin `wait()`/`spawn()`/`delay()`
  crudos, sin `loadstring`/`getfenv`/`setfenv`/`_G` (grep sobre los 3 diffs completos: cero
  coincidencias).
- Monetización: sin precios escritos a mano, `PolicyService` intacto, el retraso de tienda
  **refuerza** "sin dark patterns" en vez de romperlo.
- Fórmulas de balance solo en `Formulas.luau`/`Config`: el tope de suerte está ahí (reusando
  `Rarities.MAX_LUCK`, no una constante duplicada). `FTUE_SHOP_DELAY` es una constante de
  comportamiento local de `PurchaseService`, igual que `COOLDOWN` en `ThrowService` o
  `TURBO_STREAK` en `DailyService` — mismo patrón que ya usaba el proyecto, no una fórmula de
  balance que debiera centralizarse.
- Comentarios y textos de UI en español, nombres de código en inglés: confirmado en
  `IndexController`.
- Ninguna decisión congelada de §9 (concepto, suerte no se vende, sin comercio, etc.) se reabrió.
- Las 5 ramas/PR siguen intactas, nada se perdió; el PR #1 (HUD/sonidos) sigue exactamente igual
  a como lo dejó la entrada (8), sin tocar.

**Pendiente de la corrección de hoy:** no se pudo probar en vivo la rama de "jugador que regresa"
del PR #4 (`data.totalThrows > 0` → tienda inmediata) porque el place de prueba usa datos en
memoria que se borran al salir de Play — queda para cuando alguien lo pruebe con datos que
persistan de verdad (lugar publicado, o DataStore real).

---

## 2026-11-26 (12) — Rojo reconectado de verdad + los 3 PR (#2, #3, #4) verificados dentro de Studio

**Lo que pasó, en orden (para la próxima vez que esto se rompa):**
1. El clic en "Connect" del plugin de Rojo daba un error de protocolo
   (`ApiContext:28: attempt to index number with 'protocolVersion'`). Causa real: el plugin de
   Rojo en Studio se había auto-actualizado solo a **7.7.1** (los plugins de la Toolbox se
   actualizan aparte del CLI), mientras `rokit.toml` seguía fijando el CLI en 7.6.1. Arreglado:
   `rokit.toml` → `7.7.1` + `rokit install` + reiniciar `rojo serve` (commit en `master`). **Si
   esto vuelve a pasar:** comparar la versión del CLI (`rojo --version`) contra la del panel de
   Rojo en Studio (dice "Rojo X.Y.Z" arriba del todo) y fijar la misma en `rokit.toml`.
2. Con las versiones ya iguales, "Connect" funcionó, pero el contenido no se actualizaba al
   cambiar de rama: Rojo tenía la confirmación manual de cada sync activada (un panel "View
   changes" con un botón ✓ que hay que apretar a mano). El usuario lo aceptó una vez y después puso
   la confirmación en **automática** desde el panel de Rojo → "Settings", así no hace falta
   repetir el clic cada vez que se cambia de rama.
3. **Para la próxima sesión que use el MCP de Studio:** correr `TestRunner.run()` en modo **Edit**
   justo después de que Rojo sincronice un cambio NO sirve para confirmar nada — Luau cachea el
   resultado de `require()` por instancia de script y no se invalida solo cuando Rojo actualiza el
   `Source`. Hay que entrar a modo **Play** (`start_stop_play`) para una lectura de verdad fresca.

**Con eso resuelto, verifiqué los 3 PR de la entrada (11) de punta a punta dentro de Studio (modo
Play real, no solo `execute_luau` por fuera como hasta ahora):**
- PR #2: `TestRunner.run()` → **15/15**.
- PR #3 (Índice): `TestRunner.run()` → **16/16**. Playtest real: abrí el índice (0/30), lancé una
  cápsula, y el panel se actualizó SOLO (sin recargar nada) mostrando "Musgolín (Poco común)" en
  verde y el contador en 1/30.
- PR #4 (tienda a los 3 min): playtest real confirmando que el botón "Tienda" NO aparece al entrar
  (solo "Diario") y que un intento de compra inmediato da el aviso correcto
  ("La tienda se desbloquea a los pocos minutos...") en vez de procesar nada —
  `ShopAvailableAt` quedó ~180 s en el futuro, confirmado con el reloj real del servidor.

Actualicé la descripción de los 3 PR en GitHub con esta confirmación (ya no dicen "pendiente de
probar en Studio").

**Siguiente paso sugerido (en orden):**
1. Revisar y mergear en el orden que tiene sentido por las dependencias: `#2` → `#3` (depende del
   #2) → `#4` (independiente) → `#1` (el más viejo, HUD/sonidos — sigue abierto, sin tocar, sigue
   pendiente de revisión).
2. Seguir con el resto de la Semana 1/2 (`docs/CONTEXTO_PROYECTO.md` §6).
3. Los de siempre: invitar al segundo cofundador (falta su usuario de GitHub), nombre/reparto del
   equipo.

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
