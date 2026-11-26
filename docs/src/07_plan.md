# 10. Plan de producción semana a semana

**Calendario base:** hoy es martes 24 de noviembre de 2026. Lanzamiento plan A: **sábado 26 de diciembre** (vacaciones: la última semana de diciembre concentra una parte grande del gasto del trimestre). Plan B: **sábado 9 de enero de 2027** si algo se retrasa (mejor lanzar bien una semana tarde que lanzar roto).

## Semana 0 — Preparación (mié 25 – dom 29 nov)

| Dev A (Sistemas) | Dev B (Experiencia) |
|---|---|
| Crear grupo, organización de GitHub, repo privado, protección de `main` | Verificación de edad/ID y 2FA |
| Capítulo 6 completo en su PC; DEV publicada con R15 Only | Capítulo 6 completo en su PC; unirse a Team Create |
| Sincronizar el código; corregir avisos de tipos con Claude; 10 pruebas en verde | Colocar `PlanetOrigin`; boceto de plataforma y jardines con partes simples |
| — | Referencias visuales: paleta de las 6 zonas, estilo low-poly |

**Terminado cuando:** los dos lanzan una cápsula en DEV y ven la celda ponerse verde.

## Semana 1 — Bucle central sólido (lun 30 nov – dom 6 dic)

| Dev A | Dev B |
|---|---|
| Probar a fondo DataService (salir/entrar, cerrar servidor, 2 servidores) | Plataforma de lanzamiento definitiva (10 catapultas cosméticas) |
| Sincronizar `CellsRestored` y añadir tabla de clasificación de sesión (leaderstats) | Interfaz: rediseñar HUD (dinero, poder, barra del planeta) para móvil y PC |
| Ajustar medidor con latencia real (2 clientes) | Efectos: explosión verde al caer, partículas por rareza |
| Revisión de seguridad de los 10 RemoteEvents | Sonidos: lanzamiento, caída, rareza (biblioteca de audio de Roblox) |

**Terminado cuando:** un jugador nuevo entiende qué hacer sin explicación en 60 s (prueben con un amigo).

## Semana 2 — Contenido y colección (lun 7 – dom 13 dic)

| Dev A | Dev B |
|---|---|
| Panel de índice (30 criaturas, descubiertas/ocultas) con datos del servidor | 30 criaturas low-poly (o `generate_mesh`), 6 variantes visuales de mutación |
| Jardín 3D: criaturas aparecen en la parcela del jugador (pool de modelos) | Mapa: anillos de colores de las 6 zonas visibles desde la plataforma |
| Aviso de servidor cuando alguien saca Legendario o Arcoíris | Animación de la criatura al llegar al jardín |
| Balance: ejecutar la simulación con datos de las pruebas | FTUE: mano animada, mensajes cortos, flechas |

**Terminado cuando:** una sesión de prueba de 20 minutos llega al Bloom del 25 % con 4–6 jugadores.

## Semana 3 — Monetización y social (lun 14 – dom 20 dic)

| Dev A | Dev B |
|---|---|
| Crear los 5 pases y 3 productos en Creator Hub (en DEV); poner IDs en `Products.luau` | Iconos 512×512 de cada pase y producto |
| Probar compras en Studio (cada handler, sin duplicados) | Rediseño de la tienda: tarjetas, probabilidades visibles, botón "Cerrar" grande |
| Invitar amigos: `SocialService` (aviso de invitación nativo) + recompensa por traer amigos vía *LaunchData* de Share Links | Pantalla "Planeta restaurado" (celebración colectiva) |
| Servidores privados activados (precio bajo) | Pack de Arranque contextual (aparece una vez al llegar a la zona 2–3) |

**Terminado cuando:** checklist anti dark patterns (4.7) completa y en verde.

## Semana 4 — Pulido, pruebas cerradas y lanzamiento (lun 21 – sáb 26 dic)

