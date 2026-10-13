# Accessibility WCAG Skill

## Cuándo usarlo
- **UI Designer**: Define requisitos de accesibilidad en design proposal
- **UI Implementer**: Implementa siguiendo WCAG 2.1 AA obligatorio
- **UI Reviewer**: Verifica cada regla con `ui-review-checklist` (R1-R9)

## Cuándo NO usarlo
- Como sustituto de auditoría experta (requiere testing con usuarios reales)
- Para WCAG 2.2 / 3.0 (base es 2.1 AA)

## Descripción
Reglas verificables para **WCAG 2.1 Level AA**: Contraste, foco visible, navegación teclado, etiquetas, roles ARIA, live regions, skip links, heading hierarchy, texto alternativo. Cada regla citable: "accessibility-wcag regla 3".

## Reglas Verificables (WCAG 2.1 AA)

### WCAG-1: Contraste Mínimo (1.4.3)
| Elemento | Ratio Mínimo | Verificación |
|----------|--------------|--------------|
| Texto normal (< 18px / < 14px bold) | 4.5:1 | axe-core, Color Contrast Analyzer |
| Texto grande (≥ 18px / ≥ 14px bold) | 3:1 | axe-core |
| UI Components (borders, focus rings) | 3:1 | axe-core |
| Gráficos (líneas, barras, sectores) | 3:1 | Manual |

**Regla**: **NUNCA** `text-gray-400` sobre `bg-white` (ratio ~2.1:1). Usar tokens: `text-muted-foreground` sobre `bg-background`.

### WCAG-2: Foco Visible (2.4.7)
```css
/* BUENO - Focus visible en TODOS los interactivos */
:focus-visible {
  outline: none;
  ring: 2px;
  ring-color: hsl(var(--ring));
  ring-offset: 2px;
  ring-offset-color: hsl(var(--background));
}

/* BUENO - Exception: si outline none, DEBE haber alternativa visible */
button:focus-visible,
a:focus-visible,
input:focus-visible,
select:focus-visible,
textarea:focus-visible,
[role="button"]:focus-visible,
[tabindex="0"]:focus-visible {
  /* styles above */
}

/* MALO - Sin focus visible */
*:focus { outline: none; }  /* FALLA WCAG-2 */
```

**Regla**: Todo elemento interactivo (`button`, `a`, `input`, `select`, `textarea`, `[role="button"]`, `[tabindex="0"]`) **DEBE** tener `:focus-visible` visible.

### WCAG-3: Navegación Teclado (2.1.1, 2.1.2)
| Patrón | Teclas | Implementación |
|--------|--------|----------------|
| Navegación | Tab / Shift+Tab | `tabIndex` natural, orden DOM lógico |
| Activación | Enter / Space | `onKeyDown` para `role="button"` |
| Cerrar modal/drawer | Escape | `onKeyDown={e => e.key === 'Escape' && close()}` |
| Menús dropdown | Arrow keys | Radix DropdownMenu / CDK |
| Tabs | Arrow Left/Right | Radix Tabs / CDK |
| Slider | Arrow keys | Radix Slider / CDK |
| Autocomplete | Arrow Up/Down + Enter | Radix Select / CDK |

**Regla**: **TODA** funcionalidad accesible por mouse **DEBE** ser accesible por teclado.

### WCAG-4: Etiquetas en Inputs (1.3.1, 3.3.2)
```tsx
// BUENO - Label asociado explícitamente
<FormField control={form.control} name="email" render={({ field }) => (
  <FormItem>
    <FormLabel htmlFor={field.id}>Email</FormLabel>  {/* htmlFor = input id */}
    <FormControl>
      <Input id={field.id} {...field} />  {/* id coincide con label htmlFor */}
    </FormControl>
    <FormMessage />
  </FormItem>
)}/>

// BUENO - aria-label si no hay label visual
<Input aria-label="Search" placeholder="Search..." />

// BUENO - aria-labelledby para labels compuestos
<div id="email-label">Email address</div>
<Input aria-labelledby="email-label" />

// MALO - Input sin label
<Input placeholder="Email" />  {/* FALLA WCAG-4 */}
```

**Regla**: **TODO** input, select, textarea **DEBE** tener label accesible (`<label htmlFor>`, `aria-label`, o `aria-labelledby`).

### WCAG-5: Roles ARIA Correctos (4.1.2)
| Componente | Role Requerido | Atributos Obligatorios |
|------------|----------------|------------------------|
| Modal/Dialog | `role="dialog"` `aria-modal="true"` | `aria-labelledby`, `aria-describedby` |
| Alert/Toast | `role="alert"` (assertive) / `role="status"` (polite) | `aria-live` implícito |
| Tooltip | `role="tooltip"` | `aria-describedby` en trigger |
| Dropdown Menu | `role="menu"` | `aria-orientation`, `aria-activedescendant` |
| Tabs | `role="tablist"`, `role="tab"`, `role="tabpanel"` | `aria-selected`, `aria-controls`, `id`/`aria-labelledby` |
| Accordion | `role="region"` `aria-expanded` | `aria-controls` |
| Progress | `role="progressbar"` | `aria-valuemin`, `aria-valuemax`, `aria-valuenow` |
| Slider | `role="slider"` | `aria-valuemin`, `aria-valuemax`, `aria-valuenow`, `aria-orientation` |
| Combobox/Autocomplete | `role="combobox"` | `aria-expanded`, `aria-controls`, `aria-activedescendant` |

**Regla**: Usar **Radix UI / CDK** que ya incluyen roles correctos. **NO** inventar roles custom sin testing.

