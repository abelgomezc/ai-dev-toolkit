# Eval Case: Claude MD Writer - Documentation Generation

## Plugin
context-toolkit

## Escenario
Nuevo proyecto creado con `npx create-next-app@latest my-dashboard --typescript --tailwind --eslint --app`. El claude-md-writer skill debe generar un CLAUDE.md que capture todo lo necesario para que un agente trabaje eficientemente.

## Input (Prompt)
```
# Ejecutar claude-md-writer para proyecto Next.js 15 + TypeScript + Tailwind + shadcn/ui
# Directorio: /my-dashboard (proyecto real)

Stack esperado:
- Next.js 15 (App Router)
- TypeScript 5.3
- Tailwind 3.4
- shadcn/ui components
- Vitest + React Testing Library
- ESLint + Prettier

Comando esperado: claude-md-writer --init o /map --include-source
```

## Métricas de Evaluación

| Métrica | CON Plugin (claude-md-writer) | SIN Plugin (manual) |
|---------|------------------------------|---------------------|
| Stack detection | ✅ Next.js 15, TS 5.3, Tailwind, shadcn | ⚠️ solo "Next.js" genérico |
| Structure documented | ✅ app/ router, components/, lib/, hooks/ | ⚠️ solo top-level dirs |
| Commands extracted | ✅ package.json scripts (dev, build, test, lint) | ⚠️ hardcodeados asumidos |
| Conventions captured | ✅ import paths (~/), test patterns (*-.test.ts) | ⚠️ genéricos |
| Patterns documented | ✅ Server Actions, Client Components, API routes | ❌ |
| Tokens to achieve | 4,000 (auto-generado) | 8,000 (manual discovery) |
| Accuracy (verified via spot check) | ✅ 100% | ⚠️ 70-80% |

## Expected Outcome
- **CON Plugin**: CLAUDE.md completo con stack detectado (Next.js 15.0, TypeScript, Tailwind 3.4, shadcn/ui), estructura de directorios con patrones (App Router: app/api/, app/(dashboard)/layout.tsx, lib/actions/, hooks/), comandos extraídos de package.json, convenciones (imports absolutos con ~/, tests colocados junto a source), patterns clave (Server vs Client Components, Server Actions), generación automática sin intervención humana.
- **SIN Plugin**: CLAUDE.md manual con info genérica, comandos asumidos no extraídos, convenciones no detectadas, patterns omitidos.

## Difficulty: Easy
## Est. Tokens: 12,000 (CON) vs 18,000 (SIN)

## Skill References
- claude-md-writer R1-R6 (stack, structure, commands, conventions, patterns, timestamp)
- codebase-map para source code analysis complementario