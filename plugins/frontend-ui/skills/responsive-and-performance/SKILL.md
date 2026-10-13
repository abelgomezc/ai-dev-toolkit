# Responsive and Performance Skill

## Cuándo usarlo
- **UI Designer**: Define breakpoints, mobile-first strategy, performance budgets
- **UI Implementer**: Implementa responsive, lazy load, code splitting, bundle optimization
- **UI Reviewer**: Verifica `responsive-and-performance` reglas (R10-R16, R29-R34)

## Cuándo NO usarlo
- Para optimización de backend/API (eso es api-design-review)
- Para optimización de base de datos (eso es db-migration-review)

## Descripción
Patterns para **diseño responsive mobile-first**, **breakpoints**, **lazy loading**, **code splitting**, **bundle size optimization**, **imágenes optimizadas**, **Core Web Vitals**, **virtualización**.

## Responsive Design

### Breakpoints Estándar (Tailwind Default)
```typescript
// tailwind.config.ts - Breakpoints mobile-first
const screens = {
  sm: '640px',   // Mobile landscape / small tablet
  md: '768px',   // Tablet portrait
  lg: '1024px',  // Tablet landscape / small desktop
  xl: '1280px',  // Desktop
  '2xl': '1536px', // Large desktop
};
```

### Mobile-First Patterns
```tsx
// BUENO - Base styles mobile, progressive enhancement
<div className="
  grid 
  grid-cols-1           // Mobile: 1 columna
  sm:grid-cols-2        // ≥640px: 2 columnas
  lg:grid-cols-3        // ≥1024px: 3 columnas
  xl:grid-cols-4        // ≥1280px: 4 columnas
  gap-4                 // Mobile gap
  sm:gap-6              // ≥640px: gap mayor
  p-4                   // Mobile padding
  md:p-6                // ≥768px: padding mayor
">
  {items.map(item => <Card key={item.id} />)}
</div>

// Container responsive
<div className="container mx-auto px-4 sm:px-6 lg:px-8">
  {/* Content centrado, padding responsive */}
</div>

// Tipografía fluid (clamp)
<h1 className="text-heading-1">  // clamp(2rem, 5vw, 3rem)
<h2 className="text-heading-2">  // clamp(1.5rem, 3vw, 2.25rem)
<p className="text-body">        // 1rem base, line-height 1.6

// Touch targets ≥ 44×44px
<button className="min-h-[44px] min-w-[44px] flex items-center justify-center">
  <Icon className="h-5 w-5" />
</button>

// NO horizontal scroll en móvil
<div className="overflow-x-hidden">
  <table className="w-full min-w-[600px]"> {/* Tabla ancha en móvil requiere scroll horizontal interno */}
</div>

// Viewport meta tag (obligatorio en index.html)
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
```

### Stack Order Lógico (Mobile)
```tsx
// Stack order: Header → Main → Sidebar → Footer
<div className="flex flex-col min-h-screen">
  <Header className="sticky top-0 z-40" />           // Siempre visible
  <main className="flex-1" id="main-content">       // Contenido principal
    <Sidebar className="hidden lg:block" />         // Sidebar solo desktop
    <Content />                                      // Contenido
  </main>
  <Footer />                                         // Footer
</div>

// Mobile drawer para sidebar
<Sheet>
  <SheetTrigger asChild>
    <Button variant="outline" className="lg:hidden">
      <Menu className="h-6 w-6" />
    </Button>
  </SheetTrigger>
  <SheetContent side="left" className="w-64">
    <Sidebar />
  </SheetContent>
</Sheet>
```

### Imágenes Responsive
```tsx
// Next.js Image (recomendado)
import Image from 'next/image';

<Image
  src="/hero.jpg"
  alt="Dashboard preview"
  fill
  priority              // Above fold
  sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
  className="object-cover"
/>

// Picture element (manual)
<picture>
  <source media="(max-width: 640px)" srcSet="/hero-mobile.webp" type="image/webp" />
  <source media="(max-width: 1024px)" srcSet="/hero-tablet.webp" type="image/webp" />
  <source srcSet="/hero-desktop.webp" type="image/webp" />
  <img src="/hero.jpg" alt="Hero" loading="lazy" width="1200" height="600" />
</picture>

// Loading lazy (below fold)
<Image
  src="/chart.png"
  alt="Chart"
  loading="lazy"
  placeholder="blur"
  blurDataURL="data:image/png;base64,..."
/>
```

## Performance

