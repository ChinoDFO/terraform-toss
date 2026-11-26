# Cómo usar este documento

Este es el **plan maestro** de *Terraform Toss* (nombre provisional). Está pensado para que dos personas, sin experiencia previa trabajando juntas en Roblox, puedan ir de cero a un juego publicado, monetizado de forma ética y con la IA (Claude) trabajando dentro de Roblox Studio.

Léelo en orden la primera vez. Después úsalo como manual de consulta: cada capítulo es independiente.

| Capítulo | Para qué sirve | Quién lo lee |
|---|---|---|
| 1. Resumen ejecutivo | Entender la apuesta en 3 minutos | Los dos |
| 2. Mercado y por qué esta idea | Las cifras que justifican la decisión | Los dos |
| 3. Diseño del juego (GDD) | Qué se construye exactamente | Los dos |
| 4. Monetización ética | Qué se vende, a qué precio y con qué reglas | Los dos |
| 5. Tu idea del pase "casi obligatorio" | Análisis honesto y la versión recomendada | Los dos |
| 6. Instalación paso a paso | Cuentas, programas, Rojo, Git y **la IA dentro de Studio** | Los dos (cada uno en su PC) |
| 7. Flujo de trabajo con IA | Cómo trabajar a diario con Claude sin gastar la cuota | Los dos |
| 8. Seguridad y auditoría | Exploits, backdoors y modelos gratuitos | Dev A (y revisión de Dev B) |
| 9. Arquitectura técnica | Árbol de instancias, contrato de RemoteEvents, módulos | Dev A |
| 10. Plan de producción | Semana a semana, quién hace qué | Los dos |
| 11. Lanzamiento y marketing | 30 días, miniaturas, TikTok/Shorts, algoritmo | Dev B (y Dev A) |
| 12. LiveOps | Calendario quincenal de actualizaciones | Los dos |
| 13. Métricas y decisiones | Cuándo seguir, cuándo cambiar | Los dos |
| 14. Checklists | Antes de publicar, antes de cada actualización | Los dos |
| Anexos | Prompts listos para Claude, código completo, glosario, fuentes | Según la tarea |

> **Convención de roles.** En todo el documento: **Dev A = Sistemas** (servidor, datos, compras, seguridad) y **Dev B = Experiencia** (mapa, interfaz, arte, sonido, primeros minutos, marketing). Repartan los roles según quién se sienta más cómodo con cada cosa; ambos usan Claude.

> **Archivos que acompañan este PDF.** (1) `terraform-toss-starter.zip`: el repositorio inicial con todo el código de este documento, listo para `rojo serve`. (2) `CONTEXTO_PROYECTO.md`: el archivo para cargar en el Claude de cada uno (proyecto de Claude) para que sepa de qué va todo. (3) `CLAUDE.md` viene dentro del repositorio: son las reglas que Claude Code lee automáticamente al trabajar en el código.

## Qué es dato verificado y qué es estimación

Las cifras de mercado y las reglas de la plataforma se comprobaron con fuentes oficiales (documentación de Roblox Creator Hub y la carta a accionistas del T3 2026) a fecha **24 de noviembre de 2026**. Las cifras de jugadores simultáneos de juegos concretos vienen de *trackers* no oficiales. Los objetivos de retención, los modelos de ingresos y el balance de la economía son **estimaciones propias** que deben ajustarse con datos reales después del lanzamiento. Roblox cambia sus reglas con frecuencia: antes de pagar cualquier tarifa o publicar, revisen la página oficial enlazada en el anexo de fuentes.

# 1. Resumen ejecutivo

**El juego.** *Terraform Toss* es un juego cooperativo de lanzar cápsulas de semillas a un planeta gris y muerto. Cada lanzamiento convierte en vida las casillas donde cae. El porcentaje de planeta restaurado es **compartido por todo el servidor**: todos empujan la misma barra de 0 % a 100 %. Cada lanzamiento también te da una criatura (según la distancia y la rareza) que vive en tu jardín y genera dinero por segundo. Con ese dinero mejoras tu entrenamiento y tu cápsula para lanzar más lejos, llegar a zonas nuevas y encontrar criaturas mejores.

**La frase para la miniatura:** *"Lanza semillas. Salva el planeta. Día 1 → Día 100."*

