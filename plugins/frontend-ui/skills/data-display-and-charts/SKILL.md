# Data Display and Charts Skill

## Cuándo usarlo
- **UI Implementer**: Implementa tablas, listas, gráficas, visualización de datos
- **UI Reviewer**: Verifica performance, accesibilidad, responsive de data display

## Cuándo NO usarlo
- Para lógica de fetching de datos (eso es TanStack Query / RxJS)
- Para formularios (eso es forms-and-validation)

## Descripción
Patterns para **visualización de datos**: Tablas (sortable, paginadas, virtualizadas), Gráficas (Recharts / Angular equivalentes), Listas virtualizadas, Skeletons, Empty states, Export/Print.

## Stack Principal: React + TanStack Query + Recharts

### 1. Tablas de Datos (TanStack Table v8)
```tsx
// components/data/DataTable.tsx
import { 
  useReactTable, 
  getCoreRowModel, 
  getSortedRowModel, 
  getPaginationRowModel,
  getFilteredRowModel,
  flexRender,
  createColumnHelper,
  SortingState,
  PaginationState,
} from '@tanstack/react-table';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { ChevronUp, ChevronDown, Loader2 } from 'lucide-react';

interface DataTableProps<T> {
  data: T[];
  columns: ColumnDef<T>[];
  isLoading?: boolean;
  pagination?: PaginationState;
  onPaginationChange?: (state: PaginationState) => void;
  sorting?: SortingState;
  onSortingChange?: (state: SortingState) => void;
  globalFilter?: string;
  onGlobalFilterChange?: (filter: string) => void;
  rowKey: keyof T | ((row: T) => string);
  emptyMessage?: string;
  className?: string;
}

export function DataTable<T>({
  data,
  columns,
  isLoading = false,
  pagination,
  onPaginationChange,
  sorting,
  onSortingChange,
  globalFilter,
  onGlobalFilterChange,
  rowKey,
  emptyMessage = 'No data available',
  className,
}: DataTableProps<T>) {
  const table = useReactTable({
    data,
    columns,
    state: { pagination, sorting, globalFilter },
    onPaginationChange,
    onSortingChange,
    onGlobalFilterChange,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
  });
  
  if (isLoading) {
    return (
      <div className="space-y-4">
        {Array.from({ length: 5 }).map((_, i) => (
          <div key={i} className="h-12 animate-pulse bg-muted rounded" />
        ))}
      </div>
    );
  }
  
  return (
    <div className={cn('w-full', className)}>
      {/* Global Filter */}
      <div className="mb-4">
        <Input
          placeholder="Search all columns..."
          value={globalFilter ?? ''}
          onChange={e => onGlobalFilterChange?.(e.target.value)}
          className="max-w-sm"
        />
      </div>
      
      {/* Table */}
      <div className="rounded-md border overflow-x-auto">
        <table className="w-full caption-bottom text-sm">
          <thead className="[&_tr]:border-b">
            {table.getHeaderGroups().map(headerGroup => (
              <tr key={headerGroup.id}>
                {headerGroup.headers.map(header => (
                  <th
                    key={header.id}
                    className="h-12 px-4 text-left align-middle font-medium text-muted-foreground [&:has([role=checkbox])]:pr-0"
                    {...header.getContext()}
                  >
                    {header.isPlaceholder ? null : flexRender(
                      header.column.columnDef.header,
                      header.getContext()
                    )}
                  </th>
                ))}
              </tr>
            ))}
          </thead>
          <tbody className="[&_tr:last-child]:border-0">
            {table.getRowModel().rows.length === 0 ? (
              <tr>
                <td className="h-16 text-center text-muted-foreground" colSpan={columns.length}>
                  {emptyMessage}
                </td>
              </tr>
            ) : (
              table.getRowModel().rows.map(row => (
                <tr key={row.id} className="border-b transition-colors hover:bg-muted/50 data-[state=selected]:bg-muted">
                  {row.getVisibleCells().map(cell => (
                    <td key={cell.id} className="p-4 align-middle">
                      {flexRender(cell.column.columnDef.cell, cell.getContext())}
                    </td>
                  ))}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
      
      {/* Pagination */}
      {pagination && (
        <div className="flex items-center justify-end space-x-2 py-4">
          <Button
            variant="outline"
            size="sm"
            onClick={() => onPaginationChange?.({ ...pagination, pageIndex: 0 })}
            disabled={pagination.pageIndex === 0}
          >
            <ChevronUp className="h-4 w-4" />
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={() => onPaginationChange?.({ ...pagination, pageIndex: pagination.pageIndex - 1 })}
            disabled={pagination.pageIndex === 0}
          >
            <ChevronDown className="h-4 w-4" />
          </Button>
          <span className="text-muted-foreground">
            Page {pagination.pageIndex + 1} of {table.getPageCount()}
          </span>
        </div>
      )}
    </div>
  );
}
```