### Code Splitting + Lazy Loading
```tsx
// React.lazy + Suspense (Rutas)
const Dashboard = lazy(() => import('@/pages/Dashboard'));
const Users = lazy(() => import('@/pages/Users'));

function App() {
  return (
    <Suspense fallback={<PageSkeleton />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/users" element={<Users />} />
      </Routes>
    </Suspense>
  );
}

// Component-level lazy (widgets pesados)
const HeavyChart = lazy(() => import('@/components/charts/HeavyChart').then(m => ({ default: m.HeavyChart })));

function Dashboard() {
  return (
    <Suspense fallback={<ChartSkeleton />}>
      <HeavyChart data={data} />
    </Suspense>
  );
}

// Dynamic import para librerías pesadas
async function exportToPDF() {
  const { PDFDocument } = await import('pdf-lib');  // Solo carga al click
  // ...
}
```

### Bundle Analysis
```bash
# Analizar bundle
# Next.js
npm run build && npx @next/bundle-analyzer

# Vite
npm run build && npx vite-bundle-analyzer

# Webpack
npm run build && npx webpack-bundle-analyzer dist/stats.json
```

```javascript
// next.config.js - Bundle analyzer
const withBundleAnalyzer = require('@next/bundle-analyzer')({
  enabled: process.env.ANALYZE === 'true',
});

module.exports = withBundleAnalyzer({
  // ...
  experimental: {
    optimizePackageImports: ['lucide-react', '@radix-ui/react-icons'],
  },
});
```

### Bundle Budget (CI)
```yaml
# .github/workflows/bundle.yml
jobs:
  bundle-size:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci && npm run build
      - name: Check bundle size
        run: |
          # Next.js
          BUNDLE_SIZE=$(du -sh .next/static/chunks/*.js | awk '{sum+=$1} END {print sum}')
          if [ $BUNDLE_SIZE -gt 500 ]; then
            echo "Bundle too large: ${BUNDLE_SIZE}KB > 500KB"
            exit 1
          fi
```

### Optimizaciones de Imágenes
```typescript
// next.config.js
module.exports = {
  images: {
    formats: ['image/avif', 'image/webp'],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
    minimumCacheTTL: 31536000, // 1 año
    dangerouslyAllowSVG: true,
    contentSecurityPolicy: "default-src 'self'; script-src 'none'; sandbox;",
  },
};
```

### TanStack Query Optimization
```tsx
// hooks/useUsers.ts
export function useUsers(filters: UserFilters) {
  return useQuery({
    queryKey: ['users', filters],
    queryFn: () => api.getUsers(filters),
    staleTime: 5 * 60 * 1000,      // 5 min - no refetch si fresh
    gcTime: 10 * 60 * 1000,        // 10 min - cache garbage collection
    placeholderData: (prev) => prev, // Keep previous data while fetching
    refetchOnWindowFocus: false,   // Evita refetch agresivo
    refetchOnReconnect: false,
  });
}

// Prefetching
function usePrefetchUsers() {
  const queryClient = useQueryClient();
  return () => queryClient.prefetchQuery({
    queryKey: ['users', { page: 1 }],
    queryFn: () => api.getUsers({ page: 1 }),
    staleTime: 5 * 60 * 1000,
  });
}
```

### Memoización Correcta
```tsx
// React.memo para componentes puros
const UserRow = memo(function UserRow({ user, onAction }: { user: User; onAction: (id: string) => void }) {
  return (
    <tr onClick={() => onAction(user.id)}>
      <td>{user.name}</td>
      <td>{user.email}</td>
    </tr>
  );
});

// useMemo para computaciones derivadas
function UserList({ users, filter }: { users: User[]; filter: string }) {
  const filteredUsers = useMemo(
    () => users.filter(u => u.name.toLowerCase().includes(filter.toLowerCase())),
    [users, filter]
  );
  
  // useCallback para callbacks estables
  const handleAction = useCallback((id: string) => {
    // ...
  }, [/* deps */]);
  
  return <Table data={filteredUsers} onAction={handleAction} />;
}

// Evitar: new object/array en render
// MALO
<Component style={{ margin: 10 }} data={['a', 'b']} />

// BUENO
const style = useMemo(() => ({ margin: 10 }), []);
const data = useMemo(() => ['a', 'b'], []);
<Component style={style} data={data} />
```

