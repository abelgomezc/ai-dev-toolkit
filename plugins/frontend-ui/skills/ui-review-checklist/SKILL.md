# UI Review Checklist Skill

## Cuándo usarlo
- **UI Reviewer**: Verifica implementación contra diseño y skills de dominio
- **UI Implementer**: Autoverificación antes de entregar

## Cuándo NO usarlo
- Como sustituto de testing automatizado (axe-core, lighthouse)
- Para decisiones de UX no cubiertas por design proposal

## Descripción
Checklist numerado y verificable para revisiones de UI. 41 reglas en 7 categorías: Accesibilidad, Responsividad, Consistencia Visual, Estados, Performance, Formularios, Internacionalización. Citable: "ui-review-checklist R5".

## Reglas Verificables

### A. Accesibilidad (WCAG 2.1 AA)

| Regla | Descripción | Verificación |
|-------|-------------|--------------|
| **R1** | Contraste 4.5:1 (texto normal), 3:1 (texto grande ≥18px/14px bold, UI components) | axe-core, Color Contrast Analyzer |
| **R2** | Foco visible en TODOS elementos interactivos (`:focus-visible` con ring/outline) | Tab navigation manual + inspección DevTools |
| **R3** | Navegación teclado completa: Tab order lógico, Enter/Space activa, Escape cierra modales/drawers, Arrow keys en menús/tabs | Tab testing manual |
| **R4** | Labels en TODOS inputs: `<label htmlFor>`, `aria-label`, o `aria-labelledby` | axe-core + inspección DOM |
| **R5** | Roles ARIA correctos: `role="dialog" aria-modal="true"`, `role="alert"/"status"`, `role="menu"`, `role="tablist/tab/tabpanel"`, `role="combobox"`, etc. | axe-core + inspección DOM |
| **R6** | Live regions para anuncios dinámicos: `role="status"` (polite) para toasts/info, `role="alert"` (assertive) para errores críticos | axe-core + screen reader testing |
| **R7** | Skip link al inicio de página: primer elemento enfocable, salta a `#main-content` | Tab testing (primer Tab) |
| **R8** | Heading hierarchy correcta: un solo h1, secuencia h1→h2→h3→h4 sin saltos | axe-core + heading map |
| **R9** | Texto alternativo en TODAS imágenes: informativa = descripción, decorativa = `alt=""` + `aria-hidden="true"` | axe-core + inspección DOM |

### B. Responsividad

| Regla | Descripción | Verificación |
|-------|-------------|--------------|
| **R10** | Mobile-first: estilos base para móvil, `sm:` `md:` `lg:` `xl:` `2xl:` para mejoras progresivas | Inspección CSS / Tailwind classes |
| **R11** | Breakpoints estándar: 640/768/1024/1280/1536 (Tailwind default) | `tailwind.config.ts` screens |
| **R12** | Touch targets ≥ 44×44px en botones, links, inputs, controles interactivos | DevTools device toolbar + regla CSS `min-h-[44px] min-w-[44px]` |
| **R13** | Viewport meta tag: `<meta name="viewport" content="width=device-width, initial-scale=1">` | `index.html` / `layout.tsx` |
| **R14** | No horizontal scroll en móvil: `overflow-x-hidden` en contenedores, tablas con scroll interno | Device toolbar testing |
| **R15** | Stack order lógico mobile: Header → Main → Sidebar (drawer) → Footer | Device toolbar visual check |
| **R16** | Imágenes responsive: `srcset`/`sizes`/`loading="lazy"` / Next.js Image / `picture` element | Network tab + Device toolbar |

### C. Consistencia Visual (Design System)

| Regla | Descripción | Verificación |
|-------|-------------|--------------|
| **R17** | Colores via tokens semánticos: `bg-background`, `text-foreground`, `border-border`, `ring-ring`, `bg-primary`, `text-primary-foreground` — **NUNCA** literales (`#2563eb`, `bg-blue-500`) | `grep -r "bg-blue\|text-gray-400\|#"` |
| **R18** | Espaciado via escala 4px: `space-y-4`, `gap-4`, `p-4`, `m-4` — **NO** valores arbitrarios (`mt-7`, `px-13`) | `grep -r "mt-\|mb-\|ml-\|mr-\|p-\|gap-" --include="*.tsx"` |
| **R19** | Tipografía via tokens: `text-heading-1`, `text-body`, `text-caption` — **NO** `text-2xl`, `text-lg` directo | `grep -r "text-2xl\|text-lg\|text-xl"` |
| **R20** | Border radius consistente: `rounded` (inputs/buttons), `rounded-md` (cards/dropdowns), `rounded-lg` (modals), `rounded-full` (pills/avatars) | Inspección visual + component library |
| **R21** | Sombras/elevation semánticas: `shadow-sm` (cards), `shadow-md` (dropdowns), `shadow-lg` (modals/drawers), `shadow-xl` (toasts) | Inspección visual |
| **R22** | Dark mode: `dark:` prefix en TODOS tokens — **NUNCA** `bg-white`/`text-black` hardcodeado | `grep -r "bg-white\|text-black\|bg-black\|text-white"` |
| **R23** | Componentes base: **SOLO** `~/components/ui/` (shadcn/ui) — **NO** `@radix-ui/*` directo | `grep -r "@radix-ui" --include="*.tsx" | grep -v "node_modules"` |

### D. Estados de UI

