# Eval Case: Accessibility - WCAG 2.1 AA Compliance Form

## Plugin
frontend-ui

## Escenario
Implementar un formulario de signup con validación que cumpla WCAG 2.1 AA. El UI Reviewer debe validar con axe-core y ui-review-checklist.

## Input (Prompt)
```
/ui "Signup form con:
- Email input (required, email validation)
- Password + confirm (min 8 chars, must match)
- Name (required)
- Terms checkbox (required)
- Submit button

Requisitos de accesibilidad:
- 4.5:1 contrast (verify with axe-core)
- Focus visible en todos los inputs
- Labels asociados (label htmlFor)
- aria-invalid + aria-describedby para errores
- skip link al inicio
- heading hierarchy (h1 → h2)
- role='alert' para error summary
- Keyboard navigation (Tab, Enter, Escape)
- reduced motion support
"
```

## Métricas de Evaluación

| Métrica | CON Plugin (UI flow) | SIN Plugin (directo) |
|---------|---------------------|---------------------|
| axe-core violations | 0 | 3-5 (contrast, labels, ARIA) |
| Focus visible | ✅ en TODOS interactivos | ⚠️ algunos omitidos |
| Labels (all inputs) | ✅ label htmlFor + aria-describedby | ⚠️ aria-label parcial |
| Keyboard navigation | ✅ Tab, Enter, Escape, Arrow keys | ⚠️ solo Tab |
| Heading hierarchy | ✅ h1 → h2 (sin saltos) | ⚠️ saltos de nivel |
| Error announcements | ✅ role='alert' aria-live | ⚠️ solo visual |
| Reduced motion | ✅ @media prefers-reduced-motion | ❌ |
| Review findings (a11y) | 0/0 | 4-6/majors |

## Expected Outcome
- **CON Plugin**: Formulario con axe-core 0 violations, labels correctos, focus visible, keyboard nav completa, error announcements con ARIA, heading hierarchy correcta, reduced motion support, skip link funcional.
- **SIN Plugin**: Implementación funcional pero con 3-5 axe-core violations, labels omitidos, focus styles faltantes, sin reduced motion support.

## Difficulty: Hard
## Est. Tokens: 35,000 (CON) vs 25,000 (SIN)

## Skill References
- ui-review-checklist R1-R9 (WCAG 2.1 AA)
- accessibility-wcag WCAG-1 through WCAG-9
- accessibility-wcag WCAG-7 (skip links)