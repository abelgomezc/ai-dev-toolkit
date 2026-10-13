# Forms and Validation Skill

## Cuándo usarlo
- **UI Implementer**: Implementa formularios con patterns obligatorios
- **UI Reviewer**: Verifica validación, accesibilidad, UX de formularios

## Cuándo NO usarlo
- Para validación de backend/API (eso es api-design-review)
- Para validación de base de datos (eso es db-migration-review)

## Descripción
Patterns obligatorios para formularios: **React Hook Form + Zod** (React) / **Reactive Forms + Validators** (Angular). Validación on blur + on submit, errores inline asociados via ARIA, submit loading/disabled, autocomplete attributes.

## Stack Principal: React Hook Form + Zod

### Schema Zod (Single Source of Truth)
```typescript
// schemas/user.ts
import { z } from 'zod';

export const userCreateSchema = z.object({
  email: z.string().min(1, 'Email is required').email('Invalid email format'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  confirmPassword: z.string(),
  fullName: z.string().min(1, 'Name is required').max(100, 'Name too long'),
  role: z.enum(['admin', 'user', 'viewer'], { required_error: 'Role is required' }),
  acceptTerms: z.boolean().refine(v => v === true, 'You must accept terms'),
}).refine(data => data.password === data.confirmPassword, {
  message: 'Passwords do not match',
  path: ['confirmPassword'],
});

export type UserCreateFormData = z.infer<typeof userCreateSchema>;
```

