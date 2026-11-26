# 3. Diseño del juego (GDD)

## 3.1 Fantasía y pitch

**Fantasía:** "Soy parte de un equipo de jardineros espaciales que devuelve la vida a planetas muertos. Cuanto más lejos lanzo, más raras son las criaturas que despierto."

**Pitch de 10 segundos:** *Mantén pulsado, suelta en la zona verde y mira cómo tu cápsula de semillas vuela, cae y pinta de verde el planeta. Todo el servidor llena la misma barra. Al 25 % explota un Bloom y todos ganan el doble.*

**Lo que lo hace único frente a la ola "Throw X":**

| Ellos | Terraform Toss |
|---|---|
| Progreso 100 % individual | Barra de planeta **compartida** + eventos de servidor + recompensa colectiva al 100 % |
| Lanzar es solo "ir más lejos" | Cada lanzamiento **cambia el mundo** visible para todos |
| Suerte de pago (pociones) | Suerte **gratuita**: sube con tu colección y con los eventos |
| Sesión ~16 min | Hitos de servidor diseñados para el minuto 17–20 |

## 3.2 Bucle central (core loop)

| Paso | Qué hace el jugador | Qué decide el servidor | Recompensa |
|---|---|---|---|
| 1. Entrenar | Nada (pasivo +N/s) o toca ENTRENAR para acelerar | Suma Poder cada segundo | Número que sube siempre |
| 2. Cargar | Mantiene LANZAR (o barra espaciadora) | Anota la hora de inicio | Tensión del medidor |
| 3. Soltar | Suelta en la zona verde | Calcula el medidor con su reloj: ×1 / ×1,5 / ×2 | Habilidad |
| 4. Volar | Ve su cápsula (y la de los demás) volar | Distancia = Poder × medidor × cápsula × combo | Espectáculo |
| 5. Caer | Ve casillas grises volverse verdes | Zona según distancia; celdas según rareza | Impacto en el mundo |
| 6. Criatura | Recibe una criatura | Rareza (con suerte) + mutación | Coleccionar, presumir |
| 7. Jardín | La criatura genera $/s | Ingreso por zona × rareza × mutación | Dinero |
| 8. Mejorar | Compra +Entreno y +Cápsula | Valida y cobra | Lanzar más lejos → zona nueva |

**Bucles de mayor duración:**

- **Minutos:** zona nueva → criaturas nuevas → +2 % de suerte cada una.
- **~20 minutos:** hito de servidor (Bloom al 25/50/75 %): ×2 dinero y +0,5 suerte para todos durante 10 minutos.
- **~1 hora (6 jugadores):** planeta al 100 % → recompensa para todos (5 min de ingresos + 1 Huevo Estelar gratis) → Planeta 2 (+10 % de dinero en ese servidor).
- **Días:** racha diaria (día 3: Turbo gratis; día 7: Huevo Estelar gratis), ingresos offline, completar el índice de 30 criaturas.

## 3.3 Sistemas uno por uno

### Entrenamiento (el "+1 por segundo")

- Poder sube **(1 + nivel de entrenamiento) por segundo**, siempre, sin hacer nada.
- Tocar ENTRENAR suma medio segundo extra por toque (máximo 8 toques por segundo; el servidor lo limita).
- **Turbo ×2**: se desbloquea **gratis y para siempre** al llegar a una racha de 3 días, o al instante con el pase *Turbo de Arranque*.
- Coste de mejora: `30 × 1,85^nivel` dinero.

### Lanzamiento y medidor

- El medidor va de 0 a 1 y vuelve a 0 cada 1,6 s. Zona verde (≥ 0,9) = ×2; amarilla (≥ 0,7) = ×1,5; resto = ×1. Mantener más de 8 s = ×1.
- **El cliente nunca envía el valor del medidor**: el servidor lo calcula con su propio reloj entre "empecé" y "solté". Es imposible hacer trampa enviando "perfecto".
- Enfriamiento entre lanzamientos: 1,2 s.
- **Lanzamiento combinado:** si otro jugador a menos de 30 studs soltó hace menos de 1 s, tu lanzamiento recibe +25 % de distancia y +0,1 de suerte. Incentivo directo a jugar juntos y coordinarse ("¡a la de tres!").
- Cápsula: multiplica la distancia por `1,2^nivel`; coste `300 × 4^nivel`.

### Zonas (6)

| # | Zona | Distancia mínima | Ingreso base/s | Ritmo esperado* |
|---|---|---|---|---|
| 1 | Páramo Gris | 0 | 1 | Minuto 0 |
| 2 | Dunas de Óxido | 200 | 6 | ~1 min |
| 3 | Cráter Salino | 3.000 | 36 | ~3 min |
| 4 | Glaciar Dormido | 50.000 | 220 | ~15 min |
| 5 | Bosque Fósil | 900.000 | 1.300 | ~1,5 h acumuladas |
| 6 | Núcleo Volcánico | 20.000.000 | 8.000 | ~12 h acumuladas |

