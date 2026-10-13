# Angular UI Patterns Skill

## Cuándo usarlo
- **UI Implementer**: Implementa componentes Angular 17+ siguiendo patterns obligatorios
- **UI Reviewer**: Verifica standalone components, signals, control flow, Material/PrimeNG usage

## Cuándo NO usarlo
- Para proyectos React (usa `react-component-patterns` + `tailwind-shadcn-stack`)
- Para AngularJS (1.x) o Angular < 17

## Descripción
Patterns obligatorios para **Angular 17+**: standalone components, signals, control flow (@if/@for/@switch), Angular Material / PrimeNG, RxJS + signals, Reactive Forms, CDK para a11y/layout.

## Stack Versions
```json
{
  "dependencies": {
    "@angular/animations": "^17.3.0",
    "@angular/common": "^17.3.0",
    "@angular/compiler": "^17.3.0",
    "@angular/core": "^17.3.0",
    "@angular/forms": "^17.3.0",
    "@angular/platform-browser": "^17.3.0",
    "@angular/router": "^17.3.0",
    "@angular/material": "^17.3.0",
    "@angular/cdk": "^17.3.0",
    "primeng": "^17.18.0",
    "primeicons": "^7.0.0",
    "rxjs": "^7.8.0",
    "zone.js": "^0.14.4"
  }
}
```

## Patterns Obligatorios

### 1. Standalone Components (Default)
```typescript
// BUENO - Standalone, signals, inyección moderna
@Component({
  selector: 'app-user-card',
  standalone: true,
  imports: [CommonModule, MatCardModule, MatButtonModule, MatIconModule],
  template: `
    <mat-card class="user-card">
      <mat-card-header>
        <mat-card-title>{{ user().name }}</mat-card-title>
        <mat-card-subtitle>{{ user().email }}</mat-card-subtitle>
      </mat-card-header>
      <mat-card-content>
        @if (showDetails()) {
          <p>{{ user().bio }}</p>
        }
      </mat-card-content>
      <mat-card-actions>
        <button mat-button (click)="toggleDetails()">
          <mat-icon>{{ showDetails() ? 'expand_less' : 'expand_more' }}</mat-icon>
          {{ showDetails() ? 'Less' : 'More' }}
        </button>
      </mat-card-actions>
    </mat-card>
  `,
  styles: [`
    .user-card { @apply w-full max-w-sm; }
  `]
})
export class UserCardComponent {
  // Input signal (Angular 17.1+)
  user = input.required<User>();
  
  // Local signal
  showDetails = signal(false);
  
  // Output via signal (Angular 17.2+)
  detailsToggled = output<boolean>();
  
  toggleDetails() {
    this.showDetails.update(v => !v);
    this.detailsToggled.emit(this.showDetails());
  }
}

// MALO - NgModule, decoradores legacy
@Component({
  selector: 'app-user-card',
  templateUrl: './user-card.component.html',
  styleUrls: ['./user-card.component.scss']
})
export class UserCardComponent implements OnInit {
  @Input() user!: User;
  @Output() detailsToggled = new EventEmitter<boolean>();
  // ...
}
```

### 2. Signals para State Management
```typescript
// BUENO - Signals para estado local y derivado
@Component({...})
export class UserListComponent {
  // Input signal
  filter = input<string>('');
  
  // Local signals
  private _users = signal<User[]>([]);
  private _loading = signal(false);
  
  // Computed signal (derivado, reactivo)
  filteredUsers = computed(() => {
    const f = this.filter().toLowerCase();
    return this._users().filter(u => 
      u.name.toLowerCase().includes(f) || u.email.toLowerCase().includes(f)
    );
  });
  
  // Effect para side effects
  constructor() {
    effect(() => {
      console.log('Filter changed:', this.filter());
      this.loadUsers();
    });
  }
  
  async loadUsers() {
    this._loading.set(true);
    try {
      const users = await this.userService.getUsers();
      this._users.set(users);
    } finally {
      this._loading.set(false);
    }
  }
  
  // Template usa _loading() y filteredUsers() directamente
}

// MALO - RxJS BehaviorSubject para todo
private usersSubject = new BehaviorSubject<User[]>([]);
users$ = this.usersSubject.asObservable();
```

