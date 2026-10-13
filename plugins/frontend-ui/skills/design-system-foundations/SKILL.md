# Design System Foundations Skill

## Cuándo usarlo
- **UI Designer**: Define tokens, componentes base, jerarquía visual
- **UI Implementer**: Implementa usando tokens obligatorios, no hardcodea
- **UI Reviewer**: Verifica consistencia visual (tokens, dark mode, elevation)

## Cuándo NO usarlo
- Para decisiones de layout específico de una pantalla (eso es design proposal)
- Para lógica de negocio o estado de aplicación

## Descripción
Define los **tokens fundamentales** (color, tipografía, espaciado, radios, sombras), **escala consistente**, **modo claro/oscuro**, y **cómo evitar aspecto genérico de plantilla**. Es la base contractual entre diseño e implementación.

## Archivos de Referencia
- `tokens.json` — Definición completa de tokens (color, spacing, typography, radius, shadow, elevation, motion, z-index)
- `components-base.md` — Componentes base obligatorios (Button, Input, Card, Dialog, etc.)
- `dark-mode.md` — Implementación dark mode correcta
- `avoid-generic-look.md` — Cómo personalizar y evitar aspecto "shadcn/ui default"

## Tokens Obligatorios (tokens.json structure)

### Color Tokens (Semantic, no literales)
```json
{
  "color": {
    "background": "hsl(var(--background))",
    "foreground": "hsl(var(--foreground))",
    "primary": {
      "DEFAULT": "hsl(var(--primary))",
      "foreground": "hsl(var(--primary-foreground))"
    },
    "secondary": {
      "DEFAULT": "hsl(var(--secondary))",
      "foreground": "hsl(var(--secondary-foreground))"
    },
    "muted": {
      "DEFAULT": "hsl(var(--muted))",
      "foreground": "hsl(var(--muted-foreground))"
    },
    "accent": {
      "DEFAULT": "hsl(var(--accent))",
      "foreground": "hsl(var(--accent-foreground))"
    },
    "destructive": {
      "DEFAULT": "hsl(var(--destructive))",
      "foreground": "hsl(var(--destructive-foreground))"
    },
    "border": "hsl(var(--border))",
    "input": "hsl(var(--input))",
    "ring": "hsl(var(--ring))",
    "success": {
      "DEFAULT": "hsl(var(--success))",
      "foreground": "hsl(var(--success-foreground))"
    },
    "warning": {
      "DEFAULT": "hsl(var(--warning))",
      "foreground": "hsl(var(--warning-foreground))"
    }
  }
}
```

**Regla DSF-1**: **NUNCA** usar colores literales (`#2563eb`, `bg-blue-500`, `text-gray-900`). Siempre tokens semánticos.

### Typography Tokens
```json
{
  "typography": {
    "fontFamily": {
      "sans": "var(--font-sans)",
      "mono": "var(--font-mono)",
      "display": "var(--font-display)"
    },
    "fontSize": {
      "heading-1": ["clamp(2rem, 5vw, 3rem)", { "lineHeight": "1.1", "letterSpacing": "-0.02em" }],
      "heading-2": ["clamp(1.5rem, 3vw, 2.25rem)", { "lineHeight": "1.2", "letterSpacing": "-0.01em" }],
      "heading-3": ["clamp(1.25rem, 2vw, 1.5rem)", { "lineHeight": "1.3" }],
      "body-lg": ["1.125rem", { "lineHeight": "1.7" }],
      "body": ["1rem", { "lineHeight": "1.6" }],
      "body-sm": ["0.875rem", { "lineHeight": "1.5" }],
      "caption": ["0.75rem", { "lineHeight": "1.5" }]
    },
    "fontWeight": {
      "normal": "400",
      "medium": "500",
      "semibold": "600",
      "bold": "700"
    }
  }
}
```

**Regla DSF-2**: Usar clases semánticas: `text-heading-1`, `text-body`, `text-caption`. No `text-2xl`, `text-lg` directo.

### Spacing Scale (Base 4px)
```json
{
  "spacing": {
    "0": "0",
    "1": "0.25rem",  // 4px
    "2": "0.5rem",   // 8px
    "3": "0.75rem",  // 12px
    "4": "1rem",     // 16px
    "5": "1.25rem",  // 20px
    "6": "1.5rem",   // 24px
    "8": "2rem",     // 32px
    "10": "2.5rem",  // 40px
    "12": "3rem",    // 48px
    "16": "4rem",    // 64px
    "20": "5rem",    // 80px
    "24": "6rem"     // 96px
  }
}
```

**Regla DSF-3**: Espaciado via escala: `space-y-4`, `gap-4`, `p-4`, `m-4`. No `mt-7`, `px-13` arbitrario.

