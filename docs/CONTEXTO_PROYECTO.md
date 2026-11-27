# CONTEXTO DEL PROYECTO — Terraform Toss (Roblox)

> **Para el cofundador:** sube este archivo como *conocimiento del proyecto* en un Proyecto de Claude llamado "Terraform Toss" (claude.ai → Proyectos → Nuevo proyecto → añadir archivo). Sube también `PLAN_MAESTRO.pdf`. Copia el bloque de la sección 0 en las **instrucciones del proyecto**. Así cualquier conversación que abras ahí sabrá de qué va todo.
>
> **Para Claude:** este documento es la fuente de verdad del proyecto. Si algo de aquí contradice una idea genérica sobre Roblox, manda este documento. Si algo parece desactualizado (reglas de Roblox, precios, APIs), dilo y propón verificarlo en create.roblox.com antes de actuar. Versión 1.1 — 27 nov 2026 (actualizado tras mergear los PR #1–#14; el historial detallado está en `ESTADO_DEL_PROYECTO.md`).

---

## 0. Instrucciones para Claude (copiar en "Instrucciones del proyecto")

Eres el asistente técnico y de producto de un estudio indie de 2 cofundadores que construye **Terraform Toss**, un juego de Roblox. Respondes en español. Actúas como Arquitecto de Sistemas en Roblox (Luau estricto), productor de LiveOps y estratega de monetización ética.

Reglas que siempre aplicas:
1. Todo código Luau lleva `--!strict` y es **autoritativo en el servidor**: el cliente pide, el servidor valida y decide. Nunca confías en valores del cliente.
2. Prohibido proponer: `RemoteFunction:InvokeClient`, `wait()`, `spawn()`, `delay()`, `Model:SetPrimaryPart`, `loadstring`, `getfenv/setfenv`, `require(<número>)`, `SetAsync` para datos de jugador. Usa `task.*`, `PivotTo`, `UpdateAsync` vía DataService.
3. Ningún precio escrito a mano: siempre `MarketplaceService:GetProductInfoAsync` (precios regionales + descuento de Roblox Plus).
4. Cualquier artículo aleatorio pagado: `PolicyService:GetPolicyInfoForPlayerAsync` en el servidor (`ArePaidRandomItemsRestricted`), probabilidades numéricas visibles antes de comprar que sumen 100 %, mínimo garantizado, alternativa gratuita. **La suerte no se vende.**
5. Sin dark patterns: sin temporizadores falsos, sin botones engañosos, sin avisos de compra que se abren solos, confirmación propia para compras ≥ 400 R$, lo pagado nunca bloquea el progreso compartido.
6. Avatares solo R15.
7. Cambios mínimos y puntuales; nunca reescribas archivos completos si basta un cambio. Antes de un cambio grande, propone un plan corto y espera aprobación.
8. Una tarea por conversación. Al final de cada respuesta técnica: cómo probarlo (pruebas automáticas y/o prueba de juego con el MCP de Studio).
9. Sé honesto: si una idea del equipo es arriesgada (legal, ética o para la retención), dilo con argumentos y propone una alternativa que conserve lo bueno de la idea.

---

## 1. El equipo y las restricciones

- **2 cofundadores**, estudiantes. Roles: **Dev A = Sistemas** (servidor, datos, compras, seguridad) y **Dev B = Experiencia** (mapa, interfaz, arte, sonido, primeros minutos, marketing). Ambos usan Claude.
- **Presupuesto:** $0 en API. Cada uno tiene Claude Pro (incluye Claude Code). Costes de plataforma: grupo de Roblox (~100 R$) y tarifa reembolsable de publicación para todas las edades (1.000 R$).
- **Herramientas:** Roblox Studio con el **servidor MCP integrado** (Assistant → … → Manage MCP Servers → Enable Studio as MCP server), Claude Code y Claude Desktop conectados por MCP, **Rojo 7** (con Rokit), Git + GitHub (repo privado, `main` protegido con PR + 1 aprobación), VS Code con Luau Language Server, StyLua y Selene.
- **Ritmo:** MVP en 4 semanas + 1 de pruebas; después, actualización cada 2 semanas.

## 2. El juego en una página

**Terraform Toss** (nombre provisional): juego **cooperativo** de lanzar cápsulas de semillas a un planeta gris. Cada lanzamiento revive casillas del planeta. El **% de planeta restaurado es compartido por todo el servidor** (0 % → 100 %). Cada lanzamiento da una criatura (según zona y rareza) que vive en tu jardín y genera dinero por segundo. Con el dinero mejoras entrenamiento y cápsula para lanzar más lejos.

- **Gancho:** "Lanza semillas. Salva el planeta. Día 1 → Día 100."
- **Por qué no es un clon:** mezcla la ola "Throw X" (*Throw Food For Animals*, ~236 K jugadores simultáneos, sesión ~16 min) con la restauración cooperativa de *Sweep The Moon* (29,7 min de sesión, 97,8 % de aprobación). Roblox resta visibilidad a juegos "no únicos".
- **Servidor:** 10 jugadores. **Sesión objetivo:** 19+ min.
- **Público:** global. El primer mes, solo mayores de 16 (regla de publicación de Roblox); luego todas las edades tras la evaluación Kids & Select.

### Bucle central
1. **Entrenar:** el Poder sube (1 + nivel) por segundo, siempre; tocar ENTRENAR suma medio segundo por toque (máx. 8/s).
2. **Cargar y soltar:** medidor 0→1→0 cada 1,6 s; ≥ 0,9 = ×2, ≥ 0,7 = ×1,5, resto ×1; más de 8 s = ×1. **El servidor calcula el medidor con su reloj** (el cliente solo envía "empecé" y "solté").
3. **Distancia** = Poder × medidor × 1,2^nivelCápsula × 1,25 si hay combo.
4. **Zona** por distancia; **rareza** con suerte; **mutación** aparte.
5. **Celdas:** se reviven en la franja de esa zona (o la libre más cercana).
6. **Jardín:** la criatura genera $/s; mejoras con dinero.

### Números clave (balance inicial, ajustable en `Config/` y `Util/Formulas.luau`)

| Zona | Nombre | Distancia mínima | Ingreso base/s |
|---|---|---|---|
| 1 | Páramo Gris | 0 | 1 |
| 2 | Dunas de Óxido | 200 | 6 |
| 3 | Cráter Salino | 3.000 | 36 |
| 4 | Glaciar Dormido | 50.000 | 220 |
| 5 | Bosque Fósil | 900.000 | 1.300 |
| 6 | Núcleo Volcánico | 20.000.000 | 8.000 |

Ritmo simulado (activo, sin pases): zona 2 ~1 min, 3 ~3 min, 4 ~15 min, 5 ~1,5 h, 6 ~12 h.

| Rareza | Prob. base | Ingreso | Celdas por lanzamiento (x3 desde el 27 nov) | Exponente de suerte |
|---|---|---|---|---|
| Común | 62 % | ×1 | 3 | 0 |
| Poco común | 25 % | ×2 | 6 | 0,35 |
| Raro | 10 % | ×5 | 12 | 0,6 |
| Épico | 2,7 % | ×15 | 24 | 0,85 |
| Legendario | 0,3 % | ×60 | 60 | 1 |

- **Suerte** = 1 + 0,02 × criaturas distintas descubiertas + 0,5 (Bloom) + 0,25 (vídeo con recompensa, 10 min). Máx. 5. Peso de cada rareza × suerte^exponente; Común absorbe el resto → siempre suma 100 %.
- **Mutaciones:** Ninguna 90 % · Neón 4 % (×1,5) · Dorado 3 % (×2) · Gigante 1,5 % (×2,5) · Cristal 1 % (×3) · Bioluminiscente 0,4 % (×4) · Arcoíris 0,1 % (×5).
- **30 criaturas** = 6 zonas × 5 rarezas (nombres en `Config/Creatures.luau`: Brotín, Musgolín, Cactopo, Liquenzorro, Rocalirio; Arenuga… Corazón de Gaia).
- **Costes:** entreno `30 × 1,85^nivel`; cápsula `300 × 4^nivel`.
- **Jardín:** 8 huecos (+4 pase, +1 Roblox Plus). Lleno → reemplaza a la peor si la nueva vale más; la vendida da 30 s de su ingreso. Ingresos offline: 50 %, máx. 8 h.
- **Planeta:** 96×96 = 9.216 celdas lógicas en 6 franjas; se dibuja con 32×32 = 1.024 partes. Con 6 jugadores: 25 % en ~5,5 min, 100 % en ~22 min (celdas por lanzamiento x3, decisión del 27 nov; un lanzamiento medio da ≈5,39 celdas ≈ 0,06 % del planeta).
- **Bloom Event** al 25/50/75 %: 10 min de ×2 dinero y +0,5 suerte para todos. **100 %:** 5 min de ingresos + 1 Huevo Estelar gratis para todos; siguiente planeta (+10 % de dinero en ese servidor).
- **Combo:** otro jugador a ≤ 30 studs soltó hace ≤ 1 s → +25 % distancia y +0,1 suerte.
- **Diario:** ciclo de 7 días. Día 3 de racha → Turbo ×2 de entrenamiento gratis para siempre. Día 7 → 1 Huevo Estelar gratis.
- **FTUE:** primer lanzamiento siempre Poco común; primera mejora (30 $) a los ~20–30 s; sin ventanas de compra los primeros 3 minutos (solo la primera sesión de cada cuenta). **Tutorial guiado de 3 pasos** (lanza → mejora → mira tu jardín) con banner y flecha; el servidor avanza los pasos por hechos y el último solo con el botón "¡Entendido!"; quien ya tiene ≥5 lanzamientos lo salta.
- **Misiones diarias** (se reinician cada día UTC, sin castigo por perder un día): lanzar 10 cápsulas, comprar 2 mejoras, restaurar 40 celdas. Recompensa: dinero personal (120 s de ingreso, mínimo 100). El progreso es la diferencia de contadores que el servidor ya lleva.
- **Meta visible:** etiqueta bajo la barra del planeta con la "Próxima criatura" sin descubrir y la "Próxima zona". **Aviso de combo:** barra de 1 s cuando un compañero cercano acaba de lanzar (la ventana real del combo).
- **Mundo:** plataforma de lanzamiento procedural (con el spawn de los jugadores), escenografía por zona que aparece al restaurar celdas (helechos, dunas, cristales, hielo, árboles, lava; tope 24 por franja), ambiente que pasa de gris/apagado a cálido/verde con el % del planeta, partículas al aterrizar y fuegos artificiales al 100 %, y criaturas procedurales (cuerpo + ojos + rasgos por rareza; brillo en Épico/Legendario y mutaciones) con balanceo suave en el cliente.

## 3. Monetización (precios BASE; el juego los lee en vivo)

| Producto | Tipo | Base | Qué da | Gratis vía |
|---|---|---|---|---|
| Turbo de Arranque | Pase | 5 R$ | ×2 entrenamiento | Racha de 3 días |
| Doble Dinero | Pase | 149 R$ | ×2 dinero del jardín | Bloom (temporal) |
| Auto-Lanzamiento | Pase | 199 R$ | Lanza solo cada 4 s (medidor ×1,5) | — |
| +4 Huecos | Pase | 99 R$ | Jardín 8 → 12 | +1 con Plus |
| Catapulta Dorada | Pase | 79 R$ | Cosmético | — |
| Pack de Arranque | Producto, una vez | 49 R$ | Contenido fijo: +3 niveles de entreno, 1 Huevo Estelar, skin | — |
| Huevo Estelar | Producto | 25 R$ | Rara o mejor de tu mejor zona (aleatorio) | Día 7, planeta 100 %, Pack |
| ×2 Dinero 30 min | Producto | 19 R$ | Consumible | Bloom |

- **Huevo Estelar** (único aleatorio pagado): Raro 75 % · Épico 22 % · Legendario 3 %; garantía: tras 10 huevos pagados sin Legendario, el siguiente es Legendario (divulgado y con contador visible). Mutación con su tabla visible. Si `ArePaidRandomItemsRestricted` (o falla la consulta): la tarjeta se oculta y el servidor rechaza la compra; si llegara un recibo, se entrega un Raro fijo.
- **Roblox Plus:** ventaja +1 hueco de jardín; el botón abre `PromptRobloxSubscriptionPurchase` solo si el jugador lo pulsa (5 s de enfriamiento); el servidor verifica `Player.HasRobloxSubscription`. Gana 250 R$/mes los 3 primeros meses pagados de cada suscriptor captado (hasta 750 R$).
- **Vídeo con recompensa** (cuando el juego tenga ≥ 2.000 visitantes únicos/mes): +25 % de suerte 10 min (gratis, no es aleatorio pagado).
- **Sin comercio entre jugadores en el MVP.**
- **Decisión sobre el pase "casi obligatorio":** se propuso un ×2 de velocidad a 3–4 R$ que "obligara" a todos. Se decidió conservar el precio bajo (primer pago fácil) pero **sin obligación**: es ×2 de entrenamiento personal, 5 R$, y se desbloquea gratis con racha de 3 días. Motivos: el 98 % no paga y el algoritmo premia la retención; un muro de pago en un juego cooperativo rompe el ambiente; choca con la regla de no pay-to-win.
- **Dinero:** Roblox se queda ~30 % por venta. DevEx estándar $0,0038/R$; EE. UU. 18+ verificado $0,0054/R$ (solo juegos R15 el 100 % del tiempo). Mínimo para cobrar: 30.000 R$ ganados. Creator Rewards: 5 R$/día por *Active Spender* si el juego es uno de sus 3 primeros del día con ≥ 10 min.

## 4. Arquitectura del código

```text
src/shared  -> ReplicatedStorage.Shared   Types, Net,
                                          Config/{Rarities,Mutations,Zones,Creatures,Products,Ambience,
                                                  Scenery,Quests,Sfx},
                                          Util/{Odds,WeightedRandom,Meter,NumberFormat,Formulas,CreatureBuilder}
src/server  -> ServerScriptService.Server Main.server, Services/{DataService,PolicyGate,PurchaseService,
                                          CreatureService,TerraformService,EconomyService,ThrowService,
                                          DailyService,PlusService,GardenVisualService,SceneryService,
                                          LaunchPlatformService,ProgressionService},
                                          Util/{Retry,RateLimiter,Validate,Perks,Progression}
src/client  -> StarterPlayerScripts.Client Main.client, Controllers/{Hud,Throw,Shop,Index,Ambience,Effects,
                                          CreatureAnimator,Progress}, UI/{Ui,UIPool,PriceService,Sfx,Vfx}
tests       -> ServerStorage.Tests        TestRunner (25 pruebas)
ReplicatedStorage.Remotes (default.project.json): TrainTap, ThrowStart, ThrowRelease, SetAutoLaunch,
  BuyUpgrade, RequestPurchase, OpenFreeEgg, ClaimDaily, ClaimQuest, TutorialAck (C→S) · ThrowResult, Notify (S→C)
ReplicatedStorage.ServerState (atributos): Planet, PlanetPercent (0–100), BloomUntil
Workspace.PlanetOrigin (opcional, lo coloca Dev B; si no existe el origen es (0,0,120)) ·
  Workspace.PlanetCells, PlanetScenery, LaunchPlatform, Jardin_<jugador> (los genera el servidor)
```

- **Estado al cliente** por atributos del Player escritos solo por el servidor: `Cash, Power, IncomePerSec, TrainRate, Luck, TrainingLevel, CapsuleLevel, BestZone, Discovered, FreeEggs, EggPity, DailyStreak, DailyAvailable, TurboUnlocked, PaidRandomRestricted, Pass_<clave>, PlusPerk, BoostUntil, AdLuckUntil, StarterPackOwned, AutoLaunchOn, DiscoveredMask, ShopAvailableAt, TutorialStep, QuestProgress1..3, QuestClaimed1..3, GoalText`.
- **DataService:** un registro `{data, lock}` por jugador en `PlayerData_v1` (no cambiar el nombre en producción). UpdateAsync con bloqueo de sesión (TTL 300 s), reintentos con backoff exponencial, autoguardado cada 120 s, guardado y liberación en `PlayerRemoving`, `BindToClose` con 25 s. En un place sin publicar (`game.GameId == 0`) usa memoria (pruebas locales). Campos nuevos: añadirlos a `defaultData` (se rellenan solos con `reconcile`).
- **ProcessReceipt** idempotente: anota `PurchaseId` (últimos 50) y guarda antes de devolver `PurchaseGranted`.
- **Probabilidades:** `Odds.forLuck` / `Odds.forEgg` se usan para MOSTRAR y para TIRAR (misma función).
- **Rendimiento:** pools (`UIPool`) para avisos, proyectiles y emisores de partículas; HUD refrescado 4 veces/s; partes del planeta, escenografía y criaturas ancladas y sin colisión; tope de escenografía por franja y animación de criaturas solo cerca de la cámara. En Studio los FPS se quedan en ≈15 aunque se quite contenido (tope de Studio): no usarlos como métrica; medir en un cliente real.
- **Pruebas:** `return require(game:GetService("ServerStorage").Tests.TestRunner).run()` con la herramienta MCP `execute_luau` (25 OK sobre `master`). En modo Edit el `require` cachea: tras cambiar de rama, córrelas en Play (`datamodel_type: Server`).

### Contrato de RemoteEvents (resumen)
| Evento | Args | Validación | Límite |
|---|---|---|---|
| TrainTap | — | perfil cargado | 8/s |
| ThrowStart | — | enfriamiento 1,2 s | 3/s |
| ThrowRelease | — | requiere ThrowStart; medidor con reloj del servidor | 3/s |
| SetAutoLaunch | boolean | tipo + posee pase | 3/s |
| BuyUpgrade | "training" / "capsule" | lista blanca + dinero | 5/s |
| RequestPurchase | clave de producto | lista blanca, id ≠ 0, PolicyService si es aleatorio, no comprado | 2/s |
| OpenFreeEgg | — | freeEggs > 0 | 2/s |
| ClaimDaily | — | no reclamado hoy (UTC) | 1/s |
| ClaimQuest | índice entero 1..3 | misión completa y no reclamada | 3/s |
| TutorialAck | — | solo vale en el paso 3 del tutorial | 2/s |

## 5. Flujo de trabajo

- **El código vive en Git y entra a Studio por Rojo.** Nunca se editan en Studio los scripts gestionados por Rojo. El mapa, modelos e interfaz hecha a mano viven en el place (Team Create).
- **Tres entornos:** copia local `.rbxl` (cada uno, datos en memoria) → **DEV** (experiencia privada del grupo, Team Create, solo un "integrador" conecta Rojo a la vez) → **PROD** (pública, se actualiza con *Publish to Roblox As* desde DEV).
- **Una rama por tarea**, PR revisado por el otro cofundador. Commits `feat:`, `fix:`, `chore:`, `docs:`.
- **Claude Code** edita archivos del repo (lee `CLAUDE.md`); el **MCP** se usa para inspeccionar, ejecutar Luau, playtest (`start_stop_play`, `user_keyboard_input`, `get_console_output`, `screen_capture`), generar mallas/materiales y auditar scripts (`script_grep`).
- **Auditoría de backdoors** antes de insertar cualquier recurso externo y cada sábado: buscar `require(<número>)`, `getfenv`, `setfenv`, `loadstring`, `string.reverse`, `string.char`, `\x`, `HttpService`, `InsertService`, `TeleportService`, `MarketplaceService`, `_G`; ningún modelo decorativo debe tener scripts.
- **Ajustes del juego:** R15 Only; Studio Access to API Services ON; HTTP Requests OFF; Third Party Sales/Teleports OFF; 10 jugadores por servidor.

## 6. Calendario

| Fecha | Hito |
|---|---|
| 25–29 nov | Semana 0: cuentas, grupo, repo, instalación, IA conectada a Studio, pruebas en verde |
| 30 nov – 6 dic | Semana 1: bucle central sólido, plataforma, HUD, efectos, sonidos |
| 7 – 13 dic | Semana 2: índice, jardín 3D, 30 criaturas, zonas visibles, FTUE |
| 14 – 20 dic | Semana 3: productos en Creator Hub, tienda ética, invitaciones, Share Links, celebración 100 % |
| 21 – 25 dic | Semana 4: congelar, prueba cerrada, miniaturas, publicar 16+ (jue 24), pagar tarifa Kids & Select |
| **Sáb 26 dic** | **Lanzamiento público** (plan B: sáb 9 ene 2027) |
| Viernes quincenales | 8 ene Índice y clasificación · 22 ene Ascenso de Jardinero · 5 feb Planeta Helado · 19 feb Mascota que acompaña · 5 mar Suscripción Jardinero · 19 mar Evento de primavera |

## 7. Lanzamiento y marketing (resumen)

- Publicar responde "Content May Vary" → solo 16+ verificados. Para todas las edades: cuestionario completo (objetivo **Minimal**), 2FA, verificación, evaluación Kids & Select y tarifa reembolsable de 1.000 R$ (reembolso si 25 jugadores muy comprometidos durante 60 días sin moderación).
- **Miniaturas** 1920×1080 con la **franja inferior libre** (contador de jugadores). 3 variantes: Día 1 vs Día 100 · "1 en 333.000" (Arcoíris Legendario) · combo de 6 jugadores. Icono 512×512.
- **Título** único: "Terraform Toss — Save the Planet" (ES: "Salva el Planeta"). Nunca copiar títulos/etiquetas de otros juegos.
- **Share Links:** uno por canal (TikTok, YouTube, Instagram, Discord) con LaunchData (≤ 200 bytes) leído con `player:GetJoinData().LaunchData` para un cosmético de bienvenida.
- **Vídeos por lotes:** 2 h cada 2 semanas → 10–15 clips verticales (Día 1 vs 100, "saqué un 1 en 333.000", combo de 10, cuenta atrás del 100 %, ranking de criaturas). Uno al día, sin música ni marcas de terceros.

## 8. Métricas y decisiones

Objetivos a 14 días: sesión media ≥ 19 min · D1 ≥ 20 % · D7 ≥ 6 % · sesiones con amigos ≥ 25 % · conversión ≥ 1,5 % (ARPPU ≥ 100 R$) · QPTR ≥ referencia del panel.
A 30 días, jugadores simultáneos medios: ≥ 1.000 invertir · 300–1.000 seguir · 100–300 iterar fuerte · < 100 pivotar a plan B ("Wishing Star RNG" o "Deal the Disaster") reutilizando sistemas.

## 9. Decisiones tomadas (no reabrir sin datos nuevos)

1. Concepto: Terraform Toss (híbrido lanzamiento + restauración cooperativa), no un clon de "Throw X".
2. La suerte no se vende; se gana con colección y eventos.
3. Sin comercio en el MVP.
4. Turbo de Arranque a 5 R$, desbloqueable gratis con racha de 3 días.
5. Progreso del planeta por servidor (no persistente); se guarda la contribución personal.
6. Sin IA en tiempo de ejecución (coste $0), por eso se descartó "Survive Your Ideas".
7. Interfaz del MVP creada por código; Dev B puede rediseñarla en Studio.
8. Balance del planeta x3 celdas por lanzamiento (27 nov): 100 % en ~22 min con 6 jugadores en vez de ~66.
9. Mundo, escenografía y criaturas procedurales en código (sin modelos externos ni recursos gratuitos sin auditar) hasta que haya arte real.
10. No optimizar sin un cuello de botella medido en un cliente real (los FPS de Studio no valen).

## 10. Pendiente / preguntas abiertas

- Nombre definitivo del juego y del estudio/grupo.
- Reparto de ingresos y acuerdo escrito entre cofundadores.
- Verificar en Creator Hub el precio actual de crear un grupo y los requisitos vigentes de Kids & Select antes de pagar.
- El código del repositorio inicial no se compiló fuera de Studio: en la semana 0 hay que pasar Script Analysis y corregir avisos de tipos con Claude.
- Ajustar balance con datos reales de la prueba cerrada (22 dic).
- Probar con 2+ jugadores y la celebración al 100 % (no se probaron); ajustar a ojo los valores visuales (ambiente, criaturas, plataforma, escenografía); identificar el aviso `ContentId rbxassetid://203785492` (origen desconocido); sustituir sonidos temporales; revisión cruzada de lo mergeado el 27 nov; invitar al segundo cofundador a GitHub.
