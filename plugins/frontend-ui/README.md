# frontend-ui

Diseño e implementación de interfaces profesionales con React/TypeScript, Tailwind CSS, shadcn/ui y soporte alterno para Angular.

## Agentes

| Agente | Permisos | Rol |
|--------|----------|-----|
| `ui-designer` | Read, Glob, Grep, WebFetch, WebSearch | Propone estructura, componentes, estados y decisiones de diseño justificadas |
| `ui-implementer` | Read, Write, Edit, MultiEdit, Glob, Grep, Bash, Task | Implementa siguiendo design system, accesibilidad y performance |
| `ui-reviewer` | Read, Glob, Grep, WebFetch, WebSearch | Revisa con checklist de 41 reglas (accesibilidad, responsive, consistencia, performance) |

## Skills

| Skill | Descripción |
|-------|-------------|
| `design-system-foundations` | Tokens, escala 4px, tipografía, colores semánticos |
| `react-component-patterns` | Patrones React 18, hooks, composición, performance |
| `tailwind-shadcn-stack` | Configuración Tailwind + shadcn/ui + Radix |
| `angular-ui-patterns` | Patrones Angular 17+ con Material/CDK |
| `forms-and-validation` | React Hook Form + Zod, validación accesible |
| `data-display-and-charts` | Tablas, listas virtualizadas, Recharts |
| `accessibility-wcag` | WCAG 2.1 AA: contraste, foco, teclado, ARIA, skip links |
| `responsive-and-performance` | Mobile-first, breakpoints, lazy loading, Core Web Vitals |
| `ui-review-checklist` | 41 reglas verificables (R1-R41) |

## Comando

```bash
/ui "Dashboard con sidebar, grid de métricas, tabla con paginación y modal de detalle"
```

## Scripts

```bash
./plugins/frontend-ui/scripts/check-a11y.sh
./plugins/frontend-ui/scripts/check-bundle.sh --budget=500
```
