# 4. Monetización ética

## 4.1 Principios

1. **Primero lo permanente y lo no aleatorio.** Pases que el jugador entiende y no lamenta.
2. **Pagar acelera lo tuyo, nunca bloquea lo de todos.** El planeta compartido avanza igual con o sin pagadores.
3. **Todo lo que se compra con Robux también se puede conseguir jugando** (salvo cosméticos y comodidades).
4. **Transparencia total en lo aleatorio:** probabilidades visibles antes de comprar, mínimo garantizado, garantía de Legendario divulgada.
5. **Nada de presión artificial:** ni temporizadores falsos, ni "¡solo hoy!", ni botones de cerrar escondidos, ni avisos de compra que se abren solos.
6. **Protección a menores:** entre los 13 y los 17 años los padres ya no pueden fijar límites de gasto en Roblox, así que la responsabilidad es del diseño. Confirmación en dos pasos para compras ≥ 400 R$ y botón de compra activo solo 1 s después de abrir la tienda (evita toques accidentales).

## 4.2 Escalera de precios (precio BASE en Robux)

*Estos son precios base que se configuran en Creator Hub. El juego nunca los escribe en el código: los lee con `GetProductInfoAsync`, así cada jugador ve su precio regional y su descuento de Plus.*

| Producto | Tipo | Base sugerida | Qué da | Cómo se consigue gratis |
|---|---|---|---|---|
| **Turbo de Arranque** | Pase | **5 R$** | ×2 entrenamiento permanente | Racha de 3 días |
| Doble Dinero | Pase | 149 R$ | ×2 a todo el dinero del jardín | Eventos Bloom (temporal) |
| Auto-Lanzamiento | Pase | 199 R$ | Lanza solo cada 4 s con medidor ×1,5 | — (comodidad) |
| +4 Huecos de Jardín | Pase | 99 R$ | Jardín de 8 a 12 | +1 con Roblox Plus |
| Catapulta Dorada | Pase | 79 R$ | Cosmético puro, sin ventaja | — |
| Pack de Arranque | Producto (1 vez) | 49 R$ | **Contenido fijo**: +3 niveles de entreno, 1 Huevo Estelar gratuito, skin | — |
| Huevo Estelar | Producto | 25 R$ | Criatura Rara o mejor de tu mejor zona (aleatorio, ver 4.4) | Día 7 de racha, planeta al 100 %, Pack de Arranque |
| ×2 Dinero 30 min | Producto | 19 R$ | Consumible, se suma al pase | Eventos Bloom |
| Suscripción "Jardinero" (mes 2) | Suscripción de desarrollador | Tramo más bajo disponible (en moneda local) | Recompensa diaria ×2 y skin mensual | — |
| Servidor privado | Servidor privado pagado | 50 R$/mes | Jugar con amigos; cuenta para el bono de Plus | — |

**Cómo leer la escalera:**

- **Escalón 1 (5–25 R$):** romper la barrera del primer pago. Turbo de Arranque, Huevo Estelar.
- **Escalón 2 (49–149 R$):** el Pack de Arranque aparece **una sola vez**, en contexto (al desbloquear la zona 2 o 3), con un botón de cerrar claro y sin temporizador. Doble Dinero es el pase "estrella".
- **Escalón 3 (199+ R$):** comodidad y estatus para quien ya disfruta el juego.
- **Recurrente:** suscripción y servidores privados, a partir del mes 2, cuando haya datos.

**Ingresos por venta (estimación):** Roblox se queda con ~30 % de cada venta en tu juego. Un pase de 149 R$ te deja ~104 R$ ≈ **$0,40** a la tasa estándar o **$0,56** si lo compra un adulto verificado de EE. UU. con tasa 18+.

## 4.3 Cómo se configura cada producto (paso a paso)

1. Creator Hub → **Creations** → elige el juego → **Monetization** → **Passes** → *Create a Pass*. Nombre, descripción honesta, icono 512 × 512, precio base. Activa **Regional Pricing / Managed Pricing**.
2. Monetization → **Developer Products** → *Create*. Igual. Para los productos de desarrollador, Regional Pricing exige que el precio se muestre por script (ya lo hace `PriceService.luau`).
3. Copia cada **ID** en `src/shared/Config/Products.luau` (campo `id`). Con `id = 0` el producto se muestra como "Próximamente".
4. Haz commit, `rojo serve`, prueba la compra en Studio (las compras en Studio son de prueba y no cobran).

## 4.4 Huevo Estelar: el único artículo aleatorio pagado

**Lo que el código ya hace** (`Odds.luau`, `PurchaseService.luau`, `ShopController.luau`):

| Requisito de Roblox | Cómo se cumple |
|---|---|
| Probabilidades numéricas antes de comprar | En la tarjeta: "Raro 75,00 % · Épico 22,00 % · Legendario 3,00 %" + botón con texto **"Ver probabilidades"** (no solo un icono) |
| Suman exactamente 100 % | Prueba automática en `TestRunner` + aviso de redondeo |
| Ningún resultado vacío | Mínimo garantizado: Raro de tu mejor zona |
| Modificadores de probabilidad divulgados y actualizados | La garantía ("cada 10 huevos pagados sin Legendario, el siguiente es Legendario") se muestra con tu contador; al llegar al 10.º la tabla cambia a "Legendario 100 %" |
| Mutación (segunda tirada) | Su tabla completa se muestra en el mismo panel |
| `ArePaidRandomItemsRestricted` por jugador | El servidor consulta PolicyService; si es *true* (o si la consulta falla) la tarjeta se oculta **y** el servidor rechaza la compra |
| Alternativa gratuita | Huevos gratis: día 7 de racha, planeta al 100 %, Pack de Arranque |
| Por si llega un recibo de alguien restringido | Se entrega un resultado **fijo** (Raro) en lugar de uno aleatorio |
| Comercio | No hay comercio en el MVP. Si algún día se añade: `IsPaidItemTradingAllowed` + `GetUsersPriceLevelsAsync` (sin cachear entre sesiones) |

## 4.5 Vídeo con recompensa (la alternativa gratuita a la suerte)

Cuando el juego cumpla los requisitos (ser 13+, cuenta verificada con ID, juego público con ≥ 2.000 visitantes únicos al mes), activen *Rewarded Video* en Game Settings y añadan un botón "Ver vídeo: +25 % de suerte durante 10 min". El patrón oficial (servidor):

```luau
-- Servidor. REWARD_PRODUCT_ID = un Developer Product creado solo para esta recompensa.
local AdService = game:GetService("AdService")
local ok, result = pcall(function()
	local reward = AdService:CreateAdRewardFromDevProductId(REWARD_PRODUCT_ID)
	return AdService:ShowRewardedVideoAdAsync(player, reward)
end)
-- La recompensa se entrega en ProcessReceipt (handler del producto de recompensa):
-- player:SetAttribute("AdLuckUntil", os.time() + 600)
```

`Formulas.luck` ya lee `AdLuckUntil`. Es suerte **gratuita** (no cuesta Robux), así que no es un artículo aleatorio pagado.

## 4.6 Roblox Plus

- Ventaja: **+1 hueco de jardín** mientras esté suscrito (visible, útil, no abusiva).
- El botón "Roblox Plus: +1 hueco de jardín" está en la tienda y **solo** abre el aviso si el jugador lo pulsa (con 5 s de enfriamiento).
- El servidor verifica con `Player.HasRobloxSubscription` y su señal de cambio antes de dar la ventaja (`PlusService.luau`). Nunca confía en el cliente.
- Ganancia: 250 R$/mes durante los 3 primeros meses pagados de cada suscriptor captado desde el juego (hasta 750 R$), con 60 días de retención.

## 4.7 Checklist anti dark patterns (revisar en cada actualización)

- [ ] Ningún aviso de compra se abre solo.
- [ ] Ningún temporizador de oferta es falso (si hay oferta de evento, la fecha de fin es real y no se renueva en bucle).
- [ ] El botón de cerrar es grande, visible y dice "Cerrar".
- [ ] Ningún botón de compra se parece a un botón de "continuar" o de "aceptar recompensa".
- [ ] Los precios vienen de `PriceService` (nunca escritos a mano).
- [ ] Las compras ≥ 400 R$ piden confirmación propia.
- [ ] Nada pagado bloquea el planeta compartido ni los eventos.
- [ ] Ningún texto culpabiliza o presiona ("todos tus amigos lo tienen", "no seas el único sin...").
- [ ] Las probabilidades suman 100 % (prueba automática en verde).
- [ ] La tienda aleatoria está oculta para jugadores restringidos.

# 5. Tu idea del pase "casi obligatorio" de 3–4 Robux

Tu propuesta: un ×2 de velocidad permanente a 3–4 Robux, tan barato que casi todos lo compren para "estar en sintonía" con el juego y con los demás.

## 5.1 Lo que tiene de bueno (y por qué lo incluimos)

La parte del **precio bajo** es una técnica real y legítima: romper la barrera del primer pago. Quien paga una vez, aunque sea poco, tiene mucha más probabilidad de volver a pagar, porque ya tiene Robux, ya conoce el aviso de compra y ya decidió que el juego vale la pena. Para un niño, pedir "algo de 5 Robux" a sus padres es una conversación muy fácil. Por eso el **Turbo de Arranque** existe en el plan, a **5 R$**.

## 5.2 Lo que conviene cambiar: el "obligatorio"

Aquí va mi opinión honesta: diseñar el juego para que **no** tenerlo te deje "fuera de sintonía" con los demás jugaría en tu contra, por cuatro razones concretas:

1. **Choca con su propia regla.** El prompt del proyecto prohíbe "muros pay-to-win abusivos". Un pase que el diseño vuelve imprescindible para jugar al ritmo del grupo es justamente eso, aunque cueste poco.
2. **El ~98 % no paga.** En Roblox, la conversión típica es del 1–3 %. Si el 98 % siente que juega "en desventaja" en un juego cooperativo, se va. Y en 2026 el algoritmo premia sobre todo la **retención**: perder a los que no pagan cuesta más que lo que ganan los 5 R$.
3. **En lo cooperativo, la desigualdad se nota más.** Si unos entrenan al doble por haber pagado y eso se nota en la barra compartida, el que no paga siente que "estorba". Eso rompe el ambiente de equipo que es el corazón del juego.
4. **El dinero directo es casi nada.** 5 R$ te dejan ~3 R$ ≈ $0,01 por venta. Con precios regionales (mínimo 30 % del base) puede quedar en 1–2 R$. Su valor real está en la **conversión** al primer pago, no en la venta.

## 5.3 La versión recomendada (ya implementada)

| Aspecto | Tu idea | Versión recomendada |
|---|---|---|
| Precio | 3–4 R$ | **5 R$** (divide limpio: ~3 R$ netos; ajustable) |
| Beneficio | ×2 velocidad | **×2 entrenamiento** (progreso personal, no movimiento ni planeta compartido) |
| ¿Se puede conseguir gratis? | No | **Sí: racha de 3 días** (y entonces el pase "te ahorra 2 días") |
| Mensaje | "Lo necesitas para estar al nivel" | "**Empieza más rápido**" |
| Presión social | Implícita | Ninguna: no se muestra quién lo tiene, sin etiquetas "SIN TURBO" |
| Cuándo se ofrece | — | En la tienda siempre; destacado una sola vez tras el primer minuto de juego, con botón de cerrar claro |

**Resultado:** conservas lo que funciona (precio irresistible = primer pago) y además el desbloqueo gratuito al día 3 **mejora la retención D3**, que es lo que más le gusta al algoritmo. Quien paga lo hace porque quiere ir más rápido hoy, no porque se sienta excluido.

> **Prueba sugerida tras el lanzamiento:** compara 5 R$ contra 9 R$ durante dos semanas cada uno (o usa la optimización de precios de Managed Pricing si está disponible para el juego). Mide: % de jugadores que hacen su **primera** compra y si esos jugadores compran algo más en los siguientes 7 días. Ese segundo número es el que de verdad importa.
