# Tailwind + shadcn/ui Stack Skill

## Cuándo usarlo
- **UI Implementer**: Configura y usa Tailwind + shadcn/ui correctamente
- **UI Reviewer**: Verifica config, tokens, dark mode, component usage

## Cuándo NO usarlo
- Para proyectos Angular (usa `angular-ui-patterns`)
- Para CSS-in-JS (styled-components, emotion) o CSS Modules puros

## Descripción
Configuración y uso obligatorio de **Tailwind CSS v3.4+** + **shadcn/ui** (basado en **Radix UI**) + **class-variance-authority (cva)** + **tailwind-merge** + **clsx**. Incluye tokens, dark mode, animaciones, y personalización de marca.

## Stack Versions (Verificar en package.json)
```json
{
  "dependencies": {
    "tailwindcss": "^3.4.0",
    "tailwind-merge": "^2.2.0",
    "clsx": "^2.1.0",
    "class-variance-authority": "^0.7.0",
    "tailwindcss-animate": "^1.0.7",
    "@radix-ui/react-slot": "^1.0.2",
    "@radix-ui/react-dialog": "^1.0.5",
    "@radix-ui/react-dropdown-menu": "^2.0.6",
    "@radix-ui/react-select": "^2.0.0",
    "@radix-ui/react-tabs": "^1.0.4",
    "@radix-ui/react-toast": "^1.1.5",
    "@radix-ui/react-tooltip": "^1.0.7",
    "lucide-react": "^0.344.0"
  },
  "devDependencies": {
    "autoprefixer": "^10.4.17",
    "postcss": "^8.4.35"
  }
}
```

## Tailwind Config Obligatorio (tailwind.config.ts)
```typescript
import type { Config } from 'tailwindcss';

const config: Config = {
  darkMode: 'class',
  content: [
    './src/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
  ],
  theme: {
    container: {
      center: true,
      padding: '2rem',
      screens: {
        '2xl': '1400px',
      },
    },
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
        'accordion-down': {
          from: { height: '0' },
          to: { height: 'var(--radix-accordion-content-height)' },
        },
        'accordion-up': {
          from: { height: 'var(--radix-accordion-content-height)' },
          to: { height: '0' },
        },
        'caret-blink': {
          '0%, 70%, 100%': { opacity: '1' },
          '20%, 50%': { opacity: '0' },
        },
      },
      animation: {
        'accordion-down': 'accordion-down 0.2s ease-out',
        'accordion-up': 'accordion-up 0.2s ease-out',
        'caret-blink': 'caret-blink 1.25s ease-out infinite',
      },
    },
  },
  plugins: [require('tailwindcss-animate')],
};

export default config;
```

## CSS Variables (src/app/globals.css o src/index.css)
```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --card: 0 0% 100%;
    --card-foreground: 222.2 84% 4.9%;
    --popover: 0 0% 100%;
    --popover-foreground: 222.2 84% 4.9%;
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
    --radius: 0.5rem;
    --success: 142.1 76.2% 36.3%;
    --success-foreground: 355.7 100% 97.3%;
    --warning: 38 92% 50%;
    --warning-foreground: 48 96% 89%;
  }

  .dark {
    --background: 222.2 84% 4.9%;
    --foreground: 210 40% 98%;
    --card: 222.2 84% 4.9%;
    --card-foreground: 210 40% 98%;
    --popover: 222.2 84% 4.9%;
    --popover-foreground: 210 40% 98%;
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
}

@layer base {
  * {
    @apply border-border;
  }
  body {
    @apply bg-background text-foreground;
    font-feature-settings: "rlig" 1, "calt" 1;
  }
  :focus-visible {
    @apply outline-none ring-2 ring-ring ring-offset-2 ring-offset-background;
  }
}
```

## cn() Utility (src/lib/utils.ts)
```typescript
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

## shadcn/ui Components (src/components/ui/)
Estructura obligatoria - **NO modificar internals de Radix**, solo extender via props:

```tsx
// button.tsx - Ejemplo patrón base
import * as React from 'react';
import { Slot } from '@radix-ui/react-slot';
import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '@/lib/utils';