### Form Component Pattern
```tsx
// components/forms/UserForm.tsx
'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { userCreateSchema, type UserCreateFormData } from '@/schemas/user';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Checkbox } from '@/components/ui/checkbox';
import { Label } from '@/components/ui/label';
import { Form, FormField, FormItem, FormLabel, FormControl, FormMessage } from '@/components/ui/form';

interface UserFormProps {
  onSubmit: (data: UserCreateFormData) => Promise<void>;
  defaultValues?: Partial<UserCreateFormData>;
  submitLabel?: string;
}

export function UserForm({ onSubmit, defaultValues, submitLabel = 'Create User' }: UserFormProps) {
  const form = useForm<UserCreateFormData>({
    resolver: zodResolver(userCreateSchema),
    defaultValues: {
      email: '',
      password: '',
      confirmPassword: '',
      fullName: '',
      role: 'user',
      acceptTerms: false,
      ...defaultValues,
    },
    mode: 'onBlur', // Validar on blur + on submit
  });
  
  const isSubmitting = form.formState.isSubmitting;
  const isDirty = form.formState.isDirty;
  const isValid = form.formState.isValid;
  
  const handleSubmit = form.handleSubmit(async (data) => {
    try {
      await onSubmit(data);
    } catch (error) {
      // Error handling via toast/notification
      console.error('Submit failed:', error);
    }
  });
  
  return (
    <Form {...form}>
      <form onSubmit={handleSubmit} className="space-y-6" noValidate>
        {/* Email */}
        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Email</FormLabel>
              <FormControl>
                <Input
                  placeholder="user@example.com"
                  type="email"
                  autoComplete="email"
                  aria-describedby={form.formState.errors.email ? 'email-error' : undefined}
                  {...field}
                />
              </FormControl>
              <FormMessage id="email-error" />
            </FormItem>
          )}
        />
        
        {/* Password */}
        <FormField
          control={form.control}
          name="password"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Password</FormLabel>
              <FormControl>
                <Input
                  type="password"
                  autoComplete="new-password"
                  aria-describedby={form.formState.errors.password ? 'password-error' : undefined}
                  {...field}
                />
              </FormControl>
              <FormMessage id="password-error" />
            </FormItem>
          )}
        />
        
        {/* Confirm Password */}
        <FormField
          control={form.control}
          name="confirmPassword"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Confirm Password</FormLabel>
              <FormControl>
                <Input
                  type="password"
                  autoComplete="new-password"
                  aria-describedby={form.formState.errors.confirmPassword ? 'confirm-error' : undefined}
                  {...field}
                />
              </FormControl>
              <FormMessage id="confirm-error" />
            </FormItem>
          )}
        />
        
        {/* Full Name */}
        <FormField
          control={form.control}
          name="fullName"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Full Name</FormLabel>
              <FormControl>
                <Input
                  placeholder="John Doe"
                  autoComplete="name"
                  aria-describedby={form.formState.errors.fullName ? 'name-error' : undefined}
                  {...field}
                />
              </FormControl>
              <FormMessage id="name-error" />
            </FormItem>
          )}
        />
        
        {/* Role Select */}
        <FormField
          control={form.control}
          name="role"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Role</FormLabel>
              <Select onValueChange={field.onChange} defaultValue={field.value}>
                <FormControl>
                  <SelectTrigger aria-describedby={form.formState.errors.role ? 'role-error' : undefined}>
                    <SelectValue placeholder="Select role" />
                  </SelectTrigger>
                </FormControl>
                <SelectContent>
                  <SelectItem value="admin">Admin</SelectItem>
                  <SelectItem value="user">User</SelectItem>
                  <SelectItem value="viewer">Viewer</SelectItem>
                </SelectContent>
              </Select>
              <FormMessage id="role-error" />
            </FormItem>
          )}
        />
        
        {/* Terms Checkbox */}
        <FormField
          control={form.control}
          name="acceptTerms"
          render={({ field }) => (
            <FormItem className="flex items-start space-x-3 space-y-0">
              <FormControl>
                <Checkbox
                  checked={field.value}
                  onCheckedChange={field.onChange}
                  aria-describedby={form.formState.errors.acceptTerms ? 'terms-error' : undefined}
                />
              </FormControl>
              <div className="space-y-1 leading-none">
                <FormLabel>
                  I accept the <a href="/terms" className="underline">Terms of Service</a> and <a href="/privacy" className="underline">Privacy Policy</a>
                </FormLabel>
                <FormMessage id="terms-error" />
              </div>
            </FormItem>
          )}
        />
        
        {/* Submit */}
        <Button type="submit" disabled={isSubmitting || !isValid} className="w-full">
          {isSubmitting ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              Creating...
            </>
          ) : (
            submitLabel
          )}
        </Button>
        
        {/* Dirty/Valid indicator */}
        <div className="text-xs text-muted-foreground flex gap-4">
          <span className={isDirty ? 'text-primary' : ''}>
            {isDirty ? '✓' : '○'} Changes made
          </span>
          <span className={isValid ? 'text-success' : ''}>
            {isValid ? '✓' : '○'} Form valid
          </span>
        </div>
      </form>
    </Form>
  );
}
```

### Validation Modes
```typescript
// mode: 'onSubmit' | 'onBlur' | 'onChange' | 'onTouched' | 'all'
const form = useForm({
  resolver: zodResolver(schema),
  mode: 'onBlur',  // RECOMENDADO: validar on blur + on submit
  // reValidateMode: 'onChange', // Re-validar tras error
});
```

### Async Validation (Server-side)
```typescript
// Async refinement en Zod
const emailSchema = z.string().email().refine(
  async (email) => {
    const exists = await api.checkEmailExists(email);
    return !exists;
  },
  { message: 'Email already registered', path: ['email'] }
);

// O en componente con setError
const onSubmit = async (data) => {
  try {
    await api.register(data);
  } catch (error) {
    if (error.code === 'EMAIL_EXISTS') {
      form.setError('email', { type: 'server', message: 'Email already registered' });
    }
    throw error;
  }
};
```

## Stack Alterno: Angular Reactive Forms

