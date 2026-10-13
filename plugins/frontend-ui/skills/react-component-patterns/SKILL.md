# React Component Patterns Skill

## Cuándo usarlo
- **UI Implementer**: Implementa componentes React siguiendo estos patterns obligatorios
- **UI Reviewer**: Verifica patterns correctos (forwardRef, composition, TypeScript)

## Cuándo NO usarlo
- Para componentes Angular (usa `angular-ui-patterns`)
- Para lógica de negocio (hooks personalizados, services)

## Descripción
Patterns obligatorios para componentes React 18 + TypeScript: composition, forwardRef, compound components, controlled/uncontrolled, TypeScript strict, performance.

## Patterns Obligatorios

### 1. ForwardRef + Composition (Patrón Base)
```tsx
// BUENO - forwardRef + displayName + cn() + className passthrough
import { forwardRef, type HTMLAttributes } from 'react';
import { cn } from '@/lib/utils';

export interface ButtonProps extends HTMLAttributes<HTMLButtonElement> {
  variant?: 'default' | 'outline' | 'ghost' | 'destructive' | 'link';
  size?: 'sm' | 'md' | 'lg' | 'icon';
  asChild?: boolean;
}

const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'default', size = 'md', asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : 'button';
    return (
      <Comp
        ref={ref}
        className={cn(buttonVariants({ variant, size }), className)}
        {...props}
      />
    );
  }
);
Button.displayName = 'Button';

// MALO - sin forwardRef, sin composition
const Button = ({ className, ...props }) => (
  <button className={className} {...props} />
);
```

### 2. Slot Pattern (Radix asChild)
```tsx
// BUENO - Permite composición con cualquier elemento
import { Slot } from '@radix-ui/react-slot';

<Button asChild>
  <a href="/login">Login</a>
</Button>

// Renderiza: <a className="..." href="/login">Login</a>
```

### 3. Compound Components (State compartido implícito)
```tsx
// BUENO - Context para estado compartido
const TabsContext = createContext<TabsContextValue | null>(null);

function Tabs({ children, defaultValue, onValueChange, ...props }) {
  const [value, setValue] = useState(defaultValue);
  return (
    <TabsContext.Provider value={{ value, onValueChange: setValue }}>
      <div {...props}>{children}</div>
    </TabsContext.Provider>
  );
}

function TabsList({ children, ...props }) {
  return <div role="tablist" {...props}>{children}</div>;
}

function TabsTrigger({ value, children, ...props }) {
  const context = useContext(TabsContext);
  const isActive = context?.value === value;
  return (
    <button
      role="tab"
      aria-selected={isActive}
      aria-controls={`panel-${value}`}
      id={`tab-${value}`}
      {...props}
    >
      {children}
    </button>
  );
}

function TabsContent({ value, children, ...props }) {
  const context = useContext(TabsContext);
  const isActive = context?.value === value;
  return (
    <div
      role="tabpanel"
      id={`panel-${value}`}
      aria-labelledby={`tab-${value}`}
      hidden={!isActive}
      {...props}
    >
      {children}
    </div>
  );
}

Tabs.List = TabsList;
Tabs.Trigger = TabsTrigger;
Tabs.Content = TabsContent;

// Uso:
<Tabs defaultValue="profile">
  <Tabs.List>
    <Tabs.Trigger value="profile">Profile</Tabs.Trigger>
    <Tabs.Trigger value="settings">Settings</Tabs.Trigger>
  </Tabs.List>
  <Tabs.Content value="profile">...</Tabs.Content>
  <Tabs.Content value="settings">...</Tabs.Content>
</Tabs>
```

### 4. Controlled + Uncontrolled Pattern
```tsx
// BUENO - Soporta ambos modos
interface SelectProps<T> {
  value?: T;           // Controlled
  defaultValue?: T;    // Uncontrolled
  onValueChange?: (value: T) => void;
  options: Option<T>[];
}

function Select<T>({ value, defaultValue, onValueChange, options }: SelectProps<T>) {
  const isControlled = value !== undefined;
  const [uncontrolledValue, setUncontrolledValue] = useState(defaultValue);
  
  const currentValue = isControlled ? value : uncontrolledValue;
  
  const handleChange = (newValue: T) => {
    if (!isControlled) setUncontrolledValue(newValue);
    onValueChange?.(newValue);
  };
  
  return (
    // ... render
  );
}
```

### 5. TypeScript Strict Patterns
```tsx
// BUENO - Discriminated unions para variantes
type ButtonVariant = 
  | { variant: 'default'; background: 'primary' }
  | { variant: 'outline'; border: 'border' }
  | { variant: 'ghost'; background: 'transparent' };

// BUENO - Exact types para props
interface ExactProps {
  readonly required: string;
  readonly optional?: number;
  readonly neverExtra?: never;  // Previene props extra
}

// BUENO - Generic components con constraints
function List<T extends { id: string; label: string }>({ 
  items, 
  renderItem 
}: { 
  items: T[]; 
  renderItem: (item: T) => React.ReactNode 
}) { }

// MALO - any, loose types
function BadComponent(props: any) { }
function LooseComponent({ data }: { data: any }) { }
```