### Column Definitions Helper
```tsx
// utils/columns.ts
import { ColumnDef } from '@tanstack/react-table';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { MoreHorizontal } from 'lucide-react';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem } from '@/components/ui/dropdown-menu';

const helper = createColumnHelper<User>();

export const userColumns: ColumnDef<User>[] = [
  helper.accessor('name', {
    header: 'Name',
    cell: info => <span className="font-medium">{info.getValue()}</span>,
  }),
  helper.accessor('email', {
    header: 'Email',
    cell: info => <a href={`mailto:${info.getValue()}`} className="text-primary hover:underline">{info.getValue()}</a>,
  }),
  helper.accessor('role', {
    header: 'Role',
    cell: info => (
      <Badge variant={info.getValue() === 'admin' ? 'default' : 'secondary'}>
        {info.getValue()}
      </Badge>
    ),
    filterFn: 'includesString',
  }),
  helper.accessor('status', {
    header: 'Status',
    cell: info => (
      <Badge variant={info.getValue() === 'active' ? 'success' : 'secondary'}>
        {info.getValue()}
      </Badge>
    ),
  }),
  helper.display({
    id: 'actions',
    header: 'Actions',
    cell: info => (
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="ghost" size="icon"><MoreHorizontal className="h-4 w-4" /></Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          <DropdownMenuItem onClick={() => editUser(info.row.original)}>Edit</DropdownMenuItem>
          <DropdownMenuItem onClick={() => viewUser(info.row.original)}>View</DropdownMenuItem>
          <DropdownMenuItem className="text-destructive" onClick={() => deleteUser(info.row.original.id)}>Delete</DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    ),
  }),
];
```

### 2. Virtualized Lists (TanStack Virtual)
```tsx
// components/data/VirtualList.tsx
import { useVirtualizer } from '@tanstack/react-virtual';
import { useRef, useMemo } from 'react';

interface VirtualListProps<T> {
  items: T[];
  estimateSize: number | ((index: number) => number);
  renderItem: (item: T, index: number) => React.ReactNode;
  height: number | string;
  overscan?: number;
  className?: string;
}

export function VirtualList<T>({ 
  items, 
  estimateSize, 
  renderItem, 
  height, 
  overscan = 5, 
  className 
}: VirtualListProps<T>) {
  const parentRef = useRef<HTMLDivElement>(null);
  
  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: typeof estimateSize === 'function' ? estimateSize : () => estimateSize,
    overscan,
    getItemKey: (index) => items[index]?.id?.toString() ?? index.toString(),
  });
  
  return (
    <div 
      ref={parentRef} 
      className={cn('relative overflow-auto', className)} 
      style={{ height }}
    >
      <div style={{ height: virtualizer.getTotalSize(), width: '100%', position: 'relative' }}>
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
            {renderItem(items[virtualRow.index], virtualRow.index)}
          </div>
        ))}
      </div>
    </div>
  );
}
```