| Día | Qué |
|---|---|
| Lun 21 | Congelar funciones. Solo errores. Crear PROD. Rellenar el cuestionario de clasificación de contenido completo (objetivo: **Minimal**) |
| Mar 22 | Prueba cerrada con 10–20 amigos en DEV (invitación de *early testers*). Recoger errores |
| Mié 23 | Corregir. Miniaturas (3 variantes), icono, título, descripción (cap. 11) |
| Jue 24 | Publicar PROD para mayores de 16. Pagar la tarifa reembolsable de 1.000 R$ (Audience → Reach) para entrar a la evaluación Kids & Select |
| Vie 25 | Grabar el primer lote de vídeos (cap. 11.4) |
| **Sáb 26** | **Lanzamiento público** + primeros vídeos + primer código promocional |

## Después del lanzamiento

Ritmo: **una actualización cada 2 semanas** (cap. 12), arreglos urgentes en cualquier momento.

# 11. Lanzamiento, algoritmo y marketing a coste cero

## 11.1 Qué pasa al publicar (reglas oficiales)

- Al publicar, si respondes "No" a la pregunta de contenido restringido, el juego se publica con clasificación "Content May Vary" **solo para usuarios mayores de 16 con edad verificada**. Si completas el cuestionario entero, recibes una clasificación y se publica para 16+ (o 18+ según contenido).
- **Para llegar a todas las edades (Roblox Kids y Select):** verificación de cuenta, 2FA, cuestionario completo con clasificación Minimal/Mild/Moderate, superar la evaluación Kids & Select, y **o bien** 2 meses seguidos de Roblox Plus/Premium **o bien** la tarifa reembolsable de **1.000 Robux** por juego. El reembolso llega si el juego mantiene **25 jugadores muy comprometidos durante 60 días** sin moderación.
- Existe una revisión exprés de **50.000 Robux** (48 h). No la necesitan.
- Límite: 5 juegos nuevos publicados por día por cuenta.

**Consecuencia:** el primer mes el público será 16+. El juego tiene que gustar a adolescentes mayores y adultos (y eso es bueno: los adultos de EE. UU. pagan a la tasa de $0,0054).

## 11.2 Plan de 30 días en 3 etapas

### Etapa 1 — Validar (días 1–10, 26 dic – 4 ene)

- Objetivo: que **los que entran se queden**. No hace falta mucho tráfico; hace falta buena retención.
- Fuentes de tráfico: amigos, Share Links en redes propias, primeros vídeos.
- Mirar a diario en Creator Hub → Analytics: sesión media, D1, % de sesiones con amigos, errores en la consola del servidor.
- Corregir lo que rompa la FTUE en < 24 h.

### Etapa 2 — Optimizar la tasa de clics (días 8–20)

**QPTR** (*qualified play-through rate*): de cada 100 personas que ven tu miniatura en Recomendadas, cuántas entran y juegan de verdad. Es la llave para que el algoritmo te muestre a más gente.

- **3 miniaturas** distintas; usen la prueba A/B de miniaturas del Creator Hub si está disponible para el juego. Si no, roten cada 3–4 días y comparen.
- **Formato:** 1920 × 1080 (16:9). **Dejen libre la franja inferior** (~15–20 % de la altura): ahí Roblox pinta el contador de jugadores.
- **Contenido que funciona** (por lo visto en la ola): contraste fuerte, 1 idea por imagen, números grandes y una promesa visual.
  - Variante A: "DÍA 1" (planeta gris) | "DÍA 100" (planeta verde y arcoíris) con "0 % → 100 %".
  - Variante B: cápsula volando hacia una criatura Arcoíris Legendaria con "1 en 333.000".
  - Variante C: 6 avatares lanzando juntos, explosión verde, "¡COMBO!".
- **Icono** 512 × 512: la cápsula con una hoja, fondo de color sólido. Legible a 64 px.
- **Título honesto y único:** "Terraform Toss 🌱 Save the Planet". Evitar "Throw a Seed" o títulos de otros juegos (riesgo de "no único"). Traducción automática activada; título localizado en español: "Terraform Toss 🌱 Salva el Planeta".
- **Descripción:** 3 líneas claras (qué haces, por qué con amigos, qué hay de nuevo) + lista de actualizaciones. Sin palabras clave copiadas de otros juegos.

