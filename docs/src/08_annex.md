# Anexo A. Prompts listos para Claude

Copien y peguen. Cambien lo que está entre `<>`. Todos asumen que Claude Code está abierto en la carpeta del repo (lee `CLAUDE.md` solo) y que el MCP de Studio está conectado.

## A.1 Primer día: verificar que todo compila

> *"Lee CLAUDE.md. Con Rojo ya sincronizado, usa `get_console_output` y `execute_luau` para: 1) ejecutar las pruebas (`return require(game:GetService("ServerStorage").Tests.TestRunner).run()`); 2) iniciar una prueba de juego, esperar 5 s, leer la consola y detenerla. Si hay errores o avisos de tipos (`--!strict`), corrígelos en los archivos de `src/` con cambios mínimos, explica cada cambio en una línea y repite hasta que todo esté limpio. No cambies la lógica del juego ni las reglas de CLAUDE.md."*

## A.2 Nueva función (plantilla)

> *"Tarea: <qué>. Archivos que probablemente toques: <lista>. Reglas: CLAUDE.md, --!strict, servidor autoritativo, cambios mínimos, no reescribas archivos enteros. Antes de editar, dame un plan de máximo 6 líneas y espera mi OK. Terminado cuando: <criterio observable>. Al final: ejecuta las pruebas, haz una prueba de juego corta, muéstrame la consola y una captura."*

## A.3 Nuevo RemoteEvent

> *"Necesito un RemoteEvent `<Nombre>` (cliente → servidor) para <propósito>. Añádelo a default.project.json, crea el manejador en `<Servicio>` con `RateLimiter.new(<N>, 1)`, valida cada argumento con `Validate`, comprueba el estado en el servidor (nunca confíes en el cliente) y responde con `Notify`. Añade la fila correspondiente a la tabla de contrato en docs. Dame el diff."*

## A.4 Prueba de juego automática

> *"Haz una prueba de juego con las herramientas de Studio: 1) `start_stop_play` para iniciar; 2) espera 3 s; 3) repite 5 veces: mantener Espacio con `user_keyboard_input` 0,8 s y soltar, esperar 2 s; 4) con `execute_luau` en el servidor lee los atributos Cash, Power y Discovered del jugador y `ReplicatedStorage.ServerState.PlanetPercent`; 5) `screen_capture`; 6) `get_console_output`; 7) detén la prueba. Dime si algo falló y por qué."*

## A.5 Balance

> *"Lee `Config/Zones.luau`, `Config/Rarities.luau` y `Util/Formulas.luau`. Con un script de simulación (Luau con `execute_luau` o en papel) estima cuánto tarda un jugador activo sin pases en llegar a cada zona, y cuánto tarda un servidor de 6 jugadores en llegar al 25 % del planeta. Objetivo: zona 4 ≈ 15 min, Bloom 25 % ≈ 17–20 min. Propón cambios de constantes (solo números) para acercarte, en una tabla antes/después."*

## A.6 Revisión de un pull request

> *"Revisa `git diff main...HEAD` como revisor estricto de Roblox. Busca: valores de juego que vengan del cliente, RemoteEvents sin RateLimiter o sin validación, `wait()`/`spawn()`/`InvokeClient`/`SetPrimaryPart`/`loadstring`, guardado de datos fuera de DataService, precios escritos a mano, falta de `--!strict`, artículos aleatorios sin PolicyService o sin probabilidades, y dark patterns en la UI. Lista los problemas por gravedad con archivo y línea. No edites nada."*

## A.7 Auditoría de backdoors

Ver el prompt completo en el capítulo 8.3.

## A.8 Construcción del mapa por IA

> *"Con `execute_luau` en modo edición, construye en Workspace una carpeta `Platform` con: una plataforma circular de 60 studs de diámetro en (0, 0, 0), material Slate, color gris azulado; 10 catapultas sencillas (base + brazo, 6–8 partes cada una) repartidas en círculo mirando hacia `PlanetOrigin`; todo anclado, `CastShadow=false` en lo decorativo. No crees scripts. Al final haz `screen_capture` desde una cámara elevada."*

## A.9 Criatura con IA