### 3. Gráficas con Recharts
```tsx
// components/charts/LineChart.tsx
import { 
  LineChart, 
  Line, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  Legend 
} from 'recharts';
import { cn } from '@/lib/utils';

interface ChartDataPoint {
  date: string;
  value: number;
  [key: string]: any;
}

interface LineChartProps {
  data: ChartDataPoint[];
  xKey: string;
  yKey: string;
  title?: string;
  color?: string;
  height?: number;
  className?: string;
  formatX?: (value: string) => string;
  formatY?: (value: number) => string;
}

export function LineChartComponent({
  data,
  xKey,
  yKey,
  title,
  color = 'hsl(var(--primary))',
  height = 300,
  className,
  formatX,
  formatY,
}: LineChartProps) {
  if (!data.length) {
    return (
      <div className={cn('flex items-center justify-center h-[300px]', className)}>
        <p className="text-muted-foreground">No data available</p>
      </div>
    );
  }
  
  return (
    <div className={cn('w-full', className)}>
      {title && <h3 className="mb-4 text-lg font-medium">{title}</h3>}
      <ResponsiveContainer width="100%" height={height}>
        <LineChart data={data} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
          <XAxis 
            dataKey={xKey} 
            tickFormatter={formatX}
            stroke="hsl(var(--muted-foreground))"
            fontSize={12}
            interval="preserveStartEnd"
          />
          <YAxis 
            tickFormatter={formatY}
            stroke="hsl(var(--muted-foreground))"
            fontSize={12}
            width={60}
          />
          <Tooltip
            contentStyle={{
              backgroundColor: 'hsl(var(--background))',
              border: '1px solid hsl(var(--border))',
              borderRadius: 'var(--radius)',
              boxShadow: 'var(--shadow-md)',
            }}
            labelFormatter={formatX}
            formatter={(value: number) => [formatY ? formatY(value) : value.toLocaleString(), yKey]}
          />
          <Legend />
          <Line
            type="monotone"
            dataKey={yKey}
            stroke={color}
            strokeWidth={2}
            dot={false}
            activeDot={{ r: 6, strokeWidth: 2 }}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}
```

### Bar Chart / Area Chart / Pie Chart
```tsx
// BarChart
<BarChart data={data}>
  <CartesianGrid strokeDasharray="3 3" />
  <XAxis dataKey="name" />
  <YAxis />
  <Tooltip />
  <Bar dataKey="value" fill="hsl(var(--primary))" radius={[4, 4, 0, 0]} />
</BarChart>

// AreaChart (stacked)
<AreaChart data={data}>
  <defs>
    <linearGradient id="color-primary" x1="0" y1="0" x2="0" y2="1">
      <stop offset="5%" stopColor="hsl(var(--primary))" stopOpacity={0.3} />
      <stop offset="95%" stopColor="hsl(var(--primary))" stopOpacity={0} />
    </linearGradient>
  </defs>
  <XAxis dataKey="date" />
  <YAxis />
  <Tooltip />
  <Area type="monotone" dataKey="value" fill="url(#color-primary)" stroke="hsl(var(--primary))" />
</AreaChart>

// PieChart (donut)
<PieChart>
  <Pie
    data={data}
    cx="50%"
    cy="50%"
    innerRadius={60}
    outerRadius={80}
    fill="#8884d8"
    dataKey="value"
    nameKey="name"
    label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
  />
  <Tooltip formatter={v => v.toLocaleString()} />
  <Legend />
</PieChart>
```

### 4. Server-Side Data con TanStack Query
```tsx
// hooks/useUsers.ts
export function useUsers(filters: UserFilters) {
  return useQuery({
    queryKey: ['users', filters],
    queryFn: () => api.getUsers(filters),
    staleTime: 5 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
    placeholderData: (prev) => prev, // Keep previous data while fetching
  });
}

// En componente:
function UsersPage() {
  const [filters, setFilters] = useState<UserFilters>({ page: 1, limit: 20 });
  const { data, isLoading, error, isFetching } = useUsers(filters);
  
  const handlePageChange = (page: number) => setFilters(f => ({ ...f, page }));
  const handleSortChange = (sorting: SortingState) => setFilters(f => ({ ...f, sort: sorting }));
  
  return (
    <DataTable
      data={data?.items ?? []}
      columns={userColumns}
      isLoading={isLoading}
      pagination={data ? { pageIndex: data.page - 1, pageSize: data.limit } : undefined}
      onPaginationChange={pagination => handlePageChange(pagination.pageIndex + 1)}
      sorting={sorting}
      onSortingChange={handleSortChange}
    />
  );
}
```

