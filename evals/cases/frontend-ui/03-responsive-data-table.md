# Eval Case: Responsive Design - Multi-layout Data Table

## Plugin
frontend-ui

## Escenario
Implementar una tabla de datos con columnas dinámicas que funciona en mobile, tablet y desktop. Mobile usa card layout, desktop usa tabla tradicional.

## Input (Prompt)
```
/ui "Data table responsive para 'Users list':
- Desktop: 6 columns (avatar, name, email, role, status, actions)
- Tablet: 4 columns (hide avatar, collapse actions)
- Mobile: Card layout (stack: avatar/name/email en header, role/status/actions en body)
- Features: sort (name, email, created_at), filter (search + status), pagination (10/25/50 per page)
- TanStack Table (headless) + shadcn/ui
- Touch targets ≥ 44×44px
- Loading: skeleton rows (5 skeleton cards en mobile, 5 rows en desktop)
- Empty: 'No users found' + search reset CTA
"
```

## Métricas de Evaluación

| Métrica | CON Plugin (UI flow) | SIN Plugin (directo) |
|---------|---------------------|---------------------|
| Desktop table layout | ✅ 6-column tabla | ✅ |
| Tablet responsive | ✅ 4-column, collapsed | ⚠️ solo desktop |
| Mobile card layout | ✅ stacked cards | ❌ |
| Column visibility logic | ✅ data-label en mobile cards | ⚠️ tabla overflow en mobile |
| Touch targets ≥44px | ✅ verificado con DevTools | ⚠️ 32px |
| Skeleton loading | ✅ 5 items, mobile + desktop | ⚠️ spinner simple |
| Empty state | ✅ con search reset CTA | ⚠️ solo texto |
| Breakpoint handling | ✅ sm/md/lg/xl | ⚠️ solo @media |
| Review findings (responsive) | 0/0 | 4-5/majors |

## Expected Outcome
- **CON Plugin**: Tabla responsive con card layout en mobile (data-label attributes), skeleton loaders para ambos layouts, touch targets ≥44px, 0 review findings, funciona sin horizontal scroll en mobile.
- **SIN Plugin**: Tabla que hace overflow en mobile, solo desktop styles, touch targets pequeños, skeleton faltante.

## Difficulty: Hard
## Est. Tokens: 42,000 (CON) vs 30,000 (SIN)

## Skill References
- ui-review-checklist R10-R16 (responsive)
- responsive-and-performance RAP-1 (mobile-first), RAP-12 (touch targets), RAP-14 (reduced motion)
- accessibility-wcag WCAG-4 (labels en mobile cards)