*\*Simulación propia con juego activo, sin Turbo ni pases. Ajustar con datos reales (todo vive en `Config/Zones.luau` y `Util/Formulas.luau`).*

### Rarezas (5) y suerte

| Rareza | Probabilidad base | Multiplicador de ingreso | Celdas que restaura |
|---|---|---|---|
| Común | 62 % | ×1 | 1 |
| Poco común | 25 % | ×2 | 2 |
| Raro | 10 % | ×5 | 4 |
| Épico | 2,7 % | ×15 | 8 |
| Legendario | 0,3 % | ×60 | 20 |

**Suerte** = 1 + 0,02 × criaturas distintas descubiertas + 0,5 si hay Bloom + 0,25 si vio un vídeo con recompensa (10 min). Máximo 5. La suerte multiplica el peso de cada rareza por `suerte^exponente` (Poco común 0,35 · Raro 0,6 · Épico 0,85 · Legendario 1) y Común absorbe el resto para que **siempre sume 100 %**. Ejemplo verificado: con suerte 2, Legendario pasa de 0,3 % a 0,6 % y Común baja a 47,5 %.

> **Por qué la suerte no se vende.** Desde la aclaración de Roblox de mayo de 2026, los "modificadores de probabilidad" pagados (pociones de suerte, rate-up, pity de pago) son artículos aleatorios pagados, con todas sus obligaciones. Vender suerte complicaría el cumplimiento y, en lo cooperativo, crearía presión de pago. La suerte se gana jugando.

### Mutaciones (6)

Se tiran aparte de la rareza en cada criatura: Sin mutación 90 % · Neón 4 % (×1,5) · Dorado 3 % (×2) · Gigante 1,5 % (×2,5) · Cristal 1 % (×3) · Bioluminiscente 0,4 % (×4) · Arcoíris 0,1 % (×5). El Arcoíris Legendario (0,0003 % por lanzamiento con suerte 1) es el "1 en 333.000" de la miniatura.

### Criaturas (30)

| Zona | Común | Poco común | Raro | Épico | Legendario |
|---|---|---|---|---|---|
| 1 Páramo Gris | Brotín | Musgolín | Cactopo | Liquenzorro | Rocalirio |
| 2 Dunas de Óxido | Arenuga | Escarabrote | Dunalce | Oxidrago | Faraonix |
| 3 Cráter Salino | Salmorito | Cristortuga | Geodín | Salamandrina | Halitón Rey |
| 4 Glaciar Dormido | Escarchín | Pingüiflor | Morsaurio | Auroralce | Gélidra |
| 5 Bosque Fósil | Ambarín | Helechoso | Trilobrote | Raptor Raíz | Secuoyón |
| 6 Núcleo Volcánico | Brasita | Magmapo | Obsidiano | Fénix Verde | Corazón de Gaia |

**Arte:** modelos low-poly de 6–10 partes cada uno, una paleta por zona. Para la versión final, generen variantes con la herramienta `generate_mesh` del MCP o en Blender, y usen el mismo modelo con color/material distinto para cada mutación (Neón = material Neon, Dorado = color dorado + brillo, Gigante = escala ×1,6, etc.). Así 30 criaturas × 7 mutaciones salen de solo 30 modelos.

### Jardín

- 8 huecos (+4 con el pase *Huecos Extra*, +1 con Roblox Plus).
- Si está lleno y la criatura nueva genera más que la peor, la reemplaza y la peor se vende por 30 s de su ingreso. Si no, se vende la nueva. **Nunca se pierde valor.**
- Ingresos offline: 50 % del ingreso por segundo, hasta 8 horas, cobrados al volver con un aviso "Mientras no estabas tu jardín generó $X".

### Planeta compartido

- Cuadrícula lógica de 96 × 96 = 9.216 celdas en 6 franjas (una por zona). Se dibuja con 32 × 32 partes (cada parte = 3 × 3 celdas, su color pasa de gris al color de la zona según cuántas celdas vivas tiene).
- Cada lanzamiento revive celdas aleatorias en la franja de su zona; si la franja está llena, en la franja libre más cercana.
- **Ritmo calculado:** con 6 jugadores (un lanzamiento cada ~5 s) el 25 % llega a los ~16,5 min y el 100 % a los ~66 min. Con 10 jugadores: 25 % a los ~10 min. *Ajusten con `cellsPerThrow` en `Config/Rarities.luau`.*
- Hitos 25 / 50 / 75 % = **Bloom Event** (10 min, ×2 dinero y +0,5 suerte para todos). 100 % = **Planeta restaurado**: recompensa a todos los presentes y nuevo planeta (+10 % de dinero por planeta en ese servidor).
- El progreso del planeta es **por servidor** (no se guarda). Lo que se guarda es tu contribución personal ("celdas restauradas"), ideal para una tabla de clasificación en la semana 3.

