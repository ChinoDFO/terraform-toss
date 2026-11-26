# Terraform Toss

Juego cooperativo de Roblox: lanza cápsulas de semillas y restaura un planeta compartido.

## Arranque rápido
1. Instala Rokit y ejecuta `rokit install` en esta carpeta.
2. `rojo serve` y, en Roblox Studio, plugin Rojo → Connect.
3. Studio: Avatar > Settings > R15 Only. Game Settings > Security > Enable Studio Access to API Services.
4. Pruebas: con el MCP conectado, pide a Claude ejecutar
   `return require(game:GetService("ServerStorage").Tests.TestRunner).run()`.

Plan completo: `docs/PLAN_MAESTRO.pdf`. Reglas para la IA: `CLAUDE.md`.