### Form Group Tipado
```typescript
// user-form.component.ts
@Component({...})
export class UserFormComponent {
  private fb = inject(FormBuilder);
  
  // Non-nullable form group
  form = this.fb.nonNullable.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(8)]],
    confirmPassword: ['', [Validators.required]],
    fullName: ['', [Validators.required, Validators.maxLength(100)]],
    role: ['user', [Validators.required]],
    acceptTerms: [false, [Validators.requiredTrue]],
  }, { validators: this.passwordMatchValidator });
  
  // Signals para estado UI
  loading = signal(false);
  submitted = signal(false);
  error = signal<string | null>(null);
  
  // Custom validator
  passwordMatchValidator(group: FormGroup) {
    const password = group.get('password')?.value;
    const confirm = group.get('confirmPassword')?.value;
    return password === confirm ? null : { passwordMismatch: true };
  }
  
  // Computed para validación visual
  emailInvalid = computed(() => {
    const c = this.form.get('email');
    return c?.invalid && (c.dirty || c.touched || this.submitted());
  });
  
  async onSubmit() {
    this.submitted.set(true);
    this.error.set(null);
    
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    
    this.loading.set(true);
    try {
      await this.userService.create(this.form.getRawValue());
      this.router.navigate(['/users']);
    } catch (e) {
      this.error.set('Failed to create user');
    } finally {
      this.loading.set(false);
    }
  }
}
```

### Template con Control Flow
```html
<form [formGroup]="form" (ngSubmit)="onSubmit()" class="space-y-6">
  <!-- Email -->
  <mat-form-field appearance="outline" class="w-full">
    <mat-label>Email</mat-label>
    <input matInput formControlName="email" autocomplete="email" />
    @if (emailInvalid()) {
      <mat-error>Valid email required</mat-error>
    }
  </mat-form-field>
  
  <!-- Password -->
  <mat-form-field appearance="outline" class="w-full">
    <mat-label>Password</mat-label>
    <input matInput type="password" formControlName="password" autocomplete="new-password" />
    @if (form.get('password')?.invalid && (form.get('password')?.dirty || submitted())) {
      <mat-error>Min 8 characters</mat-error>
    }
  </mat-form-field>
  
  <!-- Confirm Password -->
  <mat-form-field appearance="outline" class="w-full">
    <mat-label>Confirm Password</mat-label>
    <input matInput type="password" formControlName="confirmPassword" autocomplete="new-password" />
    @if (form.hasError('passwordMismatch') && (form.get('confirmPassword')?.dirty || submitted())) {
      <mat-error>Passwords do not match</mat-error>
    }
  </mat-form-field>
  
  <!-- Full Name -->
  <mat-form-field appearance="outline" class="w-full">
    <mat-label>Full Name</mat-label>
    <input matInput formControlName="fullName" autocomplete="name" />
    @if (form.get('fullName')?.invalid && (form.get('fullName')?.dirty || submitted())) {
      <mat-error>Name required (max 100 chars)</mat-error>
    }
  </mat-form-field>
  
  <!-- Role -->
  <mat-form-field appearance="outline" class="w-full">
    <mat-label>Role</mat-label>
    <mat-select formControlName="role">
      <mat-option value="admin">Admin</mat-option>
      <mat-option value="user">User</mat-option>
      <mat-option value="viewer">Viewer</mat-option>
    </mat-select>
    @if (form.get('role')?.invalid && (form.get('role')?.dirty || submitted())) {
      <mat-error>Role required</mat-error>
    }
  </mat-form-field>
  
  <!-- Terms -->
  <div class="flex items-start gap-3">
    <mat-checkbox formControlName="acceptTerms">
      I accept the <a href="/terms">Terms</a> and <a href="/privacy">Privacy Policy</a>
    </mat-checkbox>
    @if (form.get('acceptTerms')?.invalid && (form.get('acceptTerms')?.dirty || submitted())) {
      <mat-error class="ml-6">Must accept terms</mat-error>
    }
  </div>
  
  <!-- Submit -->
  <button mat-flat-button color="primary" type="submit" [disabled]="loading() || form.invalid" class="w-full">
    @if (loading()) {
      <mat-spinner diameter="20" />
    } @else {
      Create User
    }
  </button>
  
  @if (error()) {
    <div class="error" role="alert">{{ error() }}</div>
  }
</form>
```

