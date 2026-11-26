# 6. Instalación paso a paso (hasta tener la IA dentro de Studio)

Hagan este capítulo **juntos, en una videollamada**, cada uno en su computadora. Tiempo estimado: 2–3 horas la primera vez. Al terminar, los dos tendrán: el repositorio en GitHub, Rojo sincronizando el código con Studio y Claude conectado a Studio por MCP, capaz de leer el juego, ejecutar código y hacer pruebas de juego.

## 6.1 Mapa de cómo encaja todo

| Pieza | Qué es | Para qué la usan |
|---|---|---|
| **Roblox Studio** | El editor oficial | Construir el mapa, la interfaz, probar, publicar |
| **Servidor MCP de Studio** | Viene integrado en Studio | Deja que Claude vea y controle tu Studio abierto: leer el árbol, ejecutar Luau, iniciar pruebas, simular teclado y ratón, leer la consola, hacer capturas |
| **Claude Code** | Claude en la terminal, incluido en el plan Pro | Escribir y editar el código `.luau` del repositorio; usa el MCP para probarlo en Studio |
| **Claude Desktop** | La app de escritorio de Claude | Preguntas, diseño, revisar ideas; también puede usar el MCP |
| **Rojo** | Sincroniza archivos de tu disco con Studio | Que el código viva en archivos (y en Git), no dentro del place |
| **Rokit** | Instalador de herramientas | Que los dos usen exactamente la misma versión de Rojo |
| **Git + GitHub** | Control de versiones | Historial, ramas, revisiones, nunca perder trabajo |
| **VS Code** | Editor de código | Leer y revisar lo que escribe Claude, con autocompletado Luau |

**La regla de oro del flujo:** el **código** vive en Git y entra a Studio por Rojo. El **mapa, la interfaz diseñada a mano y los modelos** viven en el place de Studio (Team Create). Claude edita código en el disco (Claude Code) y usa el MCP para **probar** en Studio.

## 6.2 Cuentas (día 0)

### Roblox (cada uno)

1. Cuenta con correo verificado y **verificación en dos pasos (2FA)** activada (Configuración → Seguridad).
2. **Verificación de edad/ID** (Configuración → Información de la cuenta): necesaria para publicar para mayores de 16 (estimación facial o ID) y, para todas las edades, los mayores de 18 necesitan **ID oficial**.
3. Antigüedad mínima de la cuenta para publicar: 2 días.

### Grupo de Roblox (lo crea uno, Dev A)

1. roblox.com → Comunidades/Grupos → **Crear grupo** (cuesta ~100 Robux; confirmen el precio en la pantalla). Nombre del estudio, por ejemplo "Terraform Studios".
2. Invita al otro cofundador. Crea un rol "Cofundador" con permisos de **edición de experiencias** y **gestión de monetización** (Creator Hub → Grupo → Roles → Permisos). Incluye el permiso de crear *Share Links* (Collaboration → Roles → Permissions).
3. **El juego se publica bajo el grupo**, no bajo una cuenta personal. Así el dinero entra al grupo y se reparte con **pagos recurrentes por porcentaje** (Grupo → Ingresos → Pagos).
4. **Hagan un acuerdo por escrito** (aunque sea un documento simple firmado por los dos): reparto de ingresos (ej. 50/50), qué pasa si uno deja el proyecto, quién es dueño del grupo y de la cuenta de GitHub. Es la conversación más incómoda y la más importante.

### GitHub (cada uno)

1. Cuenta en github.com con 2FA.
2. Dev A crea una **organización gratuita** (ej. `terraform-studios`) y dentro un repositorio **privado** `terraform-toss`. Invita a Dev B como miembro con permiso de escritura.
3. En el repositorio: Settings → Branches → regla de protección para `main` (exigir *pull request* y 1 aprobación). Así ninguno sube cambios a `main` sin que el otro los vea.

### Claude (cada uno)

Cada uno necesita su propia suscripción **Claude Pro** (incluye Claude Code). No hace falta clave de API: Claude Code se conecta con su cuenta.

## 6.3 Instalar programas (cada uno en su PC)

### Paso 1 — Roblox Studio
Descarga desde create.roblox.com e instala. Ábrelo una vez e inicia sesión. Mantenlo **siempre actualizado** (el MCP evoluciona con Studio).

