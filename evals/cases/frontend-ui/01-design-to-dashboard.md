# Eval Case: Design → Implementation - Dashboard with Metrics Grid

## Plugin
frontend-ui

## Escenario
Diseñar e implementar un dashboard de usuario con grid de métricas, tabla de actividad con paginación, y detalles de usuario en modal. Mobile-first con shadcn/ui.

## Input (Prompt)
```
/ui "Dashboard de usuario con:
- Metric grid (4 widgets: revenue, users, conversions, retention) con trend indicators (up/down chevrons + %)
- Activity table: 5 columns (date, action, user, status, details), pagination (20/page), filtros por status
- User detail modal: avatar, profile info, activity history, edit button

Requisitos:
- Responsive: mobile drawer sidebar, tablet 2-col grid, desktop 4-col grid
- shadcn/ui components (Card, Table, Dialog, Avatar)
- Tailwind color tokens (primary, muted-foreground, etc.)
- Loading skeletons (4-item grid skeleton)
- Empty state: 'No activity yet' + CTA
- Error state: toast + inline retry

States para cada component: loading, empty, error, success"
```

## Métricas de Evaluación

| Métrica | CON Plugin (UI flow) | SIN Plugin (directo) |
|---------|---------------------|---------------------|
| Componentes estructurados | ✅ 4 components (MetricsGrid, ActivityTable, UserModal, Sidebar) | ⚠️ 6+ componentes sin separación clara |
| States implementados | ✅ loading/empty/error/success (todos) | ⚠️ loading + error, empty omitido |
| Responsive behavior | ✅ breakpoints sm/md/lg/xl, drawer sidebar | ⚠️ solo desktop styles |
| shadcn/ui component usage | ✅ todos desde ~/components/ui/ | ⚠️ mezcla Radix directo |
| Color tokens | ✅ solo semantic tokens (bg-background, text-foreground) | ⚠️ bg-blue-500 hardcodeado |
| Accessibility | ✅ roles, labels, focus-visible, aria | ⚠️ labels faltantes |
| Review findings (blocker/major) | 0/0 | 2-3/4-6 |

## Expected Outcome
- **CON Plugin**: 4 componentes bien estructurados, estados loading/empty/error/success implementados, responsive grid con drawer mobile, tokens semánticos, accesibilidad completa (axe-core 0 violations), 0 review findings.
- **SIN Plugin**: Implementación funcional pero con estados faltantes, responsive parcial, posible accessibility violations, 2-3 major findings.

## Difficulty: Medium
## Est. Tokens: 38,000 (CON) vs 28,000 (SIN)

## Skill References
- ui-review-checklist R10-R16 (responsive), R17-R23 (design system), R24-R28 (states)
- accessibility-wcag WCAG-1 through WCAG-9
- responsive-and-performance RAP-1 through RAP-14