### Border Radius
```json
{
  "borderRadius": {
    "none": "0",
    "sm": "0.25rem",   // 4px - badges, small elements
    "DEFAULT": "0.375rem", // 6px - inputs, buttons
    "md": "0.5rem",    // 8px - cards, dropdowns
    "lg": "0.75rem",   // 12px - modals, large cards
    "xl": "1rem",      // 16px - hero sections
    "full": "9999px"   // pills, avatars
  }
}
```

**Regla DSF-4**: Radius consistente: `rounded` (inputs/buttons), `rounded-md` (cards), `rounded-lg` (modals), `rounded-full` (pills/avatars).

### Shadows / Elevation
```json
{
  "boxShadow": {
    "xs": "0 1px 2px 0 rgb(0 0 0 / 0.05)",
    "sm": "0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)",
    "DEFAULT": "0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)",
    "md": "0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)",
    "lg": "0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)",
    "xl": "0 25px 50px -12px rgb(0 0 0 / 0.25)"
  }
}
```

**Regla DSF-5**: Elevation semántica: `shadow-sm` (cards), `shadow-md` (dropdowns/popovers), `shadow-lg` (modals/drawers), `shadow-xl` (toasts/notifications).

### Motion / Animation
```json
{
  "transitionDuration": {
    "fast": "150ms",
    "DEFAULT": "200ms",
    "slow": "300ms"
  },
  "transitionTimingFunction": {
    "DEFAULT": "cubic-bezier(0.4, 0, 0.2, 1)",
    "in": "cubic-bezier(0.4, 0, 1, 1)",
    "out": "cubic-bezier(0, 0, 0.2, 1)",
    "in-out": "cubic-bezier(0.4, 0, 0.2, 1)"
  }
}
```

**Regla DSF-6**: Transiciones consistentes: `transition-colors duration-200` para hover, `transition-all duration-300` para layout changes. Respetar `prefers-reduced-motion`.

### Z-Index Scale
```json
{
  "zIndex": {
    "hide": "-1",
    "base": "0",
    "dropdown": "1000",
    "sticky": "1100",
    "fixed": "1200",
    "modal-backdrop": "1300",
    "modal": "1400",
    "popover": "1500",
    "tooltip": "1600",
    "toast": "1700"
  }
}
```

## Componentes Base Obligatorios (shadcn/ui + Radix)

| Componente | Radix Primitive | Variantes Requeridas | Estados Requeridos |
|------------|-----------------|---------------------|-------------------|
| Button | Slot + Primitive | default, outline, ghost, destructive, link | loading, disabled |
| Input | Primitive | default, error, success | disabled, readonly |
| Textarea | Primitive | default, error | disabled |
| Select | Select + Portal | default, error | disabled, loading |
| Checkbox | Checkbox | default | indeterminate, disabled |
| Radio Group | Radio Group | default | disabled |
| Switch | Switch | default | disabled |
| Label | Label | - | - |
| Card | Slot | default, outlined | loading, empty |
| Dialog | Dialog + Portal | default, alert | loading |
| Sheet | Sheet + Portal | default | - |
| Dropdown Menu | Dropdown Menu | default | loading, empty |
| Toast | Toast + Portal | default, success, error, warning | - |
| Tooltip | Tooltip | default | - |
| Avatar | Avatar | default, fallback | loading |
| Badge | Slot | default, outline, destructive | - |
| Separator | Separator | horizontal, vertical | - |
| Scroll Area | Scroll Area | default | - |
| Table | Slot | default, sortable, selectable | loading, empty, error |
| Tabs | Tabs | default | disabled |
| Accordion | Accordion | default, multiple | disabled |
| Popover | Popover + Portal | default | loading |
| Progress | Progress | default, indeterminate | - |
| Skeleton | - | text, circular, rectangular | - |

**Regla DSF-7**: Usar **solo** componentes de `~/components/ui/` (shadcn/ui). No importar `@radix-ui/*` directamente.

## Dark Mode Implementation