const buttonVariants = cva(
  'inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50',
  {
    variants: {
      variant: {
        default: 'bg-primary text-primary-foreground hover:bg-primary/90',
        destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/90',
        outline: 'border border-input bg-background hover:bg-accent hover:text-accent-foreground',
        secondary: 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
        ghost: 'hover:bg-accent hover:text-accent-foreground',
        link: 'text-primary underline-offset-4 hover:underline',
      },
      size: {
        default: 'h-10 px-4 py-2',
        sm: 'h-9 rounded-md px-3',
        lg: 'h-11 rounded-md px-8',
        icon: 'h-10 w-10',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'default',
    },
  }
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean;
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : 'button';
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    );
  }
);
Button.displayName = 'Button';

export { Button, buttonVariants };
```

## Dark Mode Implementation
```tsx
// ThemeProvider.tsx (Next.js 13+ app router)
'use client';

import * as React from 'react';
import { ThemeProvider as NextThemesProvider } from 'next-themes';

export function ThemeProvider({
  children,
  ...props
}: React.ComponentProps<typeof NextThemesProvider>) {
  return <NextThemesProvider {...props}>{children}</NextThemesProvider>;
}

// Uso en layout.tsx:
<ThemeProvider attribute="class" defaultTheme="system" enableSystem>
  {children}
</ThemeProvider>
```

## Animaciones (tailwindcss-animate)
```tsx
// Disponibles via plugin:
// animate-in, animate-out, fade-in, fade-out, zoom-in, zoom-out, slide-in-from-*, slide-out-to-*
// Duraciones: duration-200, duration-300, duration-500
// Easing: ease-in, ease-out, ease-in-out

<DialogContent className="animate-in fade-in zoom-in-95 duration-200">
  <DialogTitle>Title</DialogTitle>
</DialogContent>

<DropdownMenuContent className="animate-in fade-in-0 zoom-in-95 duration-100">
  {/* ... */}
</DropdownMenuContent>
```

## Personalización de Marca (Obligatorio Mínimo)
```css
/* globals.css - Override mínimo */
:root {
  --radius: 0.5rem;           /* Ajustar redondeo */
  --primary: 262 83% 58%;     /* Color marca (ej: purple) */
  --primary-foreground: 0 0% 100%;
}

.dark {
  --primary: 262 83% 65%;     /* Versión clara para dark */
}
```

```typescript
// tailwind.config.ts - Font personalizada
fontFamily: {
  sans: ['var(--font-sans)', 'system-ui', 'sans-serif'],
  mono: ['var(--font-mono)', 'monospace'],
  display: ['var(--font-display)', 'system-ui', 'sans-serif'],
},
```

```tsx
// layout.tsx - Cargar fuentes (Next.js 13+)
import { Inter, Cal_Sans } from 'next/font/google';

const sans = Inter({ subsets: ['latin'], variable: '--font-sans' });
const display = Cal_Sans({ subsets: ['latin'], variable: '--font-display' });

<body className={`${sans.variable} ${display.variable} font-sans antialiased`}>
```

## Patrones de Uso Comunes

### Responsive Container
```tsx
<div className="container mx-auto px-4 sm:px-6 lg:px-8">
  {/* Content */}
</div>
```

### Card Grid Responsive
```tsx
<div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
  {items.map(item => <Card key={item.id}>...</Card>)}
</div>
```

### Form Layout
```tsx
<form className="space-y-6">
  <div className="grid gap-4 sm:grid-cols-2">
    <FormField name="firstName" />
    <FormField name="lastName" />
  </div>
  <FormField name="email" className="sm:col-span-2" />
</form>
```

## Verificación en Review
- **tailwind-shadcn-stack TSS-1**: ¿tailwind.config.ts con darkMode: 'class', CSS variables, animate plugin?
- **tailwind-shadcn-stack TSS-2**: ¿globals.css con @layer base, CSS variables light/dark, focus-visible?
- **tailwind-shadcn-stack TSS-3**: ¿cn() utility con clsx + tailwind-merge?
- **tailwind-shadcn-stack TSS-4**: ¿Componentes en ~/components/ui/ extendiendo Radix via cva + Slot?
- **tailwind-shadcn-stack TSS-5**: ¿ThemeProvider (next-themes) con attribute="class"?
- **tailwind-shadcn-stack TSS-6**: ¿Animaciones via tailwindcss-animate (animate-in/out, fade, zoom, slide)?
- **tailwind-shadcn-stack TSS-7**: ¿Personalización marca: --radius, --primary, --font-sans/display?
- **tailwind-shadcn-stack TSS-8**: ¿NO colores literales, NO valores arbitrarios en componentes?