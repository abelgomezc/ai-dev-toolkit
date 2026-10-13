# Eval Case: Error Recovery - Resume from Handoff

## Plugin
context-toolkit

## Escenario
Un agente Claude Code fue interrumpido (timeout) durante la implementación de un feature de autenticación JWT. El session-handoff skill debe permitir que una nueva instancia reanude exactamente donde se quedó, sin pérdida de contexto.

## Input (Prompt)
```
# Situación: Claude Code timeout durante implementación de JWT auth

# Estado cuando se interrumpió:
- AuthController implementado ✅
- AuthService implementado ✅  
- JwtTokenProvider en progreso (50% completado, línea 45/92)
- Tests: AuthControllerTest ✅ (3 tests), AuthServiceTest parcial (2/4 tests)
- Issue: Token refresh endpoint needs implementation
- Todo list pendiente: remaining todos (3 items)

# Nueva sesión ejecuta:
/handoff --status=blocked --objective="Implementar JWT auth" --output=HANDOFF-RESUME.md
```

## Métricas de Evaluación

| Métrica | CON Plugin (session-handoff) | SIN Plugin (sin handoff) |
|---------|------------------------------|--------------------------|
| Estado preservado | ✅ todos los archivos, completion %, línea interrupción | ❌ nada preservado |
| Tareas pendientes exactas | ✅ 3 items con prioridad | ⚠️ "continuar implementación" |
| Issue capturado | ✅ "Token refresh endpoint needs implementation" | ❌ |
| Reanudación precisa | ✅ desde línea 45/92 JwtTokenProvider | ⚠️ desde principio del archivo |
| Time loss on resume | < 1 minuto (read handoff) | 5-10 minutos (reverse engineer) |
| Tokens gastados en resume | 800 tokens (read handoff) | 4,000+ tokens (re-explorar) |
| Compleción del feature | ✅ (resume + completar) | ⚠️ posible error/rework |

## Expected Outcome
- **CON Plugin**: Handoff con estado exacto (JwtTokenProvider 50% completado en línea 45), 3 tareas pendientes con prioridad (high: implement token refresh, medium: complete AuthServiceTest, low: add integration tests), issue de token refresh documentado, instrucciones de reanudación con comandos específicos, reanudación en <1 minuto con <1,000 tokens.
- **SIN Plugin**: Sin handoff, nueva sesión debe explorar filesystem, leer archivos, inferir estado, perder 5-10 minutos y 4,000+ tokens, posible implementar algo diferente o rework.

## Difficulty: Hard
## Est. Tokens: 3,000 (CON) vs 4,800 (SIN) para reanudación

## Skill References
- session-handoff R1-R8 (complete state capture, issues, blockers, next actions, resume instructions)
- claude-md-writer R6 (timestamp for staleness detection)