**Por qué esta idea y no un clon.** La ola de juegos "Throw X" (*Throw Food For Animals*, ~236 K jugadores simultáneos) está en su pico; un clon saldría 4 meses tarde y el original se queda la mayor parte del tráfico. Los juegos que Roblox ya no considera "únicos" pierden prioridad en recomendaciones. *Terraform Toss* combina las dos tendencias más fuertes de la captura que analizamos (lanzar con rarezas + restauración cooperativa "Día 1 → Día 100" estilo *Sweep The Moon*, que tiene 29,7 min de sesión media y 97,8 % de aprobación) en un bucle propio.

**Lo que querías, incluido.** El "+1 por segundo" es el entrenamiento de *Poder de lanzamiento*. La "suerte que sube al coleccionar" es el índice de criaturas: cada criatura nueva sube tu suerte permanente. Ambos son piezas internas del bucle, no el gancho entero.

| Decisión | Valor |
|---|---|
| Género | Incremental cooperativo de lanzamiento + restauración compartida |
| Público | Global; mayores de 16 al principio (regla de Roblox), luego todas las edades |
| Servidor | 10 jugadores |
| Sesión objetivo | 19+ minutos (primer hito de servidor diseñado para el minuto ~17–20) |
| MVP | 1 planeta, 6 zonas, 30 criaturas, 6 mutaciones, eventos Bloom, 5 pases, 3 productos |
| Tiempo al MVP | 4 semanas de construcción + 1 de pruebas |
| Lanzamiento | **Sábado 26 de diciembre de 2026** (plan A) · 9 de enero de 2027 (plan B) |
| Costes | ~1.100 Robux (grupo + tarifa reembolsable de publicación para todas las edades) y $0 en API |
| Monetización | Pases permanentes, consumibles, huevos con probabilidades públicas, Roblox Plus, vídeo con recompensa |
| Herramientas | Roblox Studio + servidor MCP integrado, Claude Code / Claude Desktop (plan Pro), Rojo, Git/GitHub |

**Las 5 cosas que no se negocian.**

1. Todo el código en Luau `--!strict`, con el servidor como autoridad: el cliente pide, el servidor valida y decide.
2. Ningún precio escrito a mano: siempre leído en vivo (precios regionales y descuento de Roblox Plus).
3. Cualquier cosa aleatoria que se pague pasa por PolicyService, muestra probabilidades exactas antes de comprar, garantiza un mínimo y tiene alternativa gratuita.
4. Avatares solo R15 desde el día 1 (requisito para la tasa DevEx de $0.0054 por Robux de jugadores adultos de EE. UU.).
5. Lo que se compra acelera tu progreso **personal**; nunca bloquea el progreso **compartido**.

# 2. Mercado y por qué esta idea

## 2.1 Estado de Roblox (T3 2026, carta a accionistas)

| Métrica | Dato | Qué significa para ustedes |
|---|---|---|
| Usuarios activos diarios | 138 M (−9 % interanual, +12 % trimestral) | El público es enorme pero ya no crece solo: hay que ganarse cada jugador |
| Bookings (gasto) | $1.697 M en el trimestre (−12 %) | Menos gasto total, pero... |
| Pagadores mensuales | 30 M (−16 %), cada uno gasta +5 % | ...cada pagador gasta más: cuidar al que paga |
| Edad (usuarios verificados) | 34 % < 13 · 37 % 13–17 · 29 % 18+ | Los adolescentes son el bloque más grande |
| Gasto por edad (EE. UU.) | Los 18+ gastan ≥ 50 % más que los menores | Por eso existe la tasa DevEx 18+ |
| Regiones que más crecen | India +37 %, Japón +33 %, Arabia Saudí +30 % | Volumen de jugadores; precios regionales para que puedan pagar |
| Uso de IA | > 80 % del top 100 usa IA; usuarios del MCP ×5 desde el T2 | Su flujo (MCP + Claude) es el estándar ganador, no una ventaja exclusiva |
| Juegos nuevos | 40 % del top 100 de recomendaciones semanal tiene < 3 meses | Un juego nuevo sí puede entrar |

## 2.2 Cómo decide Roblox qué recomendar (2026)

En 2026 el algoritmo de "Recomendadas para ti" cambió tres veces. Hoy premia, en este orden práctico: **(1) que la gente vuelva** (retención a largo plazo), **(2) que gaste de forma sostenible** (no picos de compras impulsivas), **(3) que juegue con amigos** y **(4) que el juego sea único**. Los juegos con metadatos y archivos muy parecidos a otros "ya no se priorizan". Traducción a diseño:

- Diseñen para que *Terraform Toss* sea **el primer juego del día** del jugador (recompensa diaria, ingresos offline que se cobran al entrar, eventos de servidor).
- Monetización de **valor permanente** (pases) antes que consumibles agresivos.
- Todo lo social debe dar ventaja real: lanzamientos combinados, eventos compartidos, recompensa al 100 % para todos.
- Título, miniatura, descripción y mapa **propios**.

