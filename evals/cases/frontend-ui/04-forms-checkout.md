# Eval Case: Forms & Validation - Multi-step Checkout

## Plugin
frontend-ui

## Escenario
Implementar un checkout multi-step con validación compleja: shipping → payment → review. Cada step tiene validaciones diferentes y el form debe preservar estado entre navegación.

## Input (Prompt)
```
/ui "Checkout multi-step (React Hook Form + Zod):

Step 1 - Shipping:
- Full name (required)
- Address (required, min 5 chars)
- City (required)
- Postal code (required, formato: 5 digits o letra+número)
- Country (select required)

Step 2 - Payment:
- Card number (required, 16 digits)
- Expiry (MM/YY required, no expirada)
- CVC (3 digits required)
- Billing same as shipping (checkbox default: checked)

Step 3 - Review:
- Mostrar resumen de datos
- Editar link a cada step
- Confirmar terms checkbox (required)
- Submit button (disabled hasta terms aceptadas)

UX:
- Progress indicator (3 steps: Shipping → Payment → Review)
- Navegación forward/backward
- Validar on blur + submit
- Loading state en submit (spinner)
- Success: redirect a confirmation page
- Error: inline (field) + toast (server error)
"
```

## Métricas de Evaluación

| Métrica | CON Plugin (UI flow) | SIN Plugin (directo) |
|---------|---------------------|---------------------|
| Form validation (RHF + Zod) | ✅ schema-based, type-safe | ⚠️ validación manual (strings) |
| Validation timing | ✅ onBlur + onSubmit | ⚠️ solo onSubmit |
| Error display | ✅ inline + aria-describedby | ⚠️ solo visual (no ARIA) |
| Progress indicator | ✅ 3 steps visual | ⚠️ texto plano |
| State persistence | ✅ preserve entre steps | ⚠️ se pierde al navegar |
| Submit disabled states | ✅ terms required | ⚠️ puede habilitar sin terms |
| Loading + success | ✅ spinner + redirect | ⚠️ solo loading |
| Review edit links | ✅ back to step | ❌ |
| Review findings (forms) | 0/0 | 3-4/majors |

## Expected Outcome
- **CON Plugin**: Form con RHF + Zod schemas type-safe, validación onBlur+onSubmit, errores inline + ARIA, progress indicator funcional, state persistido entre steps, submit disabled hasta terms, loading spinner + success redirect, edit links en review.
- **SIN Plugin**: Validación manual sin types, solo onSubmit, errores visuales sin ARIA, state no persistido, submit habilitado sin terms required.

## Difficulty: Hard
## Est. Tokens: 45,000 (CON) vs 32,000 (SIN)

## Skill References
- ui-review-checklist R35-R38 (forms + validation)
- forms-and-validation RF-1 through RF-12
- accessibility-wcag WCAG-4 (labels), WCAG-6 (live regions para success/error)