### WCAG-6: Live Regions (4.1.3)
```tsx
// BUENO - Toast con role="status" (polite)
<ToastProvider>
  <Toast>
    <ToastTitle>Success</ToastTitle>
    <ToastDescription>User created successfully</ToastDescription>
  </Toast>
</ToastProvider>

// Implementación toast:
<div role="status" aria-live="polite" aria-atomic="true">
  {/* content */}
</div>

// BUENO - Error crítico con role="alert" (assertive)
<div role="alert" aria-live="assertive" aria-atomic="true">
  <p>Session expired. Please log in again.</p>
</div>

// MALO - Sin live region
<div className="toast">Saved!</div>  {/* FALLA WCAG-6: screen readers no anuncian */}
```

**Regla**: Cambios de estado dinámicos (toasts, validaciones, carga, errores) **DEBEN** anunciarse via `aria-live` (polite/status para info, assertive/alert para errores críticos).

### WCAG-7: Skip Links (2.4.1)
```tsx
// BUENO - Skip link al inicio de body
<body>
  <a 
    href="#main-content" 
    className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 z-50 px-4 py-2 bg-primary text-primary-foreground rounded-md"
  >
    Skip to main content
  </a>
  <header>...</header>
  <main id="main-content">...</main>
</body>
```

**Regla**: Primer elemento enfocable en página **DEBE** ser skip link a contenido principal.

### WCAG-8: Heading Hierarchy (1.3.1)
```tsx
// BUENO - Jerarquía correcta
<h1>Page Title</h1>
  <h2>Section 1</h2>
    <h3>Subsection 1.1</h3>
    <h3>Subsection 1.2</h3>
  <h2>Section 2</h2>
    <h3>Subsection 2.1</h3>

// MALO - Saltos de nivel
<h1>Title</h1>
<h3>Subsection</h3>  {/* FALLA WCAG-8: salta h2 */}
<h2>Section</h2>

// MALO - Múltiples h1
<h1>Title 1</h1>
<h1>Title 2</h1>  {/* FALLA WCAG-8: solo un h1 por página */}
```

**Regla**: Un solo `h1` por página, secuencia `h1 → h2 → h3 → h4` sin saltos.

### WCAG-9: Texto Alternativo en Imágenes (1.1.1)
```tsx
// BUENO - Imagen informativa
<Image 
  src="/dashboard.png" 
  alt="Dashboard showing 24% increase in users this month" 
  width={800} 
  height={400} 
/>

// BUENO - Imagen decorativa (alt vacío)
<Image src="/decoration.svg" alt="" aria-hidden="true" />

// BUENO - Icono con label en botón
<Button aria-label="Delete user">
  <Trash2 className="h-4 w-4" aria-hidden="true" />
</Button>

// MALO - Sin alt
<Image src="/chart.png" />  {/* FALLA WCAG-9 */}

// MALO - Alt redundante
<img src="logo.png" alt="Logo" />  {/* Si está en <h1>Company</h1>, alt="" es mejor */}
```

**Regla**: **TODA** imagen **DEBE** tener `alt`. Informativa = descripción; Decorativa = `alt=""` + `aria-hidden="true"`.

## Testing Automatizado

### axe-core (CI/CD)
```bash
# Instalar
npm install -D @axe-core/playwright @axe-core/react

# Test E2E con Playwright
# tests/a11y.spec.ts
import { injectAxe, checkA11y } from '@axe-core/playwright';

test('dashboard page has no a11y violations', async ({ page }) => {
  await page.goto('/dashboard');
  await injectAxe(page);
  await checkA11y(page, undefined, {
    detailedReport: true,
    detailedReportOptions: { html: true },
  });
});
```

```tsx
// Componente React - testing en dev
import { useEffect } from 'react';
import axe from 'axe-core';

export function A11yWrapper({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    if (process.env.NODE_ENV === 'development') {
      axe.run(document, { runOnly: { type: 'tag', values: ['wcag2aa'] } })
        .then(results => {
          if (results.violations.length) {
            console.group('🔴 Accessibility Violations');
            results.violations.forEach(v => {
              console.error(`[${v.impact}] ${v.help}:`, v.nodes.map(n => n.target));
            });
            console.groupEnd();
          }
        });
    }
  }, []);
  
  return <>{children}</>;
}
```

### eslint-plugin-jsx-a11y (Lint)
```json
// .eslintrc.json
{
  "extends": ["plugin:jsx-a11y/recommended"],
  "rules": {
    "jsx-a11y/anchor-is-valid": "error",
    "jsx-a11y/click-events-have-key-events": "error",
    "jsx-a11y/no-noninteractive-element-interactions": "error",
    "jsx-a11y/role-has-required-aria-props": "error",
    "jsx-a11y/aria-props": "error"
  }
}
```

## Verificación en Review
- **accessibility-wcag WCAG-1**: ¿Contraste 4.5:1 texto / 3:1 UI components? (axe-core)
- **accessibility-wcag WCAG-2**: ¿`:focus-visible` visible en TODOS interactivos?
- **accessibility-wcag WCAG-3**: ¿Navegación teclado completa (Tab, Enter, Escape, Arrows)?
- **accessibility-wcag WCAG-4**: ¿Labels en TODOS inputs (label htmlFor / aria-label / aria-labelledby)?
- **accessibility-wcag WCAG-5": ¿Roles ARIA correctos (dialog, alert, menu, tablist, combobox)?
- **accessibility-wcag WCAG-6": ¿Live regions (role=status/alert) para cambios dinámicos?
- **accessibility-wcag WCAG-7": ¿Skip link al inicio de página?
- **accessibility-wcag WCAG-8": ¿Heading hierarchy correcta (h1→h2→h3 sin saltos)?
- **accessibility-wcag WCAG-9": ¿alt en TODAS imágenes (informativa=desc, decorativa=alt="")?