## Reglas de Validación (Ambos Stacks)

### FV-1: Validación On Blur + On Submit
- **NUNCA** solo onChange (spam de errores al escribir)
- **SIEMPRE** onBlur (al salir del campo) + onSubmit (al enviar)

### FV-2: Errores Inline Asociados via ARIA
```tsx
// React
<Input aria-describedby={errors.email ? 'email-error' : undefined} />
<FormMessage id="email-error" />

// Angular
<input matInput [attr.aria-describedby]="emailInvalid() ? 'email-error' : null" />
@if (emailInvalid()) { <mat-error id="email-error">...</mat-error> }
```

### FV-3: Submit Deshabilitado Mientras Inválido + Loading
```tsx
<Button type="submit" disabled={isSubmitting || !isValid}>
  {isSubmitting ? <Spinner /> : 'Submit'}
</Button>
```

### FV-4: Autocomplete Attributes
```tsx
// Obligatorios:
autoComplete="email"           // email
autoComplete="current-password" // login password
autoComplete="new-password"     // registro/change password
autoComplete="name"             // full name
autoComplete="given-name"       // first name
autoComplete="family-name"      // last name
autoComplete="tel"              // phone
autoComplete="street-address"   // address
autoComplete="postal-code"      // zip
autoComplete="cc-number"        // credit card
```

### FV-5: Password Visibility Toggle
```tsx
// BUENO - Toggle visible
<FormControl>
  <div className="relative">
    <Input 
      type={showPassword ? 'text' : 'password'} 
      {...field} 
      className="pr-10"
    />
    <button
      type="button"
      className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground"
      onClick={() => setShowPassword(!showPassword)}
      aria-label={showPassword ? 'Hide password' : 'Show password'}
    >
      {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
    </button>
  </div>
</FormControl>
```

### FV-6: Field Array (Dynamic Fields)
```tsx
// React Hook Form - useFieldArray
const { fields, append, remove } = useFieldArray({ control: form.control, name: 'items' });

{fields.map((item, index) => (
  <FormItem key={item.id}>
    <FormControl>
      <Input {...register(`items.${index}.name`)} placeholder="Item name" />
    </FormControl>
    <FormMessage />
    <Button type="button" variant="ghost" size="icon" onClick={() => remove(index)}>
      <Trash2 className="h-4 w-4" />
    </Button>
  </FormItem>
))}
<Button type="button" variant="outline" onClick={() => append({ name: '', quantity: 1 })}>
  Add Item
</Button>
```

### FV-7: Multi-step Forms (Wizard)
```typescript
// State machine para pasos
type Step = 'personal' | 'account' | 'confirm';
const [step, setStep] = useState<Step>('personal');
const stepOrder: Step[] = ['personal', 'account', 'confirm'];

const next = () => setStep(s => stepOrder[stepOrder.indexOf(s) + 1] ?? s);
const prev = () => setStep(s => stepOrder[stepOrder.indexOf(s) - 1] ?? s);

// Validar paso actual antes de avanzar
const goNext = async () => {
  const valid = await form.trigger(stepFields[step]);
  if (valid) next();
};
```

## Verificación en Review
- **forms-and-validation FV-1**: ¿Validación onBlur + onSubmit (no solo onChange)?
- **forms-and-validation FV-2**: ¿Errores inline con aria-describedby + id en message?
- **forms-and-validation FV-3**: ¿Submit disabled mientras invalid + loading state?
- **forms-and-validation FV-4**: ¿Autocomplete attributes en campos estándar?
- **forms-and-validation FV-5**: ¿Password visibility toggle con aria-label?
- **forms-and-validation FV-6**: ¿Field array para campos dinámicos?
- **forms-and-validation FV-7**: ¿Multi-step con validación por paso?
- **forms-and-validation FV-8**: ¿Schema Zod / Validators como single source of truth?