### 3. Control Flow (@if, @for, @switch)
```typescript
// BUENO - Nuevo control flow (Angular 17+)
<template>
  @if (loading()) {
    <mat-spinner diameter="40" />
  } @else if (error()) {
    <div class="error" role="alert">
      <mat-icon>error</mat-icon>
      {{ error() }}
      <button mat-button (click)="retry()">Retry</button>
    </div>
  } @else {
    @for (user of filteredUsers(); track user.id) {
      <app-user-card [user]="user" />
    } @empty {
      <div class="empty-state">
        <mat-icon>person_off</mat-icon>
        <p>No users found</p>
      </div>
    }
  }
  
  @switch (status()) {
    @case ('active') { <span class="badge success">Active</span> }
    @case ('pending') { <span class="badge warning">Pending</span> }
    @case ('inactive') { <span class="badge neutral">Inactive</span> }
    @default { <span class="badge">Unknown</span> }
  }
</template>

// MALO - *ngIf, *ngFor, *ngSwitch (legacy)
<div *ngIf="loading; else loaded">Loading...</div>
<ng-template #loaded>
  <div *ngFor="let user of users; trackBy: trackById">...</div>
</ng-template>
```

### 4. Reactive Forms + Custom Validators
```typescript
// BUENO - FormBuilder no reactivo, signals para estado
@Component({...})
export class LoginComponent {
  private fb = inject(FormBuilder);
  
  // Form group tipado
  form = this.fb.nonNullable.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(8)]],
    rememberMe: [false],
  });
  
  // Signals para estado UI
  loading = signal(false);
  submitted = signal(false);
  error = signal<string | null>(null);
  
  // Computed para validación visual
  emailInvalid = computed(() => {
    const control = this.form.get('email');
    return control?.invalid && (control.dirty || control.touched || this.submitted());
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
      await this.authService.login(this.form.getRawValue());
      this.router.navigate(['/dashboard']);
    } catch (e) {
      this.error.set('Invalid credentials');
    } finally {
      this.loading.set(false);
    }
  }
}

// Template:
<form [formGroup]="form" (ngSubmit)="onSubmit()" class="space-y-4">
  <mat-form-field appearance="outline" class="w-full">
    <mat-label>Email</mat-label>
    <input matInput formControlName="email" autocomplete="email" />
    @if (emailInvalid()) {
      <mat-error>Valid email required</mat-error>
    }
  </mat-form-field>
  
  <mat-form-field appearance="outline" class="w-full">
    <mat-label>Password</mat-label>
    <input matInput type="password" formControlName="password" autocomplete="current-password" />
    @if (form.get('password')?.invalid && (form.get('password')?.dirty || submitted())) {
      <mat-error>Min 8 characters</mat-error>
    }
  </mat-form-field>
  
  <button mat-flat-button color="primary" type="submit" [disabled]="loading()">
    @if (loading()) {
      <mat-spinner diameter="20" />
    } @else {
      Login
    }
  </button>
  
  @if (error()) {
    <div class="error" role="alert">{{ error() }}</div>
  }
</form>
```

### 5. RxJS + Signals Interop
```typescript
// BUENO - toSignal para convertir observables
import { toSignal } from '@angular/core/rxjs-interop';
import { interval, map } from 'rxjs';

@Component({...})
export class DashboardComponent {
  // Observable → Signal
  private time$ = interval(1000).pipe(map(() => new Date()));
  currentTime = toSignal(this.time$, { initialValue: new Date() });
  
  // HTTP → Signal
  private users$ = this.http.get<User[]>('/api/users');
  users = toSignal(this.users$, { initialValue: [] });
  
  // Combine signals + observables
  filteredUsers = computed(() => {
    const filter = this.filter();
    return this.users().filter(u => u.name.includes(filter));
  });
}
```

### 6. Angular Material / PrimeNG Theming
```scss
// styles.scss - Theme personalizado Angular Material
@use '@angular/material' as mat;

$primary-palette: mat.define-palette(mat.$purple-palette, 600, 400, 800);
$accent-palette: mat.define-palette(mat.$amber-palette, 500, 300, 700);
$warn-palette: mat.define-palette(mat.$red-palette);

$theme: mat.define-light-theme((
  color: (
    primary: $primary-palette,
    accent: $accent-palette,
    warn: $warn-palette,
  ),
  typography: mat.define-typography-config(
    $font-family: 'var(--font-sans), system-ui, sans-serif',
    $headline-5: mat.define-typography-level(1.5rem, 400, 1.2),
  ),
  density: 0,
));

@include mat.all-component-themes($theme);

// Dark theme
$dark-theme: mat.define-dark-theme((
  color: (
    primary: mat.define-palette(mat.$purple-palette, 400, 200, 600),
    accent: mat.define-palette(mat.$amber-palette, 400, 200, 600),
    warn: mat.define-palette(mat.$red-palette, 400, 200, 600),
  ),
));

@include mat.all-component-themes($dark-theme);
```

