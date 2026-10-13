# Eval Case: Token Savings - Context Optimization

## Plugin
context-toolkit

## Escenario
Trabajar en un monorepo grande (100K+ líneas) con un feature que toca 4 archivos. El context-toolkit debe minimizar tokens gastados en context discovery vs un enfoque sin optimización.

## Input (Prompt)
```
# Medir ahorro de tokens usando context-toolkit en monorepo grande
# Feature: Añadir export CSV a report endpoint

Proyecto: enterprise-saas/
- 15,000+ archivos TypeScript
- 200+ endpoints API
- Stack: NestJS + TypeORM + PostgreSQL
- Feature toca: src/reports/reports.controller.ts + reports.service.ts + reports.module.ts + dto/export.dto.ts

Sin context-toolkit:
- El agente lee AGENTS.md (5KB), navega directorios, lee imports, estudia patrones
- Tiempo estimado: 50,000 tokens para context discovery

Con context-toolkit:
- /map genera resumen de 3KB
- claude-md-writer documenta patterns relevantes
- session-handoff preserva contexto entre iteraciones
```

## Métricas de Evaluación

| Métrica | CON Plugin (context-toolkit) | SIN Plugin (sin optimización) |
|---------|------------------------------|------------------------------|
| Context discovery tokens | 3,000 (map + claude.md) | 50,000 (navegación manual) |
| Time to context-ready | 2 minutos (map output) | 15 minutos (manual navigation) |
| Files read unnecessary | 4 archivos (map only top dirs) | 30+ archivos |
| Context retention | ✅ session-handoff preserves | ❌ re-reads needed |
| Feature implementation accuracy | ✅ same patterns identified | ✅ |
| Total tokens for feature | ~45,000 (3K context + 42K impl) | ~92,000 (50K context + 42K impl) |
| Token savings | ~50% | baseline |

## Expected Outcome
- **CON Plugin**: Using `/map` + CLAUDE.md, context discovery takes 3,000 tokens and 2 minutes. Agent reads only relevant directories, patterns documented from claude.md-writer. Session handoff preserves context. Total feature: ~45,000 tokens.
- **SIN Plugin**: Sin optimización, agent navega manualmente leyendo AGENTS.md, explorando imports, estudiando patrones repetidamente. 50,000 tokens en discovery alone. Sin handoff, context se pierde entre iteraciones. Total: ~92,000 tokens.

## Difficulty: Medium
## Est. Tokens: 2,000 (CON) vs 50,000 (SIN) para context discovery

## Skill References
- codebase-map R8 (output < 4KB)
- session-handoff R6 (output < 4KB)
- claude-md-writer R1-R6 (context efficiency)