> *"Usa `generate_mesh` para crear '<nombre>, criatura low-poly adorable de la zona <zona>, estilo juguete, colores <paleta>, sin texto ni logos'. Inserta el resultado en `ServerStorage.CreatureModels.<id>` (crea la carpeta si no existe), escala para que mida ~3 studs y haz una captura."*

## A.10 Textos de la tienda y descripción

> *"Escribe en español e inglés: título (≤ 50 caracteres), descripción del juego (3 líneas + lista de novedades), y la descripción de cada pase de `Products.luau`. Tono honesto, sin urgencia falsa, sin prometer cosas que el juego no da, sin nombrar otros juegos."*

# Anexo C. Glosario

| Término | Significado |
|---|---|
| **Active Spender** | Jugador que gastó ≥ $9,99 en Roblox en los últimos 60 días; cuenta para Creator Rewards |
| **ARPPU** | Ingreso medio por jugador que paga |
| **Bloom Event** | Evento de 10 min al 25/50/75 % del planeta: ×2 dinero y +0,5 suerte para todos |
| **Bloqueo de sesión** | Marca en los datos para que solo un servidor los tenga abiertos a la vez |
| **Bookings** | Lo que los jugadores gastan en Robux, en dólares |
| **CCU** | Jugadores simultáneos (concurrent users) |
| **Creator Rewards** | Pagos de Roblox por traer y retener jugadores que gastan |
| **D1 / D7** | % de jugadores nuevos que vuelven al día 1 / día 7 |
| **DAU** | Usuarios activos diarios |
| **DevEx** | Programa para cambiar Robux ganados por dinero real |
| **Developer Product** | Compra repetible (consumible) dentro del juego |
| **FTUE** | Primera experiencia del usuario (primeros minutos) |
| **Game Pass / Pase** | Compra única y permanente |
| **LiveOps** | Operar el juego tras el lanzamiento: actualizaciones, eventos, códigos |
| **MCP** | Model Context Protocol: estándar que deja a Claude usar herramientas de Studio |
| **Pity** | Garantía: tras N intentos sin premio mayor, el siguiente lo da |
| **PolicyService** | Servicio que dice qué puede hacer cada jugador según su país/edad |
| **QPTR** | De quienes ven la miniatura, cuántos entran y juegan de verdad |
| **R15** | Avatar con 15 partes articuladas (requisito de la tasa DevEx 18+) |
| **RemoteEvent** | Mensaje entre cliente y servidor |
| **Rojo** | Herramienta que sincroniza archivos del disco con Studio |
| **Share Link** | Enlace rastreable a tu juego con datos de lanzamiento opcionales |
| **Team Create** | Edición colaborativa del place en Studio |

# Anexo D. Fuentes oficiales para revisar antes de decidir

Roblox cambia sus reglas a menudo. Estas páginas son la fuente de verdad (consultadas el 24 nov 2026):

| Tema | Dónde |
|---|---|
| Servidor MCP de Studio | create.roblox.com/docs/studio/mcp |
| Rojo y Rokit | create.roblox.com/docs/projects/external-tools · github.com/rojo-rbx/rokit |
| Publicar juegos (16+, todas las edades, tarifas) | create.roblox.com/docs/production/publishing/publish-games-and-places |
| Artículos aleatorios pagados | create.roblox.com/docs/production/monetization/paid-random-items |
| Precios regionales | create.roblox.com/docs/production/monetization/regional-pricing |
| Roblox Plus para creadores | create.roblox.com/docs/production/monetization/roblox-plus |
| Tasa DevEx EE. UU. 18+ y R15 | create.roblox.com/docs/production/monetization/18-plus-devex-rate |
| Vídeo con recompensa | create.roblox.com/docs/production/promotion/rewarded-video-ads |
| Share Links | create.roblox.com/docs/production/promotion/share-links |
| Claude Code (instalación) | code.claude.com/docs/en/setup |
| Datos de mercado | Carta a accionistas de Roblox T3 2026 (sec.gov / ir.roblox.com) |
| Análisis de la Fase 1 | Informe de investigación de este proyecto (24 nov 2026) |