```typescript
// PrimeNG Theme (primeng/config)
import { providePrimeNG } from 'primeng/config';
import Aura from '@primeng/themes/aura';

export const appConfig: ApplicationConfig = {
  providers: [
    providePrimeNG({
      theme: {
        preset: Aura,
        options: {
          darkModeSelector: '.dark',
          cssLayer: {
            name: 'primeng',
            order: 'tailwind-base, primeng, tailwind-utilities',
          },
        },
      },
    }),
  ],
};
```

### 7. CDK para Accesibilidad y Layout
```typescript
// BUENO - CDK Overlay, A11y, Layout
import { OverlayModule } from '@angular/cdk/overlay';
import { A11yModule } from '@angular/cdk/a11y';
import { LayoutModule, BreakpointObserver } from '@angular/cdk/layout';

@Component({
  standalone: true,
  imports: [OverlayModule, A11yModule, LayoutModule],
  ...
})
export class DropdownComponent {
  constructor(private breakpointObserver: BreakpointObserver) {
    // Responsive via CDK
    this.breakpointObserver.observe(['(max-width: 768px)'])
      .subscribe(result => this.isMobile = result.matches);
  }
}
```

### 8. Lazy Loading + Code Splitting
```typescript
// routes.ts - Lazy loading obligatorio
export const routes: Routes = [
  {
    path: 'dashboard',
    loadComponent: () => import('./dashboard/dashboard.component').then(m => m.DashboardComponent),
  },
  {
    path: 'users',
    loadChildren: () import('./users/users.routes').then(m => m.USERS_ROUTES),
  },
  {
    path: '**',
    redirectTo: '/dashboard',
  },
];

// Preloading strategy
export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes, withPreloading(PreloadAllModules)),
  ],
};
```

### 9. Change Detection OnPush (Obligatorio)
```typescript
// BUENO - OnPush en todos los componentes
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  ...
})
export class UserListComponent {
  // Inputs son signals, computed deriva estado
  // No necesita markForCheck / detectChanges
}

// MALO - Default (CheckAlways)
@Component({
  changeDetection: ChangeDetectionStrategy.Default, // o omitido
  ...
})
```

### 10. Testing Patterns
```typescript
// component.spec.ts
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideHttpClientTesting } from '@angular/common/http/testing';

describe('UserCardComponent', () => {
  let component: UserCardComponent;
  let fixture: ComponentFixture<UserCardComponent>;
  
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [UserCardComponent],
      providers: [
        provideHttpClientTesting(),
        // Mock services
      ],
    }).compileComponents();
    
    fixture = TestBed.createComponent(UserCardComponent);
    component = fixture.componentInstance;
    
    // Set input signals
    fixture.componentRef.setInput('user', mockUser);
    fixture.detectChanges();
  });
  
  it('should display user name', () => {
    expect(fixture.nativeElement.querySelector('mat-card-title').textContent).toContain('John Doe');
  });
  
  it('should toggle details on button click', () => {
    const button = fixture.nativeElement.querySelector('button');
    button.click();
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('p')).toBeTruthy();
  });
});
```

## Verificación en Review
- **angular-ui-patterns AUP-1**: ¿Standalone components, signals, control flow @if/@for/@switch?
- **angular-ui-patterns AUP-2**: ¿Signals para estado (input, local, computed, effect)?
- **angular-ui-patterns AUP-3**: ¿Control flow nuevo (@if/@for/@switch) vs *ngIf/*ngFor?
- **angular-ui-patterns AUP-4**: ¿Reactive Forms tipados + custom validators + signals para UI state?
- **angular-ui-patterns AUP-5**: ¿RxJS + signals interop (toSignal, toObservable)?
- **angular-ui-patterns AUP-6**: ¿Material/PrimeNG theming personalizado (no default)?
- **angular-ui-patterns AUP-7**: ¿CDK para a11y, overlay, layout, breakpoint observer?
- **angular-ui-patterns AUP-8**: ¿Lazy loading routes + preloading strategy?
- **angular-ui-patterns AUP-9**: ¿ChangeDetection.OnPush en todos los componentes?
- **angular-ui-patterns AUP-10**: ¿Tests con TestBed, input signals, fixture.detectChanges()?