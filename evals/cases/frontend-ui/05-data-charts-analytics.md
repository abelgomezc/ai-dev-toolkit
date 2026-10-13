# Eval Case: Data Display & Charts - Analytics Dashboard

## Plugin
frontend-ui

## Escenario
Implementar un dashboard analítico con gráficos interactivos, métricas kpi, y filtros de tiempo. Usar Recharts + shadcn/ui + TanStack Query.

## Input (Prompt)
```
/ui "Analytics dashboard con:

Layout:
- KPI Cards (4): Revenue ($), Users (N), Conversion (%), Retention (%)
- Time filter: dropdown (7d, 30d, 90d, 1y) — data refetch con TanStack Query
- Revenue chart: área (revenue over time)
- Conversion chart: gráfico de barras (canal breakdown)
- Users chart: gráfico de líneas (new vs returning)
- Retention chart: heatmap-style (cohort retention)

Tecnologías:
- Recharts (Area, BarChart, LineChart, Tooltip, Legend)
- shadcn/ui components (Card, Select, Badge)
- TanStack Query (staleTime: 5min, prefetching, placeholderData)
- Responsive containers (ResponsiveContainer)

Estados:
- Loading: skeleton loaders para charts
- Error: retry button + toast
- Empty: 'No data for selected period'
- Hover: tooltip interactivo

Performance:
- Virtualización para large datasets (>1000 rows)
- Memoización (React.memo, useMemo)
- Bundle: lazy load charts (React.lazy + Suspense)
"
```

## Métricas de Evaluación

| Métrica | CON Plugin (UI flow) | SIN Plugin (directo) |
|---------|---------------------|---------------------|
| Chart types correctas | ✅ Area/Bar/Line según datos | ⚠️ uso incorrecto de chart types |
| TanStack Query config | ✅ staleTime, gcTime, prefetch, placeholder | ⚠️ solo basic query |
| Performance optimization | ✅ lazy charts, useMemo, React.memo | ⚠️ carga eager, sin memo |
| ResponsiveContainer usage | ✅ charts adaptan a container | ⚠️ fixed sizes |
| Virtualización | ✅ para >1000 rows | ❌ |
| Loading states | ✅ skeletons para charts | ⚠️ spinner |
| Hover interactions | ✅ tooltips, legends | ⚠️ solo basic tooltips |
| Bundle size | ✅ < 300KB (charts lazy) | ⚠️ >500KB (charts eager) |
| Review findings (performance) | 0/0 | 4-5/majors |

## Expected Outcome
- **CON Plugin**: Dashboard analítico con charts correctos (Area=Revenue, Bar=Conversion by channel, Line=Users new vs returning), TanStack Query configurado (staleTime=5min, prefetching, placeholderData), charts lazy-loaded via React.lazy, virtualización para datasets grandes, skeletons de loading, tooltips interactivos, bundle < 300KB gzipped.
- **SIN Plugin**: Charts con configuración incorrecta, carga eager de librerías de gráficos, bundle > 500KB, sin virtualización, loading spinner simple.

## Difficulty: Hard
## Est. Tokens: 48,000 (CON) vs 35,000 (SIN)

## Skill References
- ui-review-checklist R29-R34 (performance: code splitting, bundle, images, memo, virtualização, query)
- data-display-and-charts DC-1 through DC-10
- responsive-and-performance RAP-7 (code splitting), RAP-8 (bundle < 500KB), RAP-11 (memoización)