### 6. Render Props / Children as Function (para lógica reutilizable)
```tsx
// BUENO - Para lógica de datos/comportamiento
function DataFetcher<T>({ 
  queryKey, 
  queryFn, 
  children 
}: { 
  queryKey: QueryKey; 
  queryFn: () => Promise<T>; 
  children: (data: T | undefined, isLoading: boolean, error: Error | null) => React.ReactNode 
}) {
  const { data, isLoading, error } = useQuery({ queryKey, queryFn });
  return <>{children(data, isLoading, error)}</>;
}

// Uso:
<DataFetcher queryKey={['user', id]} queryFn={() => api.getUser(id)}>
  {(user, loading, error) => loading ? <Skeleton /> : error ? <Error /> : <Profile user={user} />}
</DataFetcher>
```

### 7. Custom Hooks para Lógica de UI
```tsx
// BUENO - Separación lógica/UI
function useToggle(initial = false) {
  const [state, setState] = useState(initial);
  const toggle = useCallback(() => setState(v => !v), []);
  return [state, toggle] as const;
}

function useMediaQuery(query: string) {
  const [matches, setMatches] = useState(false);
  useEffect(() => {
    const media = window.matchMedia(query);
    if (media.matches !== matches) setMatches(media.matches);
    const listener = (e: MediaQueryListEvent) => setMatches(e.matches);
    media.addEventListener('change', listener);
    return () => media.removeEventListener('change', listener);
  }, [matches, query]);
  return matches;
}
```

### 8. Performance Patterns
```tsx
// BUENO - Memoización correcta
const ExpensiveComponent = memo(function ExpensiveComponent({ 
  data, 
  onAction 
}: { 
  data: Data[]; 
  onAction: (id: string) => void 
}) {
  // useMemo para computaciones derivadas
  const sortedData = useMemo(
    () => data.slice().sort((a, b) => a.name.localeCompare(b.name)),
    [data]
  );
  
  // useCallback para callbacks estables
  const handleAction = useCallback((id: string) => {
    onAction(id);
  }, [onAction]);
  
  return (
    <ul>
      {sortedData.map(item => (
        <li key={item.id} onClick={() => handleAction(item.id)}>
          {item.name}
        </li>
      ))}
    </ul>
  );
});

// BUENO - Virtualización para listas grandes
import { useVirtualizer } from '@tanstack/react-virtual';

function VirtualList({ items }: { items: Item[] }) {
  const parentRef = useRef<HTMLDivElement>(null);
  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 50,
    overscan: 5,
  });
  
  return (
    <div ref={parentRef} className="h-[400px] overflow-auto">
      <div style={{ height: virtualizer.getTotalSize() }}>
        {virtualizer.getVirtualItems().map(virtualItem => (
          <div
            key={virtualItem.key}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              height: `${virtualItem.size}px`,
              transform: `translateY(${virtualItem.start}px)`,
            }}
          >
            {items[virtualItem.index].name}
          </div>
        ))}
      </div>
    </div>
  );
}
```

### 9. Error Boundaries
```tsx
// BUENO - Class component para error boundary (único caso válido)
class ErrorBoundary extends Component<
  { children: ReactNode; fallback?: ReactNode },
  { hasError: boolean; error: Error | null }
> {
  state = { hasError: false, error: null };
  
  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error };
  }
  
  componentDidCatch(error: Error, info: ErrorInfo) {
    logError(error, info);
  }
  
  render() {
    if (this.state.hasError) {
      return this.props.fallback || <DefaultErrorFallback error={this.state.error} />;
    }
    return this.props.children;
  }
}
```

### 10. Form Integration (RHF + Zod)
```tsx
// BUENO - Form wrapper tipado
const formSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

type FormData = z.infer<typeof formSchema>;

function LoginForm() {
  const form = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues: { email: '', password: '' },
  });
  
  const onSubmit = form.handleSubmit(async (data) => {
    await api.login(data);
  });
  
  return (
    <form onSubmit={onSubmit}>
      <FormField
        control={form.control}
        name="email"
        render={({ field }) => (
          <FormItem>
            <FormLabel>Email</FormLabel>
            <FormControl>
              <Input placeholder="email@example.com" {...field} />
            </FormControl>
            <FormMessage />
          </FormItem>
        )}
      />
      {/* ... */}
    </form>
  );
}
```

## Verificación en Review
- **react-component-patterns RCP-1**: ¿forwardRef + displayName + cn() + className passthrough?
- **react-component-patterns RCP-2**: ¿Slot pattern para composición?
- **react-component-patterns RCP-3**: ¿Compound components con Context?
- **react-component-patterns RCP-4**: ¿Controlled + Uncontrolled support?
- **react-component-patterns RCP-5**: ¿TypeScript strict (discriminated unions, exact types, generics)?
- **react-component-patterns RCP-6**: ¿Render props para lógica reutilizable?
- **react-component-patterns RCP-7**: ¿Custom hooks para lógica UI?
- **react-component-patterns RCP-8**: ¿Memo, useMemo, useCallback, virtualización?
- **react-component-patterns RCP-9**: ¿Error Boundary class component?
- **react-component-patterns RCP-10**: ¿Form wrapper RHF + Zod tipado?