### CSS Variables (globals.css)
```css
:root {
  /* Light mode (default) */
  --background: 0 0% 100%;
  --foreground: 222.2 84% 4.9%;
  --primary: 221.2 83.2% 53.3%;
  --primary-foreground: 210 40% 98%;
  --secondary: 210 40% 96.1%;
  --secondary-foreground: 222.2 47.4% 11.2%;
  --muted: 210 40% 96.1%;
  --muted-foreground: 215.4 16.3% 46.9%;
  --accent: 210 40% 96.1%;
  --accent-foreground: 222.2 47.4% 11.2%;
  --destructive: 0 84.2% 60.2%;
  --destructive-foreground: 210 40% 98%;
  --border: 214.3 31.8% 91.4%;
  --input: 214.3 31.8% 91.4%;
  --ring: 221.2 83.2% 53.3%;
  --success: 142.1 76.2% 36.3%;
  --success-foreground: 355.7 100% 97.3%;
  --warning: 38 92% 50%;
  --warning-foreground: 48 96% 89%;
}

.dark {
  --background: 222.2 84% 4.9%;
  --foreground: 210 40% 98%;
  --primary: 217.2 91.2% 59.8%;
  --primary-foreground: 222.2 47.4% 11.2%;
  --secondary: 217.2 32.6% 17.5%;
  --secondary-foreground: 210 40% 98%;
  --muted: 217.2 32.6% 17.5%;
  --muted-foreground: 215 20.2% 65.1%;
  --accent: 217.2 32.6% 17.5%;
  --accent-foreground: 210 40% 98%;
  --destructive: 0 62.8% 30.6%;
  --destructive-foreground: 210 40% 98%;
  --border: 217.2 32.6% 17.5%;
  --input: 217.2 32.6% 17.5%;
  --ring: 224.3 76.3% 48%;
  --success: 142.1 70.6% 45.3%;
  --success-foreground: 144 100% 90%;
  --warning: 38 92% 50%;
  --warning-foreground: 48 96% 89%;
}
```

**Regla DSF-8**: Dark mode via `class="dark"` en `<html>` + `next-themes` / `useTheme`. **NUNCA** `bg-white`/`text-black` hardcodeado.

### Tailwind Config (tailwind.config.ts)
```typescript
import type { Config } from 'tailwindcss';

const config: Config = {
  darkMode: 'class',
  content: ['./src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        border: 'hsl(var(--border))',
        input: 'hsl(var(--input))',
        ring: 'hsl(var(--ring))',
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))',
        },
        destructive: {
          DEFAULT: 'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))',
        },
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))',
        },
        accent: {
          DEFAULT: 'hsl(var(--accent))',
          foreground: 'hsl(var(--accent-foreground))',
        },
        success: {
          DEFAULT: 'hsl(var(--success))',
          foreground: 'hsl(var(--success-foreground))',
        },
        warning: {
          DEFAULT: 'hsl(var(--warning))',
          foreground: 'hsl(var(--warning-foreground))',
        },
      },
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: 'calc(var(--radius) - 4px)',
      },
      fontFamily: {
        sans: ['var(--font-sans)', 'system-ui', 'sans-serif'],
        mono: ['var(--font-mono)', 'monospace'],
        display: ['var(--font-display)', 'system-ui', 'sans-serif'],
      },
      keyframes: {
        'accordion-down': { from: { height: '0' }, to: { height: 'var(--radix-accordion-content-height)' } },
        'accordion-up': { from: { height: 'var(--radix-accordion-content-height)' }, to: { height: '0' } },
      },
      animation: {
        'accordion-down': 'accordion-down 0.2s ease-out',
        'accordion-up': 'accordion-up 0.2s ease-out',
      },
    },
  },
  plugins: [require('tailwindcss-animate')],
};

export default config;
```

## Evitar Aspecto Genérico (Customización)

### Regla DSF-9: Personalización Mínima Obligatoria
1. **Brand color**: Cambiar `--primary` a color de marca (no azul por defecto)
2. **Border radius**: Ajustar `--radius` (ej: `0.5rem` para más redondo, `0.25rem` para más angular)
3. **Font**: Cargar fuente propia (`--font-sans`, `--font-display`) via `next/font` o `@font-face`
4. **Component variants**: Añadir variante `brand` a Button/Card si aplica
5. **Focus ring**: Personalizar `--ring` y `focus-visible:ring` para marca

### Ejemplo: Custom Theme
```css
:root {
  --radius: 0.5rem;  /* Más redondo que default 0.375rem */
  --primary: 262 83% 58%;  /* Purple brand */
  --primary-foreground: 0 0% 100%;
  --font-sans: 'Inter Variable', system-ui, sans-serif;
  --font-display: 'Cal Sans', 'Inter Variable', system-ui, sans-serif;
}

.dark {
  --primary: 262 83% 65%;  /* Lighter purple en dark */
}
```

## Verificación en Review
- **design-system-foundations DSF-1**: ¿Sin colores literales?
- **design-system-foundations DSF-2**: ¿Tipografía via tokens semánticos?
- **design-system-foundations DSF-3**: ¿Espaciado via escala 4px?
- **design-system-foundations DSF-4**: ¿Radius consistente por componente?
- **design-system-foundations DSF-5**: ¿Sombras semánticas (sm/md/lg/xl)?
- **design-system-foundations DSF-6**: ¿Transiciones consistentes + reduced motion?
- **design-system-foundations DSF-7**: ¿Solo componentes ~/components/ui/?
- **design-system-foundations DSF-8**: ¿Dark mode via class + CSS variables?
- **design-system-foundations DSF-9**: ¿Personalización marca (color, font, radius)?