| Regla | Descripción | Verificación |
|-------|-------------|--------------|
| **R24** | Loading: Skeleton (preferido) o Spinner con `aria-busy="true"` + `aria-live="polite"` | Interacción manual + inspección ARIA |
| **R25** | Empty: Ilustración + mensaje claro + CTA (si aplica) | Estado vacío manual |
| **R26** | Error: Inline (campo) + Toast (global) + `role="alert"` + retry action | Submit inválido + error servidor |
| **R27** | Success: Toast con `role="status"` + `aria-live="polite"` | Submit exitoso |
| **R28** | Disabled states: `disabled` attr + `aria-disabled="true"` + styling `opacity-50 cursor-not-allowed` | Inspección DOM + visual |

### E. Performance

| Regla | Descripción | Verificación |
|-------|-------------|--------------|
| **R29** | Code splitting: Rutas lazy (`React.lazy` + `Suspense` / Angular `loadComponent`), componentes pesados lazy | Network tab + `React.lazy` / `loadComponent` |
| **R30** | Bundle size: `check-bundle.sh` reporta total < 500KB gzipped inicial, chunks < 100KB | `./scripts/check-bundle.sh` |
| **R31** | Imágenes optimizadas: AVIF/WebP, `srcset`/`sizes`, `loading="lazy"`, dimensiones explícitas, blur placeholder | Lighthouse + Network tab |
| **R32** | Memoización: `React.memo`, `useMemo`, `useCallback` en listas y callbacks — sin new object/array en render | React DevTools Profiler + inspección código |
| **R33** | Virtualización: `react-window` / `@tanstack/react-virtual` / CDK Virtual Scroll para listas > 50 items | Inspección código + performance tab |
| **R34** | TanStack Query: `staleTime` ≥ 5min, `gcTime` ≥ 10min, prefetching donde aplique | Inspección hooks + Network tab |

### F. Formularios y Validación

| Regla | Descripción | Verificación |
|-------|-------------|--------------|
| **R35** | Validación onBlur + onSubmit (NO solo onChange) | `mode: 'onBlur'` / `mode: 'onTouched'` |
| **R36** | Errores inline asociados via `aria-describedby` + `aria-invalid="true"` + id en message | axe-core + inspección DOM |
| **R37** | Submit deshabilitado mientras form inválido + loading state | `disabled={isSubmitting || !isValid}` |
| **R38** | Autocomplete attributes: `email`, `current-password`, `new-password`, `name`, `tel`, `street-address`, `postal-code`, `cc-number` | `grep -r "autoComplete\|autocomplete"` |

### G. Internacionalización y Accesibilidad Adicional

| Regla | Descripción | Verificación |
|-------|-------------|--------------|
| **R39** | `lang` attribute en `<html lang="es">` | `index.html` / `layout.tsx` |
| **R40** | Direction support: `dir="rtl"` via CSS logical properties (`margin-inline-start`, `padding-inline-end`) | CSS inspection |
| **R41** | Reduced motion: `@media (prefers-reduced-motion: reduce)` desactiva animaciones/transiciones | `prefers-reduced-motion` testing |

## Formato de Hallazgos (Output UI Reviewer)
```json
{
  "findings": [
    {
      "severity": "blocker",
      "rule": "ui-review-checklist-R5",
      "file": "src/components/UserDialog.tsx",
      "line": 42,
      "description": "Dialog missing role=\"dialog\" aria-modal=\"true\". Screen readers won't announce as modal.",
      "suggestion": "Add role=\"dialog\" aria-modal=\"true\" to DialogContent, ensure focus trap via Radix Dialog"
    },
    {
      "severity": "major",
      "rule": "ui-review-checklist-R17",
      "file": "src/components/Dashboard.tsx",
      "line": 15,
      "description": "Hardcoded color bg-blue-500 used instead of token bg-primary",
      "suggestion": "Replace with bg-primary / text-primary-foreground tokens"
    },
    {
      "severity": "minor",
      "rule": "ui-review-checklist-R18",
      "file": "src/components/Card.tsx",
      "line": 8,
      "description": "Arbitrary spacing mt-7 used instead of scale (mt-6 or mt-8)",
      "suggestion": "Use mt-6 or mt-8 from 4px scale"
    },
    {
      "severity": "info",
      "rule": "ui-review-checklist-R41",
      "file": "src/components/AnimatedCard.tsx",
      "line": 12,
      "description": "Animation doesn't respect prefers-reduced-motion",
      "suggestion": "Wrap animate prop with prefersReducedMotion check"
    }
  ]
}
```

## Clasificación de Severidad
| Severidad | Criterio | Ejemplos |
|-----------|----------|----------|
| **Blocker** | Violación WCAG AA que bloquea uso | Contraste, foco, teclado, ARIA crítico, skip link |
| **Major** | Responsive roto, estado faltante (loading/error), token hardcodeado, bundle > límite | Mobile broken, loading skeleton faltante, color literal, bundle > 500KB |
| **Minor** | Espaciado inconsistente, heading hierarchy, touch target pequeño, memo faltante | `mt-7` vs `mt-6`, `h3` tras `h1`, botón 40×40px |
| **Info** | Mejora sugerida (reduced motion, i18n, virtualización opcional) | Sin `@media prefers-reduced-motion`, sin `lang` attribute |

## Verificación en Review
- **ui-review-checklist R1-R9**: Accesibilidad WCAG 2.1 AA (axe-core + testing manual)
- **ui-review-checklist R10-R16**: Responsividad mobile-first + breakpoints + touch targets
- **ui-review-checklist R17-R23**: Consistencia visual (tokens, escala 4px, dark mode, shadcn/ui)
- **ui-review-checklist R24-R28**: Estados UI (loading, empty, error, success, disabled)
- **ui-review-checklist R29-R34**: Performance (code splitting, bundle, imágenes, memo, virtualización, TanStack Query)
- **ui-review-checklist R35-R38**: Formularios (validación, ARIA errors, submit, autocomplete)
- **ui-review-checklist R39-R41**: i18n + reduced motion