## 2.3 Las reglas de dinero que condicionan el diseño

| Regla | Dato verificado | Implicación |
|---|---|---|
| DevEx estándar | $0.0038 por Robux | Base de todos los cálculos |
| DevEx EE. UU. 18+ | $0.0054 por Robux (+42 %), solo compras de jugadores de EE. UU. con edad verificada 18+, en juegos donde el personaje es R15 el 100 % del tiempo | Activar "R15 Only" en Avatar Settings desde el día 1 |
| Mínimo para cobrar DevEx | 30.000 Robux ganados | Primera meta financiera |
| Creator Rewards | 5 Robux al día por cada *Active Spender* (gastó ≥ $9,99 en Roblox en 60 días) si tu juego es uno de sus 3 primeros del día con ≥ 10 min | Recompensa diaria + motivo para entrar temprano |
| Roblox Plus | $4,99/mes. Suscriptores: 10 % de descuento (20 % desde el 3.er mes) **pagado por Roblox**: tú cobras lo mismo | Mostrar siempre el precio con descuento real |
| Altas de Plus desde tu juego | 250 Robux/mes los 3 primeros meses pagados (hasta 750 por suscriptor) si se suscribe con `PromptRobloxSubscriptionPurchase` | Botón de Plus con ventaja clara |
| Servidores privados pagados | Hasta 100 Robux/mes por suscriptor Plus que pase ≥ 60 min/mes en tu servidor privado | Activar servidores privados baratos |
| Precios regionales | Nunca menos del 30 % ni más del 100 % del precio base | Un pase de 5 R$ puede costar ~1–2 R$ en algunas regiones |
| Artículos aleatorios pagados | Probabilidades antes de comprar (suman 100 %), botón con texto (no solo un icono), PolicyService por jugador; **las pociones de suerte pagadas también cuentan** | No vendemos suerte |
| Vídeo con recompensa | Requiere ser 13+, cuenta verificada con ID y juego público con ≥ 2.000 visitantes únicos/mes | Se activa en la semana 2–4 tras el lanzamiento |

## 2.4 La ola que vimos en "Recomendadas para ti"

| Juego de la captura | Identificado como | Lectura |
|---|---|---|
| Lanzar comida para animales | *Throw Food For Animals* | Líder de la ola (~236 K jugadores simultáneos, 94 %). Sesión media ~15,9 min |
| Lanzar una semilla | *Throw a Seed* | Seguidor con giro (la distancia suma suerte): ~44 K en 17 días. **No copiar su nombre** |
| Arrojar un arpón a un pez | *Harpoon a Fish* | Variante con robo PvP |
| Barrer la Luna | *Sweep The Moon* | Cooperativo Día 1 → Día 100: **29,7 min de sesión, 97,8 %** |
| Sobrevive a tus ideas | *Survive Your Ideas* | Supervivencia de fiesta por palabras (necesitaría IA en tiempo real: descartado por coste) |
| Palacio de las cartas | *Cards Palace* | Juego de cartas social |

**Cuánto dura una ola.** Con los datos disponibles (con sesgos señalados en el informe de la Fase 1), los grandes éxitos pierden ~90 % de sus jugadores desde el pico y el original se queda la mayoría del tráfico. Estimamos 6–12 semanas de crecimiento rápido y luego una cola larga. Por eso usamos el **lenguaje visual** de la ola (números enormes, "1 en 1.000.000", Día 1 vs Día 100) sobre un **bucle propio** que sobrevive cuando la ola baja.

## 2.5 Comparativa de nichos (resumen de la Fase 1)

| Nicho | Puntuación /35 | Veredicto |
|---|---|---|
| Incremental cooperativo de restauración | 28 | **Base elegida** |
| RNG con multiplicador de suerte | 24 | Ingrediente (suerte por colección), no género |
| Cartas | 24 | Plan B (concepto "Deal the Disaster") |
| Supervivencia de fiesta por palabras | 23 | Descartado: requiere IA en tiempo real |
| "Throw X" con rarezas | 22 | Ingrediente (lanzamiento), no género |
| Robar y defender | 21 | Saturado |
| Terror cooperativo | 21 | Demasiado arte para 2 personas |
| "+1 por segundo" puro | 20 | Agotado como género; vive como sistema interno |
| Cultivo con mutaciones y comercio | 20 | Comercio demasiado complejo y arriesgado para el MVP |

*Puntuaciones = estimación propia de la Fase 1.*