### Virtualización (Listas > 50 items)
```tsx
import { useVirtualizer } from '@tanstack/react-virtual';

function VirtualUserList({ users }: { users: User[] }) {
  const parentRef = useRef<HTMLDivElement>(null);
  
  const virtualizer = useVirtualizer({
    count: users.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 60,
    overscan: 5,
  });
  
  return (
    <div ref={parentRef} className="h-[400px] overflow-auto border rounded">
      <div style={{ height: virtualizer.getTotalSize(), width: '100%' }}>
        {virtualizer.getVirtualItems().map(virtualRow => (
          <div
            key={virtualRow.key}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              height: `${virtualRow.size}px`,
              transform: `translateY(${virtualRow.start}px)`,
            }}
          >
            <UserRow user={users[virtualRow.index]} />
          </div>
        ))}
      </div>
    </div>
  );
}
```

### Core Web Vitals Targets
| Métrica | Good | Needs Improvement | Poor |
|---------|------|-------------------|------|
| **LCP** (Largest Contentful Paint) | ≤ 2.5s | ≤ 4s | > 4s |
| **FID** (First Input Delay) | ≤ 100ms | ≤ 300ms | > 300ms |
| **CLS** (Cumulative Layout Shift) | ≤ 0.1 | ≤ 0.25 | > 0.25 |
| **FCP** (First Contentful Paint) | ≤ 1.8s | ≤ 3s | > 3s |
| **TTFB** (Time to First Byte) | ≤ 800ms | ≤ 1.8s | > 1.8s |

### Reduced Motion
```css
/* globals.css */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

```tsx
// Respeta reduced motion en componentes
function AnimatedComponent({ children }: { children: React.ReactNode }) {
  const prefersReducedMotion = useMediaQuery('(prefers-reduced-motion: reduce)');
  
  return (
    <motion.div
      animate={prefersReducedMotion ? {} : { x: [0, 100] }}
      transition={{ duration: prefersReducedMotion ? 0 : 0.5 }}
    >
      {children}
    </motion.div>
  );
}
```

## Stack Alterno: Angular

### OnPush + Signals + Lazy Loading
```typescript
// OnPush obligatorio
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  ...
})
export class UserListComponent { }

// Lazy loading routes
const routes: Routes = [
  { path: 'dashboard', loadComponent: () => import('./dashboard/dashboard.component').then(m => m.DashboardComponent) },
];

// Preloading
provideRouter(routes, withPreloading(PreloadAllModules));
```

### Virtual Scroll CDK
```html
<cdk-virtual-scroll-viewport itemSize="50" class="h-[400px]">
  <mat-table [dataSource]="dataSource">
    ...
  </mat-table>
</cdk-virtual-scroll-viewport>
```

### Performance Budgets (angular.json)
```json
{
  "projects": {
    "my-app": {
      "architect": {
        "build": {
          "options": {
            "budgets": [
              { "type": "initial", "maximumWarning": "500kb", "maximumError": "1mb" },
              { "type": "anyComponentStyle", "maximumWarning": "2kb", "maximumError": "4kb" },
              { "type": "allScript", "maximumWarning": "500kb", "maximumError": "1mb" }
            ]
          }
        }
      }
    }
  }
}
```

## Verificación en Review
- **responsive-and-performance RAP-1": ¿Mobile-first: base styles + sm/md/lg/xl/2xl progressive?
- **responsive-and-performance RAP-2": ¿Breakpoints estándar (640/768/1024/1280/1536)?
- **responsive-and-performance RAP-3": ¿Touch targets ≥ 44×44px?
- **responsive-and-performance RAP-4": ¿Viewport meta tag + no horizontal scroll móvil?
- **responsive-and-performance RAP-5": ¿Stack order lógico mobile (header→main→sidebar→footer)?
- **responsive-and-performance RAP-6": ¿Imágenes responsive (srcset/sizes/loading=lazy/Next Image)?
- **responsive-and-performance RAP-7": ¿Code splitting rutas + componentes pesados (React.lazy/Suspense)?
- **responsive-and-performance RAP-8": ¿Bundle analysis en CI (budget < 500KB gzipped inicial)?
- **responsive-and-performance RAP-9": ¿Imágenes optimizadas (AVIF/WebP, srcset, lazy, blur placeholder)?
- **responsive-and-performance RAP-10": ¿TanStack Query staleTime/gcTime/prefetching configurado?
- **responsive-and-performance RAP-11": ¿Memo/useMemo/useCallback para estabilidad referencial?
- **responsive-and-performance RAP-12": ¿Virtualización listas > 50 items (TanStack Virtual / CDK)?
- **responsive-and-performance RAP-13": ¿Core Web Vitals targets (LCP≤2.5s, FID≤100ms, CLS≤0.1)?
- **responsive-and-performance RAP-14": ¿Reduced motion respetado (@media prefers-reduced-motion)?