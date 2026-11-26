# 7. Flujo de trabajo diario con IA

## 7.1 Quién hace qué con Claude

| Tarea | Herramienta | Cómo |
|---|---|---|
| Escribir o cambiar código | **Claude Code** en la carpeta del repo | Lee `CLAUDE.md` solo; edita archivos `.luau`; Rojo los manda a Studio |
| Probar lo que escribió | Claude Code + **MCP** | `execute_luau` para pruebas, `start_stop_play` + input simulado + consola + captura |
| Construir mapa y decorado | Claude Desktop o Code + MCP, o **Roblox Assistant** | `execute_luau` para colocar partes, `generate_mesh`/`generate_material` |
| Diseñar, balancear, escribir textos | **Claude Desktop** con el proyecto "Terraform Toss" | Sube `CONTEXTO_PROYECTO.md` y este PDF como conocimiento del proyecto |
| Revisar un *pull request* | Claude Code (`git diff main`) | Prompt de revisión del anexo A |
| Auditar modelos gratuitos | Claude + MCP (`script_grep`) | Protocolo del capítulo 8 |

## 7.2 La rutina de una sesión (y cómo ahorrar cuota del plan Pro)

El plan Pro tiene límites de uso que se reinician cada pocas horas. Lo que más gasta: conversaciones larguísimas, leer archivos enteros sin necesidad, reescribir archivos completos y capturas/vídeo en bucle.

1. **Una tarea pequeña por sesión.** "Añade el contador de celdas restauradas al HUD", no "haz la interfaz".
2. Empieza en una rama: `git switch -c feat/hud-celdas`.
3. Abre Claude Code en la carpeta: `claude`. Pega el prompt de la tarea (anexo A tiene plantillas).
4. Pide **primero un plan corto** ("antes de editar, dime qué archivos tocarás y qué cambiarás, en 5 líneas"). Aprueba o corrige.
5. Deja que edite. Exige **cambios puntuales**, no archivos reescritos.
6. Haz que **pruebe**: pruebas automáticas + una prueba de juego con consola. Las capturas son baratas; el vídeo, caro: solo si hace falta.
7. Revisa tú el `git diff` en VS Code. Si no lo entiendes, pídele que te lo explique.
8. Commit y *pull request*: `git add -A && git commit -m "feat: contador de celdas en HUD" && git push -u origin feat/hud-celdas`.
9. **Cierra la sesión** (`/clear` o nueva conversación) antes de la siguiente tarea. El contexto viejo gasta cuota y confunde.
10. Usa el modelo más ligero disponible para tareas mecánicas (`/model` en Claude Code) y reserva el más potente para arquitectura, errores difíciles y revisiones.

## 7.3 Ritmo semanal del equipo

| Día | Qué |
|---|---|
| Lunes (15 min, llamada) | Elegir 3–5 tareas de la semana del plan (cap. 10). Cada tarea = una rama |
| Martes–viernes | Sesiones cortas. Cada *pull request* lo revisa el otro en < 24 h |
| Sábado | **Integración**: el integrador fusiona, conecta Rojo a DEV, prueba de juego juntos 30 min |
| Domingo | Descanso o tareas de contenido (criaturas, decorado, vídeos) |

## 7.4 Prompts de ejemplo de buena calidad

**Buena tarea (concreta, con criterio de terminado):**

> *"Tarea: en `HudController.luau`, muestra debajo del dinero el texto 'Celdas: N', donde N viene de un atributo del jugador `CellsRestored` que debes sincronizar desde `EconomyService.sync`. Reglas: --!strict, cambios mínimos, no toques otros archivos. Terminado cuando: las pruebas pasan, haces una prueba de juego, lanzas 3 veces simulando la barra espaciadora (mantener 0,8 s y soltar) y la captura muestra el contador subiendo."*

**Mala tarea:** *"Mejora la interfaz."* (sin alcance, sin criterio, gasta cuota y produce cambios enormes difíciles de revisar).

# 8. Seguridad: exploits, backdoors y auditoría

## 8.1 Modelo de amenazas (lo que de verdad pasa en Roblox)

| Amenaza | Ejemplo | Defensa en este proyecto |
|---|---|---|
| Cliente modificado (exploit) | Envía "distancia = 10^20" o "dame 1.000 huevos" | El cliente **nunca** envía valores de juego; el servidor calcula todo |
| Spam de eventos | 500 lanzamientos por segundo | `RateLimiter` en cada RemoteEvent |
| Argumentos basura | NaN, infinito, tablas gigantes, strings de 1 MB | `Validate.luau` (tipo, rango, NaN, longitud, lista blanca) |
| Duplicación de objetos | Cambiar de servidor muy rápido para cargar datos viejos | Bloqueo de sesión en `DataService` |
| Compra duplicada | Reintentos de `ProcessReceipt` | Recibo anotado + guardado antes de confirmar |
| **Backdoor en modelo gratuito** | Un árbol del Creator Store con un script oculto que da control remoto a un desconocido | Protocolo 8.3 |
| Plugin malicioso | Un plugin que inyecta scripts al guardar | Solo plugins de autores conocidos, revisar permisos |

## 8.2 Reglas para cada RemoteEvent nuevo

1. Definirlo en `default.project.json` (carpeta `Remotes`).
2. En el servidor: `RateLimiter.new(N, 1)` con N lo más bajo razonable.
3. Validar **cada** argumento con `Validate` (o `typeof` + rango). Rechazar en silencio lo inválido.
4. El servidor comprueba **estado** (¿tiene dinero?, ¿está en enfriamiento?, ¿le pertenece?), nunca lo que el cliente dice que tiene.
5. Respuesta por otro evento (`Notify` o específico). **Nunca** `RemoteFunction:InvokeClient`.
6. Añadir la fila al contrato (capítulo 9.2) en el mismo *pull request*.

## 8.3 Protocolo de auditoría de modelos, plugins y assets

**Antes de insertar cualquier recurso de terceros** (Creator Store, Toolbox, `insert_asset`):

1. Preferir recursos de **creadores verificados** y con muchas valoraciones. Mejor aún: generar el recurso (`generate_mesh`, Blender) o hacerlo con partes.
2. Insertarlo **primero en la copia local**, nunca en DEV.
3. Pedir a Claude este escaneo (MCP `script_grep` sobre el place):

> *"Audita el place por posibles backdoors. Usa `search_game_tree` para listar TODOS los Script, LocalScript y ModuleScript fuera de ServerScriptService.Server, ReplicatedStorage.Shared, StarterPlayerScripts.Client y ServerStorage.Tests. Después usa `script_grep` con cada patrón: `require%(%d`, `getfenv`, `setfenv`, `loadstring`, `string.reverse`, `string.char`, `\\x`, `HttpService`, `InsertService`, `TeleportService`, `MarketplaceService`, `:Kick`, `Players:GetPlayers`, `_G`, `shared%.`. Para cada coincidencia dime archivo, línea y si es legítima. Marca como SOSPECHOSO cualquier script dentro de un modelo decorativo."*

4. **Un modelo decorativo no necesita scripts.** Si un árbol, roca o casa trae scripts, se borran todos.
5. Revisar **valores ocultos**: scripts con `Disabled`/`Enabled` cambiado, nombres que imitan servicios ("Workspace " con espacio), objetos dentro de `Lighting`, `SoundService`, `Chat`, `StarterGui` que no pusieron ustedes.
6. Solo entonces, pasarlo a DEV.

**Auditoría semanal** (sábado, 5 minutos): repetir el escaneo del paso 3 sobre DEV. Cualquier script nuevo fuera de las carpetas de Rojo es una alerta.

## 8.4 Configuración segura del juego

| Ajuste | Valor |
|---|---|
| Allow HTTP Requests | OFF (no lo necesitan en el MVP) |
| Allow Third Party Sales | OFF |
| Allow Third Party Teleports | OFF |
| `ServerScriptService.LoadStringEnabled` | false (por defecto) |
| Plugins instalados | Solo Rojo (oficial) y los que acuerden por escrito |
| Permisos de Team Create | Solo los dos cofundadores. Nadie más con edición |
| Cuenta de Roblox | 2FA, correo verificado, contraseñas distintas a las de GitHub |
| Secretos | Nunca en el repositorio (no hay ninguno en el MVP) |

## 8.5 Checklist de revisión de seguridad para cada *pull request*

- [ ] `--!strict` en todos los archivos tocados.
- [ ] Ningún uso de `wait()`, `spawn()`, `delay()`, `loadstring`, `getfenv`, `InvokeClient`, `SetPrimaryPart`.
- [ ] Todo RemoteEvent nuevo tiene `RateLimiter` + validación + fila en el contrato.
- [ ] Ningún valor de juego (dinero, distancia, rareza, precio) llega del cliente.
- [ ] Datos guardados solo a través de `DataService`.
- [ ] Ningún precio escrito a mano.
- [ ] Pruebas automáticas en verde.