### Recompensa diaria

Ciclo de 7 días. Día N de racha = 60 s de ingreso × N (mínimo $50). Día 3 = Turbo ×2 gratis para siempre. Día 7 = 1 Huevo Estelar gratis. Perder un día reinicia la racha (sin castigo extra, sin mensajes culpabilizadores).

## 3.4 Los primeros 60 segundos (FTUE)

Objetivo: que en 60 segundos el jugador haya lanzado, visto el mundo cambiar, recibido una criatura, comprado su primera mejora y entendido que juega **con** los demás. Sin ventanas de compra en los primeros 3 minutos.

| Segundo | Qué ve | PC | Móvil | Qué se aprende |
|---|---|---|---|---|
| 0–5 | Aparece en la plataforma frente al planeta gris. Arriba, la barra "Planeta 1 · 3,2 %". Cápsulas de otros jugadores cruzando el cielo. Una mano animada señala LANZAR | — | — | "Aquí se lanza y todos llenan la barra" |
| 5–12 | Mantiene LANZAR: aparece el medidor con la zona verde marcada | Clic sostenido o Espacio | Botón grande abajo a la derecha | Medidor |
| 12–18 | **Primer lanzamiento garantizado:** criatura Poco común, explosión verde de celdas, aviso "+2 celdas" | — | — | "Lo que hago cambia el mundo" |
| 18–28 | La criatura aparece en su jardín y suben los $/s. Flecha a "+Entreno" | Clic | Toque | Dinero → mejora |
| 28–40 | Compra la primera mejora (cuesta 30 $, se alcanza en ~20 s) | Clic | Toque | Progreso |
| 40–52 | Segundo y tercer lanzamiento; mensaje "¡Suelta en la zona VERDE para ×2!" | — | — | Habilidad |
| 52–60 | Aviso social: "Bloom Event al 25 %: faltan 21,8 %. Lanza junto a alguien: +25 % de distancia" | — | — | Cooperación y meta compartida |

**Reglas de la FTUE:**

- Interfaz mínima al principio: dinero, poder, barra del planeta y LANZAR. El resto aparece cuando se necesita (tienda tras la primera zona nueva, diario si está disponible, huevos si tiene alguno).
- Textos de 6 palabras máximo, con iconos. Todo traducible (servicio de traducción automática de Roblox).
- Botones táctiles de al menos 0,08 × 0,16 de la pantalla; nada importante en las esquinas superiores (ahí están los menús de Roblox en móvil).
- Probar la FTUE con alguien que nunca haya visto el juego, sin explicarle nada. Si pregunta "¿y ahora qué?", hay un fallo.

## 3.5 Cómo se llega a 19+ minutos

| Minuto | Momento | Gancho que retiene |
|---|---|---|
| 0–1 | FTUE | Primer lanzamiento garantizado, primera mejora |
| 1–3 | Zona 2 | Criaturas nuevas = +suerte |
| 3–5 | Zona 3 | Saltos de ingreso ×6; aparece la tienda (sin abrirse sola) |
| 5–10 | Mejoras y combos | Lanzamientos combinados con desconocidos |
| 10–15 | Índice | "Te faltan 4 criaturas de la zona 3" |
| 15–20 | **Bloom al 25 %** (con ~6 jugadores) + zona 4 | Evento de servidor: nadie quiere irse durante el ×2 |
| 20–30 | Bloom activo | 10 minutos de ×2 dinero → compras de mejoras grandes |
| 30+ | Hacia el 50 % | Siguiente Bloom; racha y huevos |

## 3.6 Mapa (lo construye Dev B)

- **Plataforma de lanzamiento** central, amplia (para que 10 jugadores lancen juntos y se activen combos), con 10 catapultas cosméticas.
- **Planeta**: la cuadrícula de celdas se genera sola por código delante de la plataforma. Coloquen una parte llamada `PlanetOrigin` en Workspace donde debe empezar (si no existe, se usa (0, 0, 120)).
- **Jardines**: 10 parcelas alrededor de la plataforma, una por jugador. (MVP: el jardín puede ser solo la lista de la interfaz; las parcelas 3D con criaturas animadas llegan en la semana 3.)
- **Decorado**: bordes del planeta, cielo estrellado, un "anillo" de zonas visible de lejos con colores distintos para que se vea a dónde se quiere llegar.
- Presupuesto de rendimiento para móviles: < 5.000 partes en total, sombras desactivadas en lo decorativo, streaming activado.