### Etapa 3 — Vídeos por lotes + Share Links (días 15–30 y siempre)

**Share Links:** Creator Hub → Creations → pestaña **Share Links** → *Create link*. Creen **un enlace por canal** (TikTok, YouTube, Instagram, Discord) para saber cuál trae jugadores que se quedan y gastan (Analytics → Acquisition). Añadan *LaunchData* (máx. 200 bytes) con un código, ej. `{"src":"tiktok","gift":"seed"}`, y en el juego lean `player:GetJoinData().LaunchData` para dar un cosmético de bienvenida. Las altas y reactivaciones que traen cuentan para **Audience Expansion Rewards** de Creator Rewards.

## 11.3 Producción de vídeos por lotes (TikTok y YouTube Shorts)

**Sistema:** una sesión de grabación de 2 horas cada 2 semanas → 10–15 clips verticales de 15–30 s.

| Formato | Gancho (primeros 2 segundos) | Duración |
|---|---|---|
| Día 1 vs Día 100 | Pantalla dividida: planeta gris → verde | 15 s |
| "Saqué un 1 en 333.000" | Reacción real al Arcoíris Legendario | 20 s |
| Combo de 10 jugadores | "¿Qué pasa si 10 personas lanzan a la vez?" | 15 s |
| Llevamos el planeta al 100 % | Cuenta atrás del último 1 % | 30 s |
| Ranking de criaturas | "Las 5 criaturas más raras" | 25 s |
| Errores divertidos | Lanzamientos fallidos, cápsulas que caen cerca | 15 s |

**Reglas:** grabar en Studio/juego con 1080 × 1920 (o recortar), subtítulos grandes, música libre de derechos (biblioteca de la plataforma), llamada a la acción "enlace en el perfil", el Share Link del canal en la biografía. Publicar 1 al día, a la misma hora, en las dos plataformas. No usar música, personajes ni marcas de terceros.

## 11.4 Lo que NO hacer en el lanzamiento

- Comprar seguidores, bots o "jugadores": arruina las métricas y viola normas.
- Prometer recompensas falsas en vídeos ("¡Robux gratis!").
- Copiar miniaturas o títulos de otros juegos.
- Cambiar todo a la vez: si cambian miniatura y título el mismo día, no sabrán qué funcionó.

# 12. LiveOps: calendario quincenal

Cada actualización tiene un **tema**, **contenido nuevo pequeño**, **un código promocional** y **un vídeo** que lo anuncia. Publicar los viernes por la tarde (hora de México): el fin de semana es cuando más se juega.

| Fecha (viernes) | Actualización | Contenido | Para qué métrica |
|---|---|---|---|
| 8 ene | **1.1 Índice y clasificación** | Recompensas por completar cada zona del índice; tabla de "celdas restauradas" | D7, sesión |
| 22 ene | **1.2 Ascenso de Jardinero** | Prestigio personal: reinicia dinero y poder por +25 % permanente | Retención larga |
| 5 feb | **1.3 Planeta Helado** (2.º bioma visual) | El planeta 2+ cambia de aspecto; 5 criaturas de evento | Volver a entrar |
| 19 feb | **1.4 Mascota que acompaña** | Tu mejor criatura te sigue (cosmético) | Presumir, social |
| 5 mar | **1.5 Suscripción Jardinero** | Suscripción mensual: diario ×2 + skin del mes | Ingreso recurrente |
| 19 mar | **1.6 Evento de primavera** | Bloom especial: celdas de flores, criaturas temporales (con fecha de fin real y visible) | Pico de jugadores |

**Cada dos semanas, sin falta:**

1. Lunes: decidir el tema con los datos de la quincena anterior (qué zona abandonan, qué compran).
2. Martes–jueves: construir (una o dos tareas por persona).
3. Jueves: prueba en DEV + checklist 14.2.
4. Viernes: publicar, código nuevo en la descripción y en el vídeo.
5. Fin de semana: leer comentarios y errores.

# 13. Métricas y decisiones

## 13.1 Objetivos a 14 días (umbrales para seguir o cambiar)

| Métrica (Creator Hub → Analytics) | Objetivo | Si no se cumple |
|---|---|---|
| QPTR en Recomendadas | ≥ referencia de juegos similares que muestra el panel | Probar 3 miniaturas y 2 títulos |
| Sesión media | ≥ 19 min | Adelantar el primer hito; ajustar `cellsPerThrow` para que el Bloom llegue antes |
| Retención D1 / D7 | ≥ 20 % / ≥ 6 % | Revisar la FTUE; reforzar recompensa diaria e ingresos offline |
| Sesiones con amigos | ≥ 25 % | Más recompensa por combo; invitaciones con recompensa |
| Conversión de pago | ≥ 1,5 % (ARPPU ≥ 100 R$) | Ajustar Pack de Arranque; probar precio del Turbo |
| Primera compra → segunda en 7 días | ≥ 20 % | Revisar escalón 2 de precios |
| Active Spenders / DAU | Subiendo semana a semana | Más razones para ser "el primer juego del día" |
| Errores de servidor | 0 errores repetidos | Arreglo inmediato |

## 13.2 Decisión a 30 días

| Jugadores simultáneos medios | Decisión |
|---|---|
| ≥ 1.000 | **Invertir**: acelerar LiveOps, considerar crédito de anuncios de Roblox con lo ganado |
| 300 – 1.000 | **Seguir**: mejorar retención y QPTR, mantener el ritmo quincenal |
| 100 – 300 | **Iterar fuerte**: rehacer FTUE y miniaturas; revisar el bucle |
| < 100 | **Pivotar** al plan B reutilizando sistemas (datos, compras, tienda, seguridad): "Wishing Star RNG" (suerte cooperativa, 3–4 semanas) o "Deal the Disaster" (cartas de desastre, 6–8 semanas) |

## 13.3 Modelo de ingresos (estimación propia, no promesa)

| Escenario | Jugadores simultáneos medios | DAU estimado | USD/mes aprox. |
|---|---|---|---|
| Conservador | 300 | ~12 K | ~$560 |
| Base | 1.000 | ~41 K | ~$4.700 |
| Optimista | 5.000 | ~205 K | ~$47.000 |

*Más Creator Rewards, bonos de Plus y la parte cobrada a la tasa 18+. El mínimo para cobrar DevEx es 30.000 Robux ganados.*

# 14. Checklists

## 14.1 Antes de publicar por primera vez

- [ ] R15 Only activado; ningún sistema cambia a R6.
- [ ] 10 pruebas automáticas en verde en PROD.
- [ ] Salir/entrar conserva el progreso; cerrar servidor no pierde datos.
- [ ] Todos los IDs de `Products.luau` rellenados y probados.
- [ ] Probabilidades visibles y botón "Ver probabilidades" con texto.
- [ ] Tienda aleatoria oculta si `PaidRandomRestricted` (probar forzando el atributo en Studio).
- [ ] Checklist anti dark patterns (4.7) completa.
- [ ] Auditoría de scripts (8.3) sin hallazgos.
- [ ] Cuestionario de contenido completo (objetivo Minimal).
- [ ] Miniaturas con franja inferior libre, icono, título único, descripción.
- [ ] Share Links creados por canal.
- [ ] Prueba en un móvil real (botones alcanzables con el pulgar, 30+ FPS).

## 14.2 Antes de cada actualización

- [ ] *Pull requests* revisados por el otro cofundador.
- [ ] Pruebas automáticas en verde.
- [ ] Prueba de juego de 10 minutos en DEV con 2 clientes.
- [ ] Ningún cambio en `STORE_NAME`; campos nuevos con valor por defecto en `defaultData`.
- [ ] Auditoría rápida de scripts nuevos fuera de Rojo.
- [ ] Notas de la actualización en la descripción + código promocional + vídeo.
- [ ] Publicar en PROD con *Publish to Roblox As* desde DEV.