### 5. Skeletons para Loading States
```tsx
// components/ui/skeleton.tsx
export function Skeleton({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn('animate-pulse rounded-md bg-muted', className)}
      {...props}
    />
  );
}

// Table Skeleton
export function TableSkeleton({ rows = 5, cols = 4 }) {
  return (
    <div className="space-y-3">
      <div className="grid gap-4">
        {Array.from({ length: cols }).map((_, i) => (
          <Skeleton key={i} className="h-10 w-full" />
        ))}
      </div>
      {Array.from({ length: rows }).map((_, i) => (
        <div key={i} className="grid gap-4">
          {Array.from({ length: cols }).map((_, j) => (
            <Skeleton key={j} className="h-12 w-full" />
          ))}
        </div>
      ))}
    </div>
  );
}

// Chart Skeleton
export function ChartSkeleton({ height = 300 }) {
  return (
    <Skeleton className="w-full" style={{ height }} />
  );
}
```

### 6. Export / Print
```tsx
// utils/export.ts
export function exportToCSV<T>(data: T[], filename: string, columns: { key: keyof T; header: string }[]) {
  const headers = columns.map(c => c.header).join(',');
  const rows = data.map(item => 
    columns.map(c => {
      const value = item[c.key];
      return typeof value === 'string' && value.includes(',') ? `"${value}"` : value;
    }).join(',')
  );
  const csv = [headers, ...rows].join('\n');
  downloadBlob(new Blob([csv], { type: 'text/csv;charset=utf-8;' }), `${filename}.csv`);
}

export function exportToJSON<T>(data: T[], filename: string) {
  downloadBlob(new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' }), `${filename}.json`);
}

function downloadBlob(blob: Blob, filename: string) {
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

// Print styles
// globals.css
@media print {
  .no-print { display: none !important; }
  .print-only { display: block !important; }
  table { page-break-inside: avoid; }
  tr { page-break-inside: avoid; }
}
```

## Stack Alterno: Angular

### PrimeNG Table / Angular Material Table
```typescript
// Angular Material Table con CDK Virtual Scroll
<table mat-table [dataSource]="dataSource" class="mat-elevation-z1">
  <ng-container matColumnDef="name">
    <th mat-header-cell *matHeaderCellDef> Name </th>
    <td mat-cell *matCellDef="let element"> {{element.name}} </td>
  </ng-container>
  <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
  <tr mat-row *matRowDef="let row; columns: displayedColumns;"></tr>
</table>

<mat-paginator [pageSizeOptions]="[10, 25, 50]" showFirstLastButtons></mat-paginator>

// Virtual Scroll
<cdk-virtual-scroll-viewport itemSize="50" class="h-[400px]">
  <mat-table [dataSource]="dataSource">
    ...
  </mat-table>
</cdk-virtual-scroll-viewport>
```

### ngx-charts / ng2-charts (Chart.js)
```typescript
// ng2-charts (Chart.js wrapper)
import { ChartConfiguration, ChartData } from 'chart.js';
import { BaseChartDirective } from 'ng2-charts';

@Component({
  standalone: true,
  imports: [BaseChartDirective],
  template: `<canvas baseChart [data]="chartData" [options]="chartOptions" [type]="'line'"></canvas>`
})
export class ChartComponent {
  chartData: ChartData<'line'> = {
    labels: ['Jan', 'Feb', 'Mar', 'Apr'],
    datasets: [{ data: [10, 20, 15, 30], label: 'Sales', borderColor: 'rgb(75, 192, 192)' }]
  };
  chartOptions: ChartConfiguration<'line'>['options'] = {
    responsive: true,
    plugins: { legend: { display: true } }
  };
}
```

## Verificación en Review
- **data-display-and-charts DDC-1**: ¿Tablas con TanStack Table (sort, filter, pagination, virtualización)?
- **data-display-and-charts DDC-2**: ¿Skeletons para loading states (table, chart, list)?
- **data-display-and-charts DDC-3**: ¿Gráficas Recharts responsive (ResponsiveContainer, Tooltip, Legend)?
- **data-display-and-charts DDC-4": ¿Virtualización para listas > 50 items (TanStack Virtual)?
- **data-display-and-charts DDC-5**: ¿Server-side pagination/sorting/filtering via TanStack Query?
- **data-display-and-charts DDC-6": ¿Export CSV/JSON functionality?
- **data-display-and-charts DDC-7": ¿Empty states con ilustración + CTA?
- **data-display-and-charts DDC-8": ¿Angular: Material Table + CDK Virtual Scroll / ng2-charts?