# Eval Case: Handoff - Session Continuity

## Plugin
context-toolkit

## Escenario
Un desarrollador está implementando una feature de OAuth2 login y debe hacer handoff para que otro ingeniero continúe. El handoff debe capturar contexto completo.

## Input (Prompt)
```
/handoff --objective="Implementar OAuth2 login con Google + GitHub" --scope=changed --verbose

Contexto de sesión:
- Estado actual: implementado Google OAuth2 (Spring Security 6), pendiente GitHub
- Archivos modificados: 7 (OAuth2Config, SecurityConfig, UserController, templates/*)
- Tests: 3 tests pasando, 1 test fallando (GitHub callback URL)
- Issue: GitHub OAuth app redirect URI mismatch (app config vs env var)
- Next steps: fix GitHub properties, add tests, document in CLAUDE.md
```

## Métricas de Evaluación

| Métrica | CON Plugin | SIN Plugin (manual) |
|---------|-----------|---------------------|
| Objective captured | ✅ explícito en header | ⚠️ asumido |
| Trabajo completado | ✅ 7 archivos con diff summary | ⚠️ solo lista de archivos |
| Issues documentados | ✅ GitHub URI mismatch + fix | ⚠️ solo "test failing" |
| Next actions específicas | ✅ 3 actions con commands | ⚠️ "fix the issue" |
| Scope (changed only) | ✅ solo archivos modificados | ❌ |
| Size (< 4KB) | ✅ 2.8KB | N/A |
| Reanudación posible | ✅ con comandos reproducibles | ⚠️ depende del dev |

## Expected Outcome
- **CON Plugin**: Handoff con objective claro, 7 archivos listados con tipo de cambio, issue de GitHub URI mismatch documentado con causa raíz, 3 next actions concretas (fix properties, add 2 tests, update CLAUDE.md), reanudación posible con comandos específicos.
- **SIN Plugin**: Documentación libre de texto, issues genéricos, next actions vagas, sin commands reproducibles.

## Difficulty: Medium
## Est. Tokens: 8,000 (CON) vs 6,000 (SIN)

## Skill References
- session-handoff R1-R8 (handoff completeness, issues, next actions, resume)