### Paso 2 — Git
- **Windows:** descarga "Git for Windows" de git-scm.com e instala con las opciones por defecto (incluye Git Bash, que Claude Code aprovecha).
- **Mac:** en la Terminal, `xcode-select --install`.
- Configura tu nombre (una sola vez):

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu-correo@ejemplo.com"
```

### Paso 3 — VS Code y extensiones
Instala VS Code (code.visualstudio.com) y estas extensiones (pestaña Extensiones, busca por nombre):

| Extensión | Autor | Para qué |
|---|---|---|
| Luau Language Server | JohnnyMorganz | Autocompletado y errores de tipo `--!strict` con la API de Roblox |
| Rojo | evaera | Botón para iniciar/parar Rojo desde VS Code |
| StyLua | JohnnyMorganz | Formato automático al guardar |
| Selene | Kampfkarren | Detecta errores comunes (lint) |

### Paso 4 — Rokit (gestor de herramientas)

**Windows (PowerShell):**
```powershell
Invoke-RestMethod https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | Invoke-Expression
```
**Mac (Terminal):**
```bash
curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
```
Cierra y vuelve a abrir la terminal. Comprueba con `rokit --version`.

### Paso 5 — Claude Desktop
Descarga desde claude.ai/download, instala e inicia sesión con tu cuenta Pro.

### Paso 6 — Claude Code
Instalador oficial (sin permisos de administrador). Comprueben el comando vigente en la documentación oficial de Claude Code si alguno falla.

**Windows (PowerShell):**
```powershell
irm https://claude.ai/install.ps1 | iex
```
**Mac (Terminal):**
```bash
curl -fsSL https://claude.ai/install.sh | bash
```
Luego `claude --version` y `claude doctor`. La primera vez que ejecutes `claude` se abrirá el navegador para iniciar sesión con tu cuenta Pro.

## 6.4 Crear el repositorio (Dev A) y clonarlo (Dev B)

**Dev A**, una sola vez:

1. Descomprime `terraform-toss-starter.zip` en tu carpeta de proyectos.
2. En una terminal dentro de la carpeta:

```bash
git init -b main
git add .
git commit -m "chore: estructura inicial de Terraform Toss"
git remote add origin https://github.com/terraform-studios/terraform-toss.git
git push -u origin main
```

**Dev B:**

```bash
git clone https://github.com/terraform-studios/terraform-toss.git
cd terraform-toss
```

**Los dos**, dentro de la carpeta del proyecto:

```bash
rokit install
rokit add JohnnyMorganz/StyLua
rokit add Kampfkarren/selene
```

(`rokit add` fija la última versión en `rokit.toml`; hagan commit de ese archivo para que el otro tenga la misma versión.) Si Rokit pide confirmar que confías en una herramienta, acepta solo las de esta lista.

Abran la carpeta en VS Code (`code .`). Los errores de tipo de Luau aparecerán en rojo; con el *sourcemap* de Rojo, la extensión entiende `script.Parent.X` y `ReplicatedStorage.Shared.X`.

## 6.5 Las tres experiencias de Roblox

Para no romper el juego real mientras trabajan, usen **tres entornos**:

| Entorno | Qué es | Datos | Quién lo usa |
|---|---|---|---|
| **Copia local** | Un archivo `.rbxl` en tu PC, sin publicar | En memoria (el código lo detecta solo; no se guarda nada) | Cada uno, para probar su rama |
| **DEV** | Experiencia privada del grupo con Team Create | DataStores reales de DEV | Los dos: mapa, interfaz, integración |
| **PROD** | Experiencia pública del grupo | DataStores reales de jugadores | Solo recibe versiones aprobadas |

### Crear DEV (Dev A)
1. Studio → New → **Baseplate**.
2. File → **Publish to Roblox** → crear experiencia nueva, **Creator: el grupo**, nombre "Terraform Toss DEV". Déjala privada.
3. **Home → Game Settings**:
   - *Security* → **Enable Studio Access to API Services**: ON (DataStores en Studio). *Allow HTTP Requests*: OFF. *Allow Third Party Sales*: OFF. *Allow Third Party Teleports*: OFF.
   - *Places* → máximo de jugadores por servidor: **10**.
4. **Avatar → Settings → … → R15 Only** (requisito de la tasa DevEx 18+). Comprueben que ningún sistema del juego cambia a R6.
5. Activa **Team Create** (Home → Collaborate) y añade a Dev B (o da permisos de edición al rol del grupo).
6. Crea en Workspace una parte anclada llamada **`PlanetOrigin`** delante de la zona de aparición (ahí empieza la cuadrícula del planeta).

### Crear PROD (Dev A, en la semana 4)
Igual que DEV, nombre definitivo. Se actualiza con **File → Publish to Roblox As…** desde DEV, nunca editándola directamente.

### Copia local (cada uno)
Abre DEV → File → **Save to File As…** → `terraform-toss-local.rbxl` (está en `.gitignore`). Ábrela cuando quieras probar una rama sin afectar a nadie.

## 6.6 Conectar Rojo

1. Instala el plugin de Rojo en Studio, en la terminal del proyecto:

```bash
rojo plugin install
```

   (o búscalo en el Creator Store; usa solo el oficial de *Rojo*.)

2. En la terminal del proyecto:

```bash
rojo serve
```

3. En Studio: pestaña **Plugins → Rojo → Connect**. Verás aparecer `ReplicatedStorage.Shared`, `ReplicatedStorage.Remotes` (10 RemoteEvents), `ServerScriptService.Server`, `ServerStorage.Tests` y `StarterPlayer.StarterPlayerScripts.Client`.
4. Pulsa **Play**. En Output debe salir `[Terraform Toss] Servidor listo` y aparecer la cuadrícula gris del planeta. Mantén LANZAR y suelta: verás volar la cápsula y ponerse verdes unas celdas.

### Reglas Rojo + Team Create (para no pisarse)

1. **Nunca editen en Studio los scripts que gestiona Rojo** (todo lo de `Server`, `Shared`, `Client`, `Tests`). Rojo los sobrescribe y el cambio se pierde. Se editan en el disco (VS Code o Claude Code).
2. **Solo una persona conecta Rojo al place DEV a la vez**: el "integrador". Normalmente el que acaba de fusionar algo en `main`. Antes de conectar: `git pull` en `main`.
3. Para trabajar en una rama, conecta Rojo a tu **copia local**, no a DEV.
4. Todo lo que no sea código (mapa, modelos, interfaz hecha a mano) se hace en DEV con Team Create y ahí se queda. Rojo no lo toca porque esas carpetas no están en `default.project.json`.
5. Si crean interfaz a mano en Studio y quieren versionarla, guárdenla como modelo (`.rbxm`) en `assets/` y añádanla al proyecto de Rojo (decisión del equipo; en el MVP la interfaz se crea por código).

## 6.7 Encender la IA dentro de Studio (servidor MCP)

### Paso 1 — Activar el servidor en Studio
1. Abre **Assistant** (el asistente de IA de Studio).
2. Pulsa **…** → **Manage MCP Servers**.
3. Activa **Enable Studio as MCP server**.

### Paso 2 — Conectar Claude (elige A, B o C)

**A. Conexión rápida (recomendada).** En **Assistant Settings → MCP Servers → Quick connect**, despliega la lista y activa **Claude Desktop** y/o **Claude Code**. Si no aparecen, instálalos y reinicia Studio. Después reinicia Claude.

**B. Claude Desktop manual.** Claude Desktop → Settings → Developer → **Edit Config** abre `claude_desktop_config.json`. Pega (si ya tienes otros servidores, añade solo la entrada `Roblox_Studio` dentro de `mcpServers`, separada por coma):

Windows:
```json
{
  "mcpServers": {
    "Roblox_Studio": {
      "command": "cmd.exe",
      "args": ["/c", "%LOCALAPPDATA%\\Roblox\\mcp.bat"]
    }
  }
}
```
Mac:
```json
{
  "mcpServers": {
    "Roblox_Studio": {
      "command": "/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP"
    }
  }
}
```
Guarda y reinicia Claude Desktop.

**C. Claude Code manual.** En la terminal, dentro de la carpeta del proyecto:

Windows:
```powershell
claude mcp add --transport stdio Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat
```
Mac:
```bash
claude mcp add --transport stdio Roblox_Studio -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP
```
Comprueba con `claude mcp list`. Dentro de Claude Code, el comando `/mcp` muestra el estado.

### Paso 3 — Verificar
En Studio: Assistant → … → Manage MCP Servers → bajo *Enable Studio as MCP server* debe verse el **indicador verde** con el número de clientes conectados.

### Paso 4 — Primera prueba (copia y pega en Claude)

> *"Usa las herramientas de Roblox Studio. 1) Con `search_game_tree` lista lo que hay en ServerScriptService y ReplicatedStorage. 2) Con `execute_luau` ejecuta `return require(game:GetService("ServerStorage").Tests.TestRunner).run()` y dime el resultado. 3) Inicia una prueba de juego con `start_stop_play`, espera 5 segundos, lee la consola con `get_console_output`, haz una captura con `screen_capture` y detén la prueba."*

Si las 10 pruebas salen ✔ y ves `[Terraform Toss] Servidor listo` en la consola, **la IA ya trabaja dentro de Studio**.

### Herramientas MCP que más van a usar

| Herramienta | Uso típico |
|---|---|
| `search_game_tree`, `inspect_instance` | "¿Qué hay en el mapa?", "¿qué propiedades tiene PlanetOrigin?" |
| `script_read`, `script_grep`, `script_search` | Leer y buscar en los scripts del place (auditoría) |
| `execute_luau` | Ejecutar pruebas, consultas o crear cosas en el mapa |
| `start_stop_play`, `get_studio_state` | Iniciar y detener pruebas de juego |
| `character_navigation`, `user_keyboard_input`, `user_mouse_input` | Simular a un jugador (mantener Espacio para lanzar, caminar) |
| `get_console_output`, `screen_capture` | Ver errores y cómo se ve |
| `generate_mesh`, `generate_material`, `generate_procedural_model` | Criaturas, decorado y materiales por texto |
| `search_asset`, `insert_asset` | Buscar e insertar recursos del Creator Store (¡pasar auditoría!) |
| `save_place` | Guardar (nunca publica) |
| `multi_edit` | Editar scripts **dentro** del place. **No lo usen para los scripts de Rojo** |

> **Advertencias oficiales.** Los clientes MCP pueden leer y modificar los places abiertos: conecten solo clientes de confianza. `save_place` nunca publica. Si el place nunca se guardó, guárdalo tú una vez antes de que el agente pueda hacerlo. `submit_feedback` puede enviar informes a Roblox sin preguntar (el agente te avisa y para si se lo pides).
