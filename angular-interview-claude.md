# Angular Interview Preparation Guide

> Angular 17+ (Standalone-first, Signals, modern best practices)

---

## Table of Contents

1. [Angular Overview](#1-angular-overview)
2. [Modules (NgModule)](#2-modules-ngmodule)
3. [Components](#3-components)
4. [Component Lifecycle Hooks](#4-component-lifecycle-hooks)
5. [Directives](#5-directives)
6. [Data Binding](#6-data-binding)
7. [Decorators](#7-decorators)
8. [Services & Dependency Injection](#8-services--dependency-injection)
9. [Routing](#9-routing)
10. [Template-Driven Forms](#10-template-driven-forms)
11. [Reactive Forms](#11-reactive-forms)
12. [Pipes](#12-pipes)
13. [HTTP Client & API Calls](#13-http-client--api-calls)
14. [Observables & RxJS](#14-observables--rxjs)
15. [Route Guards](#15-route-guards)
16. [Change Detection](#16-change-detection)
17. [Angular Signals (Angular 16+)](#17-angular-signals-angular-16)
18. [Standalone Components (Angular 14+)](#18-standalone-components-angular-14)
19. [Performance Optimization](#19-performance-optimization)
20. [Common Interview Q&A](#20-common-interview-qa)

---

## 1. Angular Overview

**Q: What is Angular?**

Angular is a **TypeScript-based, component-driven framework** by Google for building scalable single-page applications (SPAs).

Key features:
- Component-based architecture
- Two-way data binding
- Dependency injection (DI)
- Built-in routing
- Reactive programming via RxJS
- CLI tooling

**Q: Difference between Angular vs AngularJS?**

| Feature | AngularJS (1.x) | Angular (2+) |
|---|---|---|
| Language | JavaScript | TypeScript |
| Architecture | MVC | Component-based |
| Data Binding | Two-way by default | One-way + explicit two-way |
| Performance | Digest cycle | Zone.js + change detection |
| Mobile Support | No | Yes |

**Q: How Angular bootstraps?**

```
index.html → main.ts → AppModule (or standalone AppComponent) → AppComponent
```

```typescript
// main.ts (classic)
import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';
import { AppModule } from './app/app.module';

platformBrowserDynamic().bootstrapModule(AppModule);

// main.ts (standalone - Angular 17+)
import { bootstrapApplication } from '@angular/platform-browser';
import { AppComponent } from './app/app.component';

bootstrapApplication(AppComponent);
```

---

## 2. Modules (NgModule)

**Q: What is NgModule?**

A class decorated with `@NgModule` that organizes an Angular application into cohesive blocks of functionality.

```typescript
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { UserComponent } from './user/user.component';
import { UserService } from './services/user.service';

@NgModule({
  declarations: [
    AppComponent,   // Components/Directives/Pipes that belong to this module
    UserComponent
  ],
  imports: [
    BrowserModule,  // Other modules this module needs
    AppRoutingModule
  ],
  providers: [
    UserService     // Services available to this module
  ],
  exports: [
    UserComponent   // Make available to other modules
  ],
  bootstrap: [AppComponent] // Root component (only in AppModule)
})
export class AppModule {}
```

**Q: Types of modules?**

| Type | Purpose | Example |
|---|---|---|
| Root Module | Bootstraps the app | `AppModule` |
| Feature Module | Encapsulates a feature | `UserModule`, `OrderModule` |
| Shared Module | Reusable components/pipes | `SharedModule` |
| Core Module | Singleton services | `CoreModule` |
| Routing Module | Route definitions | `AppRoutingModule` |

```typescript
// Shared Module pattern
@NgModule({
  declarations: [ButtonComponent, CardComponent, TruncatePipe],
  imports: [CommonModule],
  exports: [ButtonComponent, CardComponent, TruncatePipe, CommonModule]
})
export class SharedModule {}
```

---

## 3. Components

**Q: What is a Component?**

The fundamental UI building block. Each component = template (HTML) + class (TypeScript) + styles (CSS).

```typescript
import { Component, OnInit } from '@angular/core';

@Component({
  selector: 'app-user',           // HTML tag: <app-user></app-user>
  templateUrl: './user.component.html',
  styleUrls: ['./user.component.scss'],
  // OR inline:
  // template: `<h1>{{title}}</h1>`,
  // styles: [`h1 { color: red; }`]
})
export class UserComponent implements OnInit {
  title = 'User Dashboard';
  users: string[] = [];

  ngOnInit(): void {
    this.users = ['Alice', 'Bob', 'Charlie'];
  }
}
```

**Q: Types of component selectors?**

```typescript
// Element selector (most common)
selector: 'app-user'
// → <app-user></app-user>

// Attribute selector
selector: '[appUser]'
// → <div appUser></div>

// Class selector
selector: '.app-user'
// → <div class="app-user"></div>
```

**Q: Parent-Child Component Communication?**

```typescript
// Child component
@Component({ selector: 'app-child', template: `
  <p>{{message}}</p>
  <button (click)="sendMessage()">Send</button>
`})
export class ChildComponent {
  @Input() message: string = '';          // Receive from parent
  @Output() replied = new EventEmitter<string>(); // Send to parent

  sendMessage() {
    this.replied.emit('Hello from child!');
  }
}

// Parent component
@Component({ selector: 'app-parent', template: `
  <app-child
    [message]="parentMsg"
    (replied)="onReply($event)">
  </app-child>
  <p>Child said: {{childReply}}</p>
`})
export class ParentComponent {
  parentMsg = 'Message from parent';
  childReply = '';

  onReply(msg: string) {
    this.childReply = msg;
  }
}
```

---

## 4. Component Lifecycle Hooks

**Q: What are lifecycle hooks and in what order are they called?**

```
constructor()
  ↓
ngOnChanges()   ← called when @Input() changes (before ngOnInit, on every change)
  ↓
ngOnInit()      ← called once after first ngOnChanges
  ↓
ngDoCheck()     ← called on every change detection run
  ↓
ngAfterContentInit()    ← called once after content projection (ng-content)
  ↓
ngAfterContentChecked() ← called after every check of projected content
  ↓
ngAfterViewInit()       ← called once after component's view is initialized
  ↓
ngAfterViewChecked()    ← called after every check of component's view
  ↓
ngOnDestroy()   ← called just before component is destroyed
```

```typescript
import {
  Component, OnInit, OnDestroy, OnChanges, DoCheck,
  AfterContentInit, AfterContentChecked, AfterViewInit, AfterViewChecked,
  Input, SimpleChanges
} from '@angular/core';

@Component({
  selector: 'app-lifecycle',
  template: `<p>{{data}}</p>`
})
export class LifecycleComponent implements OnInit, OnChanges, OnDestroy,
  DoCheck, AfterContentInit, AfterContentChecked, AfterViewInit, AfterViewChecked {

  @Input() data: string = '';

  constructor() {
    console.log('1. constructor');
  }

  ngOnChanges(changes: SimpleChanges): void {
    console.log('2. ngOnChanges', changes);
    // changes.data.currentValue  → new value
    // changes.data.previousValue → old value
    // changes.data.firstChange   → true on first change
  }

  ngOnInit(): void {
    console.log('3. ngOnInit - initialize data, API calls here');
  }

  ngDoCheck(): void {
    console.log('4. ngDoCheck - manual change detection');
  }

  ngAfterContentInit(): void {
    console.log('5. ngAfterContentInit');
  }

  ngAfterContentChecked(): void {
    console.log('6. ngAfterContentChecked');
  }

  ngAfterViewInit(): void {
    console.log('7. ngAfterViewInit - DOM manipulation here');
  }

  ngAfterViewChecked(): void {
    console.log('8. ngAfterViewChecked');
  }

  ngOnDestroy(): void {
    console.log('9. ngOnDestroy - cleanup, unsubscribe here');
  }
}
```

**Q: constructor vs ngOnInit?**

| | constructor | ngOnInit |
|---|---|---|
| Purpose | Dependency injection | Business logic initialization |
| When called | Class instantiated | After inputs bound |
| API calls | Never | Yes |
| Access @Input | No | Yes |

**Q: ngOnChanges vs ngDoCheck?**

- `ngOnChanges` – triggered only for `@Input()` changes (uses reference check, won't detect object property changes)
- `ngDoCheck` – triggered on every CD cycle; use to detect deep object changes

```typescript
// ngDoCheck for deep object detection
@Input() user: { name: string; age: number } = { name: '', age: 0 };
private previousUserName = '';

ngDoCheck() {
  if (this.user.name !== this.previousUserName) {
    console.log('User name changed:', this.user.name);
    this.previousUserName = this.user.name;
  }
}
```

**Q: ngAfterViewInit vs ngAfterContentInit?**

- `ngAfterContentInit` – after `<ng-content>` (projected content) is initialized → access via `@ContentChild`
- `ngAfterViewInit` – after component's own template is rendered → access via `@ViewChild`

---

## 5. Directives

**Q: What are the types of directives?**

| Type | Purpose | Examples |
|---|---|---|
| Component | Directive with a template | All components |
| Structural | Modifies DOM structure | `*ngIf`, `*ngFor`, `*ngSwitch` |
| Attribute | Modifies element appearance/behavior | `ngClass`, `ngStyle`, `ngModel` |

### Built-in Structural Directives

```html
<!-- *ngIf -->
<div *ngIf="isLoggedIn; else loginBlock">
  Welcome, {{ username }}!
</div>
<ng-template #loginBlock>
  <p>Please log in.</p>
</ng-template>

<!-- *ngFor -->
<ul>
  <li *ngFor="let user of users; let i = index; trackBy: trackById">
    {{ i + 1 }}. {{ user.name }}
  </li>
</ul>

<!-- *ngSwitch -->
<div [ngSwitch]="role">
  <span *ngSwitchCase="'admin'">Admin Panel</span>
  <span *ngSwitchCase="'user'">User Dashboard</span>
  <span *ngSwitchDefault>Guest View</span>
</div>
```

```typescript
// trackBy improves *ngFor performance
trackById(index: number, user: User): number {
  return user.id;
}
```

### Built-in Attribute Directives

```html
<!-- ngClass -->
<div [ngClass]="{ 'active': isActive, 'disabled': isDisabled, 'highlight': score > 80 }">
  Dynamic classes
</div>

<!-- ngStyle -->
<p [ngStyle]="{ 'color': textColor, 'font-size': fontSize + 'px' }">
  Dynamic styles
</p>

<!-- ngModel (two-way binding, requires FormsModule) -->
<input [(ngModel)]="username" name="username" />
<p>Hello, {{ username }}</p>
```

### Custom Attribute Directive

```typescript
import { Directive, ElementRef, HostListener, Input, Renderer2 } from '@angular/core';

@Directive({
  selector: '[appHighlight]'
})
export class HighlightDirective {
  @Input() appHighlight = 'yellow';
  @Input() defaultColor = 'transparent';

  constructor(private el: ElementRef, private renderer: Renderer2) {}

  @HostListener('mouseenter')
  onMouseEnter() {
    this.setBackground(this.appHighlight);
  }

  @HostListener('mouseleave')
  onMouseLeave() {
    this.setBackground(this.defaultColor);
  }

  private setBackground(color: string) {
    this.renderer.setStyle(this.el.nativeElement, 'background-color', color);
  }
}
```

```html
<!-- Usage -->
<p appHighlight="lightblue" defaultColor="white">
  Hover over me!
</p>
```

### Custom Structural Directive

```typescript
import { Directive, Input, TemplateRef, ViewContainerRef } from '@angular/core';

@Directive({ selector: '[appUnless]' })
export class UnlessDirective {
  @Input() set appUnless(condition: boolean) {
    if (!condition) {
      this.vcr.createEmbeddedView(this.templateRef);
    } else {
      this.vcr.clear();
    }
  }

  constructor(
    private templateRef: TemplateRef<any>,
    private vcr: ViewContainerRef
  ) {}
}
```

```html
<p *appUnless="isHidden">Shown when NOT hidden</p>
```

---

## 6. Data Binding

**Q: What are the types of data binding?**

```typescript
@Component({
  selector: 'app-binding',
  template: `
    <!-- 1. String Interpolation (Component → View) -->
    <h1>{{ title }}</h1>
    <p>{{ 2 + 2 }}</p>
    <p>{{ isActive ? 'Active' : 'Inactive' }}</p>

    <!-- 2. Property Binding (Component → View) -->
    <img [src]="imageUrl" [alt]="imageAlt" />
    <button [disabled]="isDisabled">Click me</button>
    <input [value]="username" />

    <!-- 3. Event Binding (View → Component) -->
    <button (click)="onClick()">Submit</button>
    <input (input)="onInput($event)" />
    <form (submit)="onSubmit($event)">...</form>

    <!-- 4. Two-Way Binding (Component ↔ View, requires FormsModule) -->
    <input [(ngModel)]="username" />

    <!-- 5. Attribute Binding -->
    <td [attr.colspan]="colSpan">Cell</td>
    <button [attr.aria-label]="buttonLabel">Icon</button>

    <!-- 6. Class Binding -->
    <div [class.active]="isActive">Single class</div>
    <div [class]="'btn btn-primary'">Multiple classes</div>
    <div [ngClass]="{'active': isActive, 'error': hasError}">Dynamic</div>

    <!-- 7. Style Binding -->
    <p [style.color]="textColor">Colored</p>
    <p [style.font-size.px]="fontSize">Sized</p>
    <p [ngStyle]="{'color': color, 'font-weight': bold ? 'bold' : 'normal'}">Styled</p>
  `
})
export class BindingComponent {
  title = 'Data Binding Demo';
  imageUrl = 'logo.png';
  imageAlt = 'Logo';
  isDisabled = false;
  isActive = true;
  hasError = false;
  username = '';
  colSpan = 2;
  buttonLabel = 'Close dialog';
  textColor = 'blue';
  fontSize = 16;
  color = 'red';
  bold = true;

  onClick() { console.log('Button clicked'); }
  onInput(event: Event) {
    const input = event.target as HTMLInputElement;
    console.log(input.value);
  }
  onSubmit(event: Event) { event.preventDefault(); }
}
```

---

## 7. Decorators

**Q: What decorators are used inside a class?**

### @Input & @Output

```typescript
// Child
@Component({ selector: 'app-counter', template: `
  <span>{{ count }}</span>
  <button (click)="increment()">+</button>
`})
export class CounterComponent {
  @Input() count: number = 0;
  @Input({ required: true }) label!: string; // Angular 16+ required input
  @Output() countChange = new EventEmitter<number>();

  increment() {
    this.count++;
    this.countChange.emit(this.count);
  }
}

// Parent
@Component({ template: `
  <app-counter [count]="value" label="Score" (countChange)="value = $event" />
  <p>Value: {{ value }}</p>
`})
export class ParentComponent {
  value = 0;
}
```

### @ViewChild & @ViewChildren

```typescript
@Component({
  selector: 'app-parent',
  template: `
    <input #inputRef type="text" />
    <app-child #childRef></app-child>
    <button (click)="focusInput()">Focus Input</button>
  `
})
export class ParentComponent implements AfterViewInit {
  @ViewChild('inputRef') inputEl!: ElementRef;
  @ViewChild('childRef') childComp!: ChildComponent;
  @ViewChildren(ChildComponent) children!: QueryList<ChildComponent>;

  ngAfterViewInit() {
    // DOM elements available here
    console.log(this.inputEl.nativeElement.value);
  }

  focusInput() {
    this.inputEl.nativeElement.focus();
  }
}
```

### @ContentChild & @ContentChildren

```typescript
// Used with content projection (ng-content)
@Component({
  selector: 'app-card',
  template: `
    <div class="card">
      <ng-content select="[card-title]"></ng-content>
      <ng-content></ng-content>
    </div>
  `
})
export class CardComponent implements AfterContentInit {
  @ContentChild('titleRef') titleEl!: ElementRef;

  ngAfterContentInit() {
    console.log(this.titleEl.nativeElement.textContent);
  }
}

// Parent using content projection
@Component({ template: `
  <app-card>
    <h2 #titleRef card-title>My Card Title</h2>
    <p>Card body content</p>
  </app-card>
`})
export class ParentComponent {}
```

### @HostListener & @HostBinding

```typescript
@Directive({ selector: '[appDraggable]' })
export class DraggableDirective {
  @HostBinding('class.dragging') isDragging = false;
  @HostBinding('style.cursor') cursor = 'grab';

  @HostListener('mousedown')
  onMouseDown() {
    this.isDragging = true;
    this.cursor = 'grabbing';
  }

  @HostListener('mouseup')
  onMouseUp() {
    this.isDragging = false;
    this.cursor = 'grab';
  }

  @HostListener('document:keyup.escape')
  onEscape() {
    this.isDragging = false;
  }
}
```

---

## 8. Services & Dependency Injection

**Q: What is a Service?**

A class with `@Injectable()` decorator used to share data/logic across components.

```typescript
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, BehaviorSubject } from 'rxjs';

@Injectable({
  providedIn: 'root'  // Singleton – available app-wide
})
export class UserService {
  private usersSubject = new BehaviorSubject<User[]>([]);
  users$ = this.usersSubject.asObservable();

  constructor(private http: HttpClient) {}

  getUsers(): Observable<User[]> {
    return this.http.get<User[]>('/api/users');
  }

  addUser(user: User): void {
    const current = this.usersSubject.getValue();
    this.usersSubject.next([...current, user]);
  }
}
```

**Q: `providedIn` options?**

```typescript
@Injectable({ providedIn: 'root' })       // App-level singleton
@Injectable({ providedIn: 'any' })        // New instance per lazy module
@Injectable({ providedIn: UserModule })   // Module-scoped
// OR registered in @NgModule providers array (module-scoped)
```

**Q: Component-level provider (non-singleton)?**

```typescript
@Component({
  selector: 'app-cart',
  template: `...`,
  providers: [CartService]  // New instance per component tree
})
export class CartComponent {}
```

**Q: How DI works — injection token?**

```typescript
import { InjectionToken } from '@angular/core';

export const API_URL = new InjectionToken<string>('API_URL');

// In module/component providers:
providers: [
  { provide: API_URL, useValue: 'https://api.example.com' }
]

// Inject it:
constructor(@Inject(API_URL) private apiUrl: string) {}
```

---

## 9. Routing

**Q: How to set up routing?**

```typescript
// app-routing.module.ts
import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { HomeComponent } from './home/home.component';
import { UserComponent } from './user/user.component';
import { NotFoundComponent } from './not-found/not-found.component';
import { authGuard } from './guards/auth.guard';

const routes: Routes = [
  { path: '', redirectTo: '/home', pathMatch: 'full' },
  { path: 'home', component: HomeComponent },
  { path: 'user/:id', component: UserComponent },
  {
    path: 'admin',
    canActivate: [authGuard],
    loadChildren: () => import('./admin/admin.module').then(m => m.AdminModule) // lazy load
  },
  { path: '**', component: NotFoundComponent }  // wildcard – must be last
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule {}
```

```html
<!-- app.component.html -->
<nav>
  <a routerLink="/home" routerLinkActive="active">Home</a>
  <a routerLink="/admin" routerLinkActive="active" [routerLinkActiveOptions]="{exact: true}">Admin</a>
</nav>
<router-outlet></router-outlet>
```

**Q: Accessing route params and query params?**

```typescript
import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';

@Component({ selector: 'app-user', template: `<p>User: {{ userId }}</p>` })
export class UserComponent implements OnInit {
  userId: string = '';
  category: string = '';

  constructor(
    private route: ActivatedRoute,
    private router: Router
  ) {}

  ngOnInit() {
    // Route params: /user/42
    // snapshot – use when params won't change while component is active
    this.userId = this.route.snapshot.paramMap.get('id') ?? '';

    // subscribe – use when params can change without reloading
    this.route.paramMap.subscribe(params => {
      this.userId = params.get('id') ?? '';
    });

    // Query params: /user?category=admin&page=2
    this.route.queryParamMap.subscribe(params => {
      this.category = params.get('category') ?? '';
    });

    // Fragment: /user#section
    this.route.fragment.subscribe(frag => console.log(frag));
  }

  navigate() {
    this.router.navigate(['/user', 42], {
      queryParams: { category: 'admin' },
      fragment: 'details'
    });

    // Relative navigation
    this.router.navigate(['../sibling'], { relativeTo: this.route });
  }
}
```

**Q: Nested / child routes?**

```typescript
const routes: Routes = [
  {
    path: 'dashboard',
    component: DashboardComponent,
    children: [
      { path: 'profile', component: ProfileComponent },
      { path: 'settings', component: SettingsComponent },
      { path: '', redirectTo: 'profile', pathMatch: 'full' }
    ]
  }
];
```

```html
<!-- dashboard.component.html needs its own router-outlet -->
<nav>
  <a routerLink="profile">Profile</a>
  <a routerLink="settings">Settings</a>
</nav>
<router-outlet></router-outlet>
```

**Q: Lazy loading?**

```typescript
const routes: Routes = [
  {
    path: 'products',
    loadChildren: () => import('./products/products.module').then(m => m.ProductsModule)
  }
];

// products-routing.module.ts
const productRoutes: Routes = [
  { path: '', component: ProductListComponent },
  { path: ':id', component: ProductDetailComponent }
];

@NgModule({
  imports: [RouterModule.forChild(productRoutes)],  // forChild (not forRoot!)
  exports: [RouterModule]
})
export class ProductsRoutingModule {}
```

---

## 10. Template-Driven Forms

**Q: How do Template-Driven Forms work?**

Requires `FormsModule`. Angular creates form model from HTML template automatically.

```typescript
// app.module.ts
imports: [FormsModule]

// component.ts
export class LoginComponent {
  user = { username: '', email: '', password: '' };

  onSubmit(form: NgForm) {
    if (form.valid) {
      console.log(form.value);  // { username: '...', email: '...' }
      form.reset();
    }
  }
}
```

```html
<form #loginForm="ngForm" (ngSubmit)="onSubmit(loginForm)">

  <input
    name="username"
    [(ngModel)]="user.username"
    #usernameCtrl="ngModel"
    required
    minlength="3"
  />
  <div *ngIf="usernameCtrl.invalid && usernameCtrl.touched">
    <small *ngIf="usernameCtrl.errors?.['required']">Username is required.</small>
    <small *ngIf="usernameCtrl.errors?.['minlength']">Min 3 characters.</small>
  </div>

  <input
    name="email"
    type="email"
    [(ngModel)]="user.email"
    #emailCtrl="ngModel"
    required
    email
  />
  <div *ngIf="emailCtrl.invalid && emailCtrl.touched">
    <small *ngIf="emailCtrl.errors?.['email']">Invalid email format.</small>
  </div>

  <!-- NgModelGroup for nested objects -->
  <div ngModelGroup="address">
    <input name="city" ngModel required />
    <input name="zip" ngModel required />
  </div>

  <button type="submit" [disabled]="loginForm.invalid">Login</button>
  <button type="button" (click)="loginForm.reset()">Reset</button>

  <!-- Form state properties -->
  <!-- loginForm.valid / loginForm.invalid -->
  <!-- loginForm.pristine / loginForm.dirty (ever modified) -->
  <!-- loginForm.touched / loginForm.untouched (ever focused) -->
</form>
```

---

## 11. Reactive Forms

**Q: How do Reactive Forms work?**

Requires `ReactiveFormsModule`. Form model defined in TypeScript, not HTML — more control, more testable.

```typescript
import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, FormArray, Validators, AbstractControl } from '@angular/forms';

@Component({
  selector: 'app-register',
  templateUrl: './register.component.html'
})
export class RegisterComponent implements OnInit {
  registerForm!: FormGroup;

  constructor(private fb: FormBuilder) {}

  ngOnInit() {
    this.registerForm = this.fb.group({
      username: ['', [Validators.required, Validators.minLength(3), Validators.maxLength(20)]],
      email: ['', [Validators.required, Validators.email]],
      passwords: this.fb.group({
        password: ['', [Validators.required, Validators.minLength(8)]],
        confirmPassword: ['', Validators.required]
      }, { validators: this.passwordMatch }),  // group-level validator
      phones: this.fb.array([this.fb.control('', Validators.required)])
    });
  }

  // Custom validator
  passwordMatch(group: AbstractControl) {
    const pass = group.get('password')?.value;
    const confirm = group.get('confirmPassword')?.value;
    return pass === confirm ? null : { mismatch: true };
  }

  // Getters for cleaner template access
  get username() { return this.registerForm.get('username')!; }
  get email() { return this.registerForm.get('email')!; }
  get passwords() { return this.registerForm.get('passwords')!; }
  get phones() { return this.registerForm.get('phones') as FormArray; }

  addPhone() {
    this.phones.push(this.fb.control('', Validators.required));
  }

  removePhone(index: number) {
    this.phones.removeAt(index);
  }

  onSubmit() {
    if (this.registerForm.valid) {
      console.log(this.registerForm.value);
      this.registerForm.reset();
    } else {
      this.registerForm.markAllAsTouched(); // show all errors
    }
  }
}
```

```html
<!-- register.component.html -->
<form [formGroup]="registerForm" (ngSubmit)="onSubmit()">

  <input formControlName="username" placeholder="Username" />
  <div *ngIf="username.invalid && username.touched">
    <small *ngIf="username.errors?.['required']">Required</small>
    <small *ngIf="username.errors?.['minlength']">Min 3 chars</small>
  </div>

  <input formControlName="email" type="email" placeholder="Email" />

  <div formGroupName="passwords">
    <input formControlName="password" type="password" />
    <input formControlName="confirmPassword" type="password" />
    <small *ngIf="passwords.errors?.['mismatch'] && passwords.touched">
      Passwords do not match.
    </small>
  </div>

  <div formArrayName="phones">
    <div *ngFor="let phone of phones.controls; let i = index">
      <input [formControlName]="i" placeholder="Phone {{ i + 1 }}" />
      <button type="button" (click)="removePhone(i)">Remove</button>
    </div>
  </div>
  <button type="button" (click)="addPhone()">Add Phone</button>

  <button type="submit" [disabled]="registerForm.invalid">Register</button>
</form>
```

**Q: Custom async validator?**

```typescript
import { AbstractControl, AsyncValidatorFn, ValidationErrors } from '@angular/forms';
import { Observable, of } from 'rxjs';
import { map, debounceTime, switchMap, catchError } from 'rxjs/operators';

export function usernameAvailable(userService: UserService): AsyncValidatorFn {
  return (control: AbstractControl): Observable<ValidationErrors | null> => {
    return of(control.value).pipe(
      debounceTime(400),
      switchMap(username => userService.checkUsername(username)),
      map(isTaken => (isTaken ? { usernameTaken: true } : null)),
      catchError(() => of(null))
    );
  };
}

// Usage
username: ['', [Validators.required], [usernameAvailable(this.userService)]]
```

**Q: Template-Driven vs Reactive Forms?**

| | Template-Driven | Reactive |
|---|---|---|
| Module | `FormsModule` | `ReactiveFormsModule` |
| Model defined in | HTML | TypeScript |
| Testability | Harder | Easier |
| Dynamic fields | Harder | Easy (FormArray) |
| Async validators | Limited | Full support |
| Best for | Simple forms | Complex/dynamic forms |

---

## 12. Pipes

**Q: What are Pipes and how are they used?**

Pipes transform data in templates. Syntax: `{{ value | pipeName:arg1:arg2 }}`

```html
<!-- Built-in Pipes -->
{{ name | uppercase }}                   <!-- JOHN DOE -->
{{ name | lowercase }}                   <!-- john doe -->
{{ name | titlecase }}                   <!-- John Doe -->

{{ today | date:'dd/MM/yyyy' }}          <!-- 20/05/2026 -->
{{ today | date:'fullDate' }}            <!-- Wednesday, May 20, 2026 -->

{{ 1234.56 | number:'1.2-2' }}          <!-- 1,234.56 -->
{{ 0.85 | percent:'1.0-2' }}            <!-- 85% -->
{{ 1234.56 | currency:'USD':'symbol':'1.2-2' }} <!-- $1,234.56 -->

{{ user | json }}                         <!-- {"name":"Alice","age":30} -->
{{ user | keyvalue }}                     <!-- iterate object as key-value pairs -->

<!-- Async Pipe (auto-subscribes/unsubscribes Observable/Promise) -->
{{ users$ | async | json }}
<div *ngIf="users$ | async as users">
  <p *ngFor="let u of users">{{ u.name }}</p>
</div>

<!-- Chaining pipes -->
{{ title | uppercase | slice:0:10 }}
```

**Q: Custom Pipe?**

```typescript
import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'truncate',
  // pure: false  ← impure: re-runs on every CD cycle (use carefully)
})
export class TruncatePipe implements PipeTransform {
  transform(value: string, limit: number = 50, trail: string = '...'): string {
    if (!value) return '';
    return value.length > limit ? value.substring(0, limit) + trail : value;
  }
}

// Usage: {{ longText | truncate:100:'…' }}
```

**Q: Pure vs Impure Pipe?**

| | Pure | Impure |
|---|---|---|
| `pure` | `true` (default) | `false` |
| Re-runs when | Primitive changes or object reference changes | Every change detection cycle |
| Performance | Good | Can be slow |
| Use case | Most transformations | Filtering arrays, async data |

---

## 13. HTTP Client & API Calls

**Q: How to make HTTP calls in Angular?**

```typescript
// app.module.ts
import { HttpClientModule } from '@angular/common/http';
imports: [HttpClientModule]
```

```typescript
// user.service.ts
import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError, map, retry } from 'rxjs/operators';

export interface User {
  id: number;
  name: string;
  email: string;
}

@Injectable({ providedIn: 'root' })
export class UserService {
  private apiUrl = 'https://api.example.com';

  constructor(private http: HttpClient) {}

  getUsers(): Observable<User[]> {
    const params = new HttpParams().set('page', '1').set('limit', '10');
    return this.http.get<User[]>(`${this.apiUrl}/users`, { params }).pipe(
      map(users => users.filter(u => u.id > 0)),
      retry(2),
      catchError(this.handleError)
    );
  }

  getUserById(id: number): Observable<User> {
    return this.http.get<User>(`${this.apiUrl}/users/${id}`).pipe(
      catchError(this.handleError)
    );
  }

  createUser(user: Omit<User, 'id'>): Observable<User> {
    const headers = new HttpHeaders({ 'Content-Type': 'application/json' });
    return this.http.post<User>(`${this.apiUrl}/users`, user, { headers }).pipe(
      catchError(this.handleError)
    );
  }

  updateUser(id: number, user: Partial<User>): Observable<User> {
    return this.http.put<User>(`${this.apiUrl}/users/${id}`, user).pipe(
      catchError(this.handleError)
    );
  }

  deleteUser(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/users/${id}`).pipe(
      catchError(this.handleError)
    );
  }

  private handleError(error: any): Observable<never> {
    console.error('API Error:', error.status, error.message);
    return throwError(() => new Error(error.message || 'Server error'));
  }
}
```

**Q: HTTP Interceptor?**

Interceptors intercept every request/response — used for auth tokens, error handling, loading indicators.

```typescript
import { Injectable } from '@angular/core';
import {
  HttpInterceptor, HttpRequest, HttpHandler, HttpEvent, HttpErrorResponse
} from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';

@Injectable()
export class AuthInterceptor implements HttpInterceptor {
  constructor(private authService: AuthService) {}

  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    const token = this.authService.getToken();

    // Clone the request and add auth header
    const authReq = req.clone({
      headers: req.headers.set('Authorization', `Bearer ${token}`)
    });

    return next.handle(authReq).pipe(
      catchError((error: HttpErrorResponse) => {
        if (error.status === 401) {
          this.authService.logout();
        }
        return throwError(() => error);
      })
    );
  }
}

// Register in app.module.ts providers:
// { provide: HTTP_INTERCEPTORS, useClass: AuthInterceptor, multi: true }
```

---

## 14. Observables & RxJS

**Q: What is an Observable?**

A stream of data over time that can be subscribed to. Values can be synchronous or asynchronous.

```typescript
import { Observable, Subject, BehaviorSubject, ReplaySubject, of, from, interval, forkJoin } from 'rxjs';
import { map, filter, switchMap, mergeMap, concatMap, exhaustMap,
         debounceTime, distinctUntilChanged, takeUntil, catchError, tap } from 'rxjs/operators';

// Creating Observables
const obs1$ = of(1, 2, 3);                          // emits 1, 2, 3 then complete
const obs2$ = from([1, 2, 3]);                       // from array
const obs3$ = from(Promise.resolve('hello'));        // from promise
const obs4$ = interval(1000);                        // emit every 1s
```

**Q: Subject vs BehaviorSubject vs ReplaySubject?**

```typescript
// Subject – no initial value, late subscribers miss previous emissions
const subject = new Subject<number>();
subject.next(1);  // lost if no subscriber

// BehaviorSubject – has initial value, new subscribers get the latest value
const bs = new BehaviorSubject<number>(0);  // starts with 0
bs.next(1);
bs.subscribe(v => console.log(v));  // immediately logs: 1
const current = bs.getValue();      // synchronous access to current value

// ReplaySubject – buffers N past values for new subscribers
const rs = new ReplaySubject<number>(3);  // replay last 3
rs.next(1); rs.next(2); rs.next(3); rs.next(4);
rs.subscribe(v => console.log(v));  // logs: 2, 3, 4 (last 3)
```

**Q: RxJS Mapping Operators?**

```typescript
// switchMap – cancels previous inner observable when new value arrives
// Use for: search bars, typeahead
searchControl.valueChanges.pipe(
  debounceTime(300),
  distinctUntilChanged(),
  switchMap(query => this.searchService.search(query))
).subscribe(results => this.results = results);

// mergeMap – runs all inner observables concurrently
// Use for: parallel independent requests
from([1, 2, 3]).pipe(
  mergeMap(id => this.userService.getUser(id))
).subscribe(user => console.log(user));

// concatMap – queues inner observables, runs one at a time in order
// Use for: sequential dependent operations
from([1, 2, 3]).pipe(
  concatMap(id => this.orderService.processOrder(id))
).subscribe(result => console.log(result));

// exhaustMap – ignores new values while inner observable is active
// Use for: login button, form submit (prevent double submit)
loginBtn$.pipe(
  exhaustMap(() => this.authService.login(credentials))
).subscribe(response => console.log(response));
```

**Q: forkJoin — parallel API calls?**

```typescript
import { forkJoin } from 'rxjs';

forkJoin({
  users: this.userService.getUsers(),
  products: this.productService.getProducts(),
  orders: this.orderService.getOrders()
}).subscribe(({ users, products, orders }) => {
  // All three calls completed
  this.users = users;
  this.products = products;
  this.orders = orders;
});
```

**Q: How to prevent memory leaks (unsubscribing)?**

```typescript
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

@Component({ selector: 'app-demo', template: '...' })
export class DemoComponent implements OnInit, OnDestroy {
  private destroy$ = new Subject<void>();

  ngOnInit() {
    // Pattern 1: takeUntil (recommended)
    interval(1000).pipe(
      takeUntil(this.destroy$)
    ).subscribe(val => console.log(val));

    this.userService.users$.pipe(
      takeUntil(this.destroy$)
    ).subscribe(users => this.users = users);
  }

  ngOnDestroy() {
    this.destroy$.next();   // triggers takeUntil to complete
    this.destroy$.complete();
  }
}

// Pattern 2: async pipe (auto-unsubscribes, recommended for templates)
// users$ = this.userService.getUsers();
// In template: {{ users$ | async }}
```

---

## 15. Route Guards

**Q: What are Route Guards and their types?**

| Guard | Purpose | Returns |
|---|---|---|
| `canActivate` | Block route access | `boolean \| Observable<boolean>` |
| `canActivateChild` | Block child route access | Same |
| `canDeactivate` | Prevent leaving route | Same |
| `resolve` | Preload data before navigation | `Observable<T>` |
| `canMatch` | Match route conditionally (Angular 15+) | Same |
| `canLoad` | Block lazy module loading (deprecated in v15) | Same |

```typescript
// auth.guard.ts (functional guard - Angular 14+)
import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from './auth.service';

export const authGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (authService.isLoggedIn()) {
    return true;
  }
  return router.createUrlTree(['/login'], {
    queryParams: { returnUrl: state.url }
  });
};

// role.guard.ts
export const roleGuard: CanActivateFn = (route) => {
  const authService = inject(AuthService);
  const requiredRole = route.data['role'] as string;
  return authService.hasRole(requiredRole);
};

// Usage in routes
{
  path: 'admin',
  component: AdminComponent,
  canActivate: [authGuard, roleGuard],
  data: { role: 'admin' }
}
```

```typescript
// canDeactivate guard
export interface CanComponentDeactivate {
  canDeactivate: () => boolean | Observable<boolean>;
}

export const unsavedChangesGuard: CanDeactivateFn<CanComponentDeactivate> = (component) => {
  return component.canDeactivate ? component.canDeactivate() : true;
};

// In component
export class EditComponent implements CanComponentDeactivate {
  hasUnsavedChanges = false;

  canDeactivate(): boolean {
    if (this.hasUnsavedChanges) {
      return confirm('You have unsaved changes. Leave?');
    }
    return true;
  }
}
```

```typescript
// Resolve guard (preload data)
export const userResolver: ResolveFn<User> = (route) => {
  const userService = inject(UserService);
  const id = route.paramMap.get('id')!;
  return userService.getUserById(+id);
};

// Route
{ path: 'user/:id', component: UserComponent, resolve: { user: userResolver } }

// In component
this.route.data.subscribe(({ user }) => {
  this.user = user;
});
```

---

## 16. Change Detection

**Q: What is Change Detection?**

Angular's mechanism to keep the view in sync with the component's data. Triggered by:
- User events (click, input, etc.)
- HTTP responses
- Timer callbacks (setTimeout, setInterval)
- Promises

**Q: Change Detection Strategies?**

```typescript
import { Component, ChangeDetectionStrategy, ChangeDetectorRef, Input } from '@angular/core';

// Default: checks entire component tree on every event
@Component({
  selector: 'app-default',
  changeDetection: ChangeDetectionStrategy.Default,
  template: `{{ counter }}`
})
export class DefaultComponent {
  counter = 0;
}

// OnPush: only checks when @Input reference changes, event fired, async pipe emits
@Component({
  selector: 'app-optimized',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <p>{{ user.name }}</p>
    <p>{{ counter }}</p>
  `
})
export class OptimizedComponent {
  @Input() user!: User;  // must pass new object reference to trigger CD
  counter = 0;

  constructor(private cdr: ChangeDetectorRef) {}

  incrementManually() {
    this.counter++;
    this.cdr.markForCheck();  // manually trigger CD when needed
  }

  detachTemporarily() {
    this.cdr.detach();   // pause CD
    // do heavy work
    this.cdr.detectChanges(); // manually trigger single check
    this.cdr.reattach(); // resume
  }
}
```

**Q: OnPush rules?**

- Pass **new object/array references** (don't mutate)
- Use `async` pipe for observables
- Use `markForCheck()` if you manually mutate data
- Events fired within the component still trigger CD

```typescript
// WRONG with OnPush
this.users.push(newUser);        // same reference, CD won't run

// CORRECT with OnPush
this.users = [...this.users, newUser];  // new reference, CD runs
```

---

## 17. Angular Signals (Angular 16+)

**Q: What are Signals?**

A reactive primitive for fine-grained change detection, replacing Zone.js in the long run.

```typescript
import { Component, signal, computed, effect, Signal } from '@angular/core';

@Component({
  selector: 'app-counter',
  template: `
    <p>Count: {{ count() }}</p>
    <p>Double: {{ doubled() }}</p>
    <button (click)="increment()">+</button>
    <button (click)="decrement()">-</button>
    <button (click)="reset()">Reset</button>
  `
})
export class CounterComponent {
  // Writable signal
  count = signal(0);

  // Computed signal (derived, read-only)
  doubled = computed(() => this.count() * 2);
  isPositive = computed(() => this.count() > 0);

  constructor() {
    // Effect: runs when dependencies change
    effect(() => {
      console.log(`Count changed to: ${this.count()}`);
      // automatically tracks count() as a dependency
    });
  }

  increment() { this.count.update(c => c + 1); }
  decrement() { this.count.update(c => c - 1); }
  reset() { this.count.set(0); }
}
```

```typescript
// Object/Array signals
export class UserListComponent {
  users = signal<User[]>([]);

  addUser(user: User) {
    this.users.update(list => [...list, user]);
  }

  removeUser(id: number) {
    this.users.update(list => list.filter(u => u.id !== id));
  }
}

// Signal from Observable (Angular 16+)
import { toSignal } from '@angular/core/rxjs-interop';

users = toSignal(this.userService.getUsers(), { initialValue: [] });
```

**Q: Signals vs Observables?**

| | Signals | Observables |
|---|---|---|
| Always has value | Yes | No (streams) |
| Synchronous read | Yes | No |
| Lazy | No | Yes |
| Completion | Never | Can complete |
| Best for | UI state | Async events, HTTP |

---

## 18. Standalone Components (Angular 14+)

**Q: What are Standalone Components?**

Components that don't need to be declared in an NgModule — they import their own dependencies.

```typescript
import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { UserService } from './user.service';

@Component({
  standalone: true,                         // no NgModule needed
  selector: 'app-user-list',
  imports: [CommonModule, RouterModule, FormsModule], // direct imports
  providers: [UserService],
  template: `
    <input [(ngModel)]="search" placeholder="Search..." />
    <ul>
      <li *ngFor="let user of users">
        <a [routerLink]="['/user', user.id]">{{ user.name }}</a>
      </li>
    </ul>
  `
})
export class UserListComponent implements OnInit {
  users: User[] = [];
  search = '';

  constructor(private userService: UserService) {}

  ngOnInit() {
    this.userService.getUsers().subscribe(u => this.users = u);
  }
}
```

```typescript
// main.ts for standalone app (Angular 17 default)
import { bootstrapApplication } from '@angular/platform-browser';
import { provideRouter } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';
import { AppComponent } from './app/app.component';
import { routes } from './app/app.routes';

bootstrapApplication(AppComponent, {
  providers: [
    provideRouter(routes),
    provideHttpClient()
  ]
});
```

```typescript
// app.routes.ts
import { Routes } from '@angular/router';

export const routes: Routes = [
  { path: '', loadComponent: () => import('./home/home.component').then(c => c.HomeComponent) },
  { path: 'users', loadComponent: () => import('./users/user-list.component').then(c => c.UserListComponent) }
];
```

---

## 19. Performance Optimization

**Q: Key Angular performance techniques?**

### 1. OnPush Change Detection
```typescript
@Component({ changeDetection: ChangeDetectionStrategy.OnPush })
```

### 2. trackBy in *ngFor
```typescript
// Without: re-renders entire list on any change
// With: only re-renders changed items
<li *ngFor="let item of items; trackBy: trackById">
trackById = (i: number, item: Item) => item.id;
```

### 3. Lazy Loading
```typescript
loadChildren: () => import('./feature/feature.module').then(m => m.FeatureModule)
```

### 4. Async Pipe (auto-unsubscribe)
```html
<div *ngFor="let user of users$ | async">{{ user.name }}</div>
```

### 5. Pure Pipes instead of methods
```html
<!-- BAD: getFormattedDate() called on every CD cycle -->
{{ getFormattedDate(user.createdAt) }}

<!-- GOOD: pure pipe only runs when input reference changes -->
{{ user.createdAt | date:'dd/MM/yyyy' }}
```

### 6. takeUntil for Subscription Cleanup
```typescript
private destroy$ = new Subject<void>();
observable$.pipe(takeUntil(this.destroy$)).subscribe();
ngOnDestroy() { this.destroy$.next(); this.destroy$.complete(); }
```

### 7. Virtual Scrolling (large lists)
```typescript
import { ScrollingModule } from '@angular/cdk/scrolling';

// template:
<cdk-virtual-scroll-viewport itemSize="50" class="viewport">
  <div *cdkVirtualFor="let item of items">{{ item }}</div>
</cdk-virtual-scroll-viewport>
```

### 8. PreloadingStrategy
```typescript
RouterModule.forRoot(routes, { preloadingStrategy: PreloadAllModules })
```

---

## 20. Common Interview Q&A

**Q: What is the difference between `==` and `===` in TypeScript?**
`==` checks value with type coercion; `===` checks value AND type (use `===`).

---

**Q: What is the difference between interface and type in TypeScript?**
```typescript
interface User { name: string; age: number; }       // can be extended/merged
type UserType = { name: string; age: number; };      // cannot be re-declared

interface Admin extends User { role: string; }
type AdminType = UserType & { role: string; };
```

---

**Q: What happens when both constructor and ngOnInit exist?**
Order: `constructor()` → `ngOnChanges()` → `ngOnInit()`.
Constructor is for DI only; `ngOnInit` for initialization logic.

---

**Q: Why should we not use functions in templates?**
Functions are called on every change detection cycle.
Use computed properties, pure pipes, or `ChangeDetectionStrategy.OnPush` instead.

---

**Q: What is ViewEncapsulation?**
```typescript
@Component({
  encapsulation: ViewEncapsulation.Emulated  // default – scoped styles (pseudo-shadow DOM)
  // ViewEncapsulation.None     – global styles
  // ViewEncapsulation.ShadowDom – native shadow DOM
})
```

---

**Q: What is `ng-content`?**
Content projection — passes DOM from parent into child.
```html
<!-- child component template -->
<div class="card">
  <ng-content select="[card-header]"></ng-content>
  <ng-content></ng-content>
</div>

<!-- parent -->
<app-card>
  <h2 card-header>Title</h2>
  <p>Body content</p>
</app-card>
```

---

**Q: What is `ng-template` and `ng-container`?**
```html
<!-- ng-template: defines reusable template fragments (not rendered by default) -->
<ng-template #loading>
  <p>Loading...</p>
</ng-template>

<div *ngIf="isLoaded; else loading">Content</div>

<!-- ng-container: grouping without extra DOM element -->
<ng-container *ngIf="isAdmin">
  <button>Edit</button>
  <button>Delete</button>
</ng-container>
```

---

**Q: How does async pipe help?**
- Auto-subscribes to Observable/Promise
- Auto-unsubscribes when component is destroyed (prevents memory leaks)
- Triggers change detection when value emits

---

**Q: Difference between Subject and BehaviorSubject?**
- `Subject`: no initial value, late subscribers miss past emissions
- `BehaviorSubject`: requires initial value, new subscribers immediately get the latest value
- Use `BehaviorSubject` for state management (current app state)

---

**Q: What is forRoot() and forChild()?**
```typescript
// forRoot() – use ONCE in AppModule, sets up singleton services + routes
RouterModule.forRoot(routes)

// forChild() – use in feature modules, no singleton re-registration
RouterModule.forChild(featureRoutes)
```

---

**Q: How to share data between sibling components?**
1. **Shared Service** with `BehaviorSubject` (recommended)
2. **Parent as mediator** — parent receives via `@Output`, passes via `@Input`
3. **NgRx / State management** for complex apps

---

**Q: What is Zone.js?**
Zone.js patches async browser APIs (setTimeout, Promises, XHR) to notify Angular when to run change detection. Angular 17+ introduces Zoneless mode with Signals.

---

**Q: What is Tree Shaking?**
Build optimization that removes unused code. Angular's ahead-of-time (AOT) compilation + tree shaking eliminates unused components/services from the final bundle.

---

**Q: AOT vs JIT compilation?**

| | JIT (Just-In-Time) | AOT (Ahead-Of-Time) |
|---|---|---|
| When | At runtime in browser | At build time |
| Bundle size | Larger (compiler included) | Smaller |
| Performance | Slower startup | Faster startup |
| Errors | At runtime | At build time |
| Default | dev mode | prod mode (`ng build`) |

---

**Q: What is Dependency Injection hierarchy?**

```
Root Injector (providedIn: 'root')
  └── Module Injector (providers in @NgModule)
        └── Component Injector (providers in @Component)
              └── Element Injector (directives)
```
Angular looks up the injector tree from child to parent to resolve dependencies.

---

**Q: Explain content projection with multi-slot?**
```html
<!-- card.component.html -->
<div class="card">
  <div class="header">
    <ng-content select="[slot=header]"></ng-content>
  </div>
  <div class="body">
    <ng-content select="[slot=body]"></ng-content>
  </div>
  <div class="footer">
    <ng-content select="[slot=footer]"></ng-content>  
  </div>
</div>

<!-- parent usage -->
<app-card>
  <h2 slot="header">Card Title</h2>
  <p slot="body">Card content goes here</p>
  <button slot="footer">Action</button>
</app-card>
```

---

**Q: What is a Resolver and why use it?**
Resolves data BEFORE the route activates, so the component always receives loaded data (no loading spinners needed in the component).

```typescript
export const productResolver: ResolveFn<Product> = (route) => {
  return inject(ProductService).getProduct(route.params['id']);
};
// Route: { path: ':id', component: ProductComponent, resolve: { product: productResolver } }
// Component: this.product = this.route.snapshot.data['product'];
```

---

**Q: How does lazy loading improve performance?**
- Splits the app into separate bundles
- Initial bundle is smaller → faster first load
- Feature modules download only when the user navigates to them

---

**Q: What is the difference between `switchMap`, `mergeMap`, `concatMap`, `exhaustMap`?**

| Operator | Behavior | Use Case |
|---|---|---|
| `switchMap` | Cancels previous, takes latest | Search/typeahead |
| `mergeMap` | Runs all concurrently | Parallel requests |
| `concatMap` | Queues, runs in order | Sequential operations |
| `exhaustMap` | Ignores new while busy | Login/form submit |

---

**Q: What new features came in recent Angular versions?**

- **Angular 14**: Standalone components, typed reactive forms
- **Angular 15**: Functional route guards (`CanActivateFn`), directive composition, `canMatch`
- **Angular 16**: Signals, `DestroyRef`, `takeUntilDestroyed()`, required inputs
- **Angular 17**: New control flow (`@if`, `@for`, `@switch`), `defer` blocks, Signals stable, standalone default
- **Angular 18+**: Zoneless change detection, Signal-based components

```html
<!-- Angular 17+ new control flow syntax -->
@if (isLoggedIn) {
  <p>Welcome {{ user.name }}</p>
} @else {
  <p>Please log in</p>
}

@for (user of users; track user.id) {
  <li>{{ user.name }}</li>
} @empty {
  <li>No users found</li>
}

@switch (role) {
  @case ('admin') { <app-admin /> }
  @case ('user') { <app-dashboard /> }
  @default { <app-guest /> }
}

<!-- Deferrable views -->
@defer (on viewport) {
  <app-heavy-component />
} @placeholder {
  <p>Loading...</p>
}
```

---

> **Tip for interviews**: Always relate concepts to real use cases — "I use `switchMap` for search because it cancels stale HTTP requests", "I use `OnPush` + immutable updates to prevent performance issues in large lists", "I prefer `async` pipe over manual subscriptions to prevent memory leaks."

---

# Exception Handling in Angular — Interview Ready

## 1. Local `try/catch` (Synchronous)

The most basic form — use for synchronous code or `async/await`.

```typescript
getData() {
  try {
    const result = JSON.parse(someString); // risky op
    return result;
  } catch (error) {
    console.error('Parsing failed:', error);
    return null;
  }
}

// With async/await
async fetchUser(id: number) {
  try {
    const user = await this.http.get(`/api/user/${id}`).toPromise();
    return user;
  } catch (error) {
    this.notificationService.show('Failed to load user');
    throw error; // re-throw if caller needs to know
  }
}
```

> **Interview point:** `try/catch` does NOT catch errors inside RxJS Observables — that needs `catchError`.

---

## 2. RxJS `catchError` (Observable Streams)

The primary way to handle HTTP/stream errors in Angular services and components.

```typescript
// In a service
getUsers(): Observable<User[]> {
  return this.http.get<User[]>('/api/users').pipe(
    catchError((error: HttpErrorResponse) => {
      if (error.status === 404) {
        return of([]); // graceful fallback
      }
      return throwError(() => new Error('Server error'));
    })
  );
}

// In a component
this.userService.getUsers().subscribe({
  next: (users) => this.users = users,
  error: (err) => this.errorMessage = err.message
});
```

> **Interview point:** Always return `of(fallback)` or `throwError(...)` from `catchError` — never return `void`, or the stream breaks.

---

## 3. `HttpInterceptor` — Centralized HTTP Error Handling

The **industry-standard** approach. One place handles all HTTP errors globally.

```typescript
@Injectable()
export class ErrorInterceptor implements HttpInterceptor {
  constructor(private authService: AuthService, private router: Router) {}

  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    return next.handle(req).pipe(
      catchError((error: HttpErrorResponse) => {
        switch (error.status) {
          case 401:
            this.authService.logout();
            this.router.navigate(['/login']);
            break;
          case 403:
            this.router.navigate(['/forbidden']);
            break;
          case 500:
            this.router.navigate(['/server-error']);
            break;
        }
        return throwError(() => error);
      })
    );
  }
}

// Register in app.module.ts
providers: [
  { provide: HTTP_INTERCEPTORS, useClass: ErrorInterceptor, multi: true }
]
```

> **Interview point:** `multi: true` is mandatory — it appends to the interceptor chain instead of replacing it.

---

## 4. `GlobalErrorHandler` — Uncaught Runtime Errors

Catches anything that slips through — null refs, type errors, unhandled promise rejections.

```typescript
@Injectable()
export class GlobalErrorHandler implements ErrorHandler {
  constructor(private injector: Injector) {}

  handleError(error: any): void {
    const router = this.injector.get(Router);

    if (error instanceof HttpErrorResponse) {
      // HTTP errors (already handled by interceptor usually)
      console.error('HTTP Error:', error.message);
    } else {
      // Client-side runtime errors
      console.error('Unexpected Error:', error);
      router.navigate(['/error']);
    }

    // Optionally push to monitoring (Sentry, Datadog)
    // this.monitoringService.logError(error);
  }
}

// Register in app.module.ts
providers: [
  { provide: ErrorHandler, useClass: GlobalErrorHandler }
]
```

> **Interview point:** Use `Injector` here instead of direct constructor injection — `ErrorHandler` is instantiated before most services, causing circular dependency issues.

---

## 5. `subscribe()` Error Callback

Component-level stream error handling — the `error` callback in subscribe.

```typescript
// Old style (avoid)
this.service.getData().subscribe(
  data => this.data = data,
  error => this.handleError(error)  // ⚠️ deprecated positional args
);

// Modern style (Angular 14+)
this.service.getData().subscribe({
  next: (data) => this.data = data,
  error: (err) => {
    this.isLoading = false;
    this.errorMsg = err.message;
  },
  complete: () => this.isLoading = false
});
```

---

## 6. `retry` / `retryWhen` — Transient Failures

For network blips, retry before showing an error.

```typescript
import { retry, catchError } from 'rxjs/operators';

getOrders(): Observable<Order[]> {
  return this.http.get<Order[]>('/api/orders').pipe(
    retry({ count: 3, delay: 1000 }),  // retry 3x with 1s delay
    catchError(err => {
      this.notify.error('Orders unavailable after 3 retries');
      return of([]);
    })
  );
}
```

---

## 7. Template-Level Error Handling (`*ngIf` + error state)

Surface errors to the user in the template.

```typescript
// Component
errorMessage: string | null = null;
isLoading = false;

loadData() {
  this.isLoading = true;
  this.service.getData().subscribe({
    next: (data) => { this.data = data; this.isLoading = false; },
    error: (err) => { this.errorMessage = err.message; this.isLoading = false; }
  });
}
```

```html
<div *ngIf="isLoading">Loading...</div>
<div *ngIf="errorMessage" class="error-banner">{{ errorMessage }}</div>
<div *ngIf="!isLoading && !errorMessage">
  <!-- actual content -->
</div>
```

---

## 8. Route-Level Error Handling (`Resolve` + Guards)

Handle errors before the route even activates.

```typescript
@Injectable({ providedIn: 'root' })
export class UserResolver implements Resolve<User> {
  resolve(route: ActivatedRouteSnapshot): Observable<User> {
    return this.userService.getUser(route.params['id']).pipe(
      catchError(() => {
        this.router.navigate(['/not-found']);
        return EMPTY; // prevent route activation
      })
    );
  }
}
```

---

## The Complete Mental Map

```
HTTP Error (4xx/5xx)
    └── HttpInterceptor          ← centralized, auth/redirect logic

Observable stream error
    └── catchError in pipe()     ← service/component level fallback
    └── subscribe({ error })     ← component-level UI feedback

Uncaught runtime error (null ref, etc.)
    └── GlobalErrorHandler       ← last resort, logging/monitoring

Transient network failure
    └── retry()                  ← before catchError

Route data failure
    └── Resolver + EMPTY         ← prevent broken page activation

User-visible errors
    └── Template *ngIf + state   ← UX layer
```

---

## Key Interview Q&A

**Q: Difference between `catchError` and `subscribe({ error })`?**
`catchError` is in the pipeline — it can recover and keep the stream alive. `subscribe error` is terminal — the stream is already dead.

**Q: Why use `Injector` in `GlobalErrorHandler`?**
Angular initializes `ErrorHandler` very early, before the DI tree is ready. Direct injection causes circular dependency. `Injector.get()` defers resolution to runtime.

**Q: Can `HttpInterceptor` and `GlobalErrorHandler` both fire?**
Yes, if the interceptor re-throws with `throwError(...)`, it propagates up and `GlobalErrorHandler` catches it. Design them to have distinct responsibilities.

**Q: What does `EMPTY` do in a resolver?**
It completes the Observable without emitting — the route never activates, avoiding a broken view.

---

# Missing Topics — Angular Interview Supplement

---

## 21. State Management

**Q: How to manage shared state in Angular?**

For simple apps use a `BehaviorSubject` service. For complex apps use NgRx.

```typescript
// Simple state service (recommended for most apps)
@Injectable({ providedIn: 'root' })
export class CartStateService {
  private cartItems = new BehaviorSubject<CartItem[]>([]);
  cartItems$ = this.cartItems.asObservable();
  cartCount$ = this.cartItems$.pipe(map(items => items.length));
  cartTotal$ = this.cartItems$.pipe(
    map(items => items.reduce((sum, item) => sum + item.price, 0))
  );

  addItem(item: CartItem) {
    this.cartItems.next([...this.cartItems.getValue(), item]);
  }

  removeItem(id: number) {
    this.cartItems.next(this.cartItems.getValue().filter(i => i.id !== id));
  }

  clearCart() {
    this.cartItems.next([]);
  }
}

// In component
@Component({ template: `
  <p>Items: {{ cartCount$ | async }}</p>
  <p>Total: {{ cartTotal$ | async | currency }}</p>
`})
export class HeaderComponent {
  cartCount$ = this.cartState.cartCount$;
  cartTotal$ = this.cartState.cartTotal$;

  constructor(private cartState: CartStateService) {}
}
```

> **Interview point:** BehaviorSubject service is sufficient for most Angular apps. NgRx adds boilerplate — justify it only for large teams or complex state flows.

---

## 22. Memory Leak Prevention

**Q: What causes memory leaks and how to prevent them?**

```typescript
// Problem: manual subscriptions not cleaned up
@Component({ template: `{{ data }}` })
export class LeakyComponent implements OnInit {
  data: any;

  ngOnInit() {
    // ❌ This subscription lives forever even after component destroys
    interval(1000).subscribe(v => this.data = v);
  }
}

// Fix 1: takeUntilDestroyed (Angular 16+ — cleanest approach)
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

@Component({ template: `{{ data }}` })
export class CleanComponent {
  data: any;

  constructor() {
    interval(1000).pipe(
      takeUntilDestroyed()  // auto-links to component lifecycle
    ).subscribe(v => this.data = v);
  }
}

// Fix 2: DestroyRef (Angular 16+)
export class CleanComponent implements OnInit {
  constructor(private destroyRef: DestroyRef) {}

  ngOnInit() {
    const sub = interval(1000).subscribe(v => console.log(v));
    this.destroyRef.onDestroy(() => sub.unsubscribe());
  }
}

// Fix 3: async pipe in template (always preferred)
// users$ = this.userService.getUsers();
// Template: {{ users$ | async }}
```

> **Interview point:** `takeUntilDestroyed()` is the modern Angular 16+ standard. `async` pipe is always preferred over manual subscriptions in templates.

---

## 23. Component Communication Patterns

**Q: All ways to communicate between components?**

```typescript
// 1. @Input / @Output (Parent ↔ Child) — covered in section 3

// 2. Shared Service with BehaviorSubject (Sibling / Any)
// — covered in section 21

// 3. ViewChild — Parent accesses child directly
@Component({ template: `<app-child #child></app-child>` })
export class ParentComponent {
  @ViewChild('child') child!: ChildComponent;

  callChildMethod() {
    this.child.doSomething(); // direct method call
  }
}

// 4. EventEmitter via service (publish/subscribe)
@Injectable({ providedIn: 'root' })
export class EventBusService {
  private eventSubject = new Subject<{ type: string; payload: any }>();
  events$ = this.eventSubject.asObservable();

  emit(type: string, payload: any) {
    this.eventSubject.next({ type, payload });
  }
}

// Publisher
this.eventBus.emit('USER_UPDATED', { id: 1, name: 'Alice' });

// Subscriber (any component)
this.eventBus.events$.pipe(
  filter(e => e.type === 'USER_UPDATED'),
  takeUntilDestroyed()
).subscribe(e => this.user = e.payload);

// 5. Router — pass data via state
this.router.navigate(['/detail'], { state: { product } });
// Receive:
const product = history.state.product;
```

---

## 24. Dynamic Components

**Q: How to create components dynamically at runtime?**

```typescript
// Angular 13+ (ViewContainerRef approach)
@Component({
  template: `
    <button (click)="loadChart()">Load Chart</button>
    <ng-container #container></ng-container>
  `
})
export class DashboardComponent {
  @ViewChild('container', { read: ViewContainerRef }) container!: ViewContainerRef;

  async loadChart() {
    const { ChartComponent } = await import('./chart/chart.component');
    this.container.clear();
    const ref = this.container.createComponent(ChartComponent);
    ref.instance.data = [1, 2, 3]; // pass inputs
    ref.instance.title = 'Sales';
  }
}
```

> **Interview point:** Used for modals, tooltips, dynamic dashboards, and plugin-style UIs. Pair with lazy import for best performance.

---

## 25. Angular CLI & Build

**Q: Important Angular CLI commands?**

```bash
ng new my-app --standalone          # create new standalone app
ng generate component user          # create component (ng g c user)
ng generate service user            # create service (ng g s user)
ng generate guard auth              # create guard (ng g g auth)
ng generate pipe truncate           # create pipe
ng generate module admin --routing  # create module with routing

ng serve                            # dev server (localhost:4200)
ng serve --port 4300                # custom port
ng build                            # build for production
ng build --configuration=staging    # custom env
ng test                             # run unit tests (Karma/Jest)
ng e2e                              # end-to-end tests
ng lint                             # run ESLint
ng update @angular/core @angular/cli # update Angular
```

**Q: What is the purpose of `angular.json`?**

Configures build targets, environments, assets, styles, scripts, and output paths.

```json
{
  "projects": {
    "my-app": {
      "architect": {
        "build": {
          "configurations": {
            "production": { "optimization": true, "sourceMap": false },
            "staging": { "fileReplacements": [{ "replace": "environment.ts", "with": "environment.staging.ts" }] }
          }
        }
      }
    }
  }
}
```

---

## 26. Testing (Unit Testing)

**Q: How to test Angular components and services?**

```typescript
// Component test
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';

describe('UserComponent', () => {
  let component: UserComponent;
  let fixture: ComponentFixture<UserComponent>;
  let userService: jasmine.SpyObj<UserService>;

  beforeEach(async () => {
    const spy = jasmine.createSpyObj('UserService', ['getUsers']);

    await TestBed.configureTestingModule({
      declarations: [UserComponent],
      providers: [{ provide: UserService, useValue: spy }]
    }).compileComponents();

    fixture = TestBed.createComponent(UserComponent);
    component = fixture.componentInstance;
    userService = TestBed.inject(UserService) as jasmine.SpyObj<UserService>;
  });

  it('should display users from service', () => {
    userService.getUsers.and.returnValue(of([{ id: 1, name: 'Alice' }]));

    fixture.detectChanges(); // triggers ngOnInit

    const items = fixture.debugElement.queryAll(By.css('li'));
    expect(items.length).toBe(1);
    expect(items[0].nativeElement.textContent).toContain('Alice');
  });

  it('should show error message on failure', () => {
    userService.getUsers.and.returnValue(throwError(() => new Error('API down')));
    fixture.detectChanges();

    const error = fixture.debugElement.query(By.css('.error'));
    expect(error.nativeElement.textContent).toContain('API down');
  });
});

// Service test
describe('UserService', () => {
  let service: UserService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [UserService]
    });
    service = TestBed.inject(UserService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => httpMock.verify()); // ensure no outstanding requests

  it('should GET users', () => {
    service.getUsers().subscribe(users => {
      expect(users.length).toBe(2);
    });

    const req = httpMock.expectOne('/api/users');
    expect(req.request.method).toBe('GET');
    req.flush([{ id: 1, name: 'Alice' }, { id: 2, name: 'Bob' }]);
  });
});
```

> **Interview point:** Use `HttpClientTestingModule` + `HttpTestingController` for HTTP service tests. Use `jasmine.createSpyObj` to mock dependencies in component tests.

---

## 27. `DestroyRef` & `takeUntilDestroyed` (Angular 16+)

**Q: What is DestroyRef?**

A DI token that lets you register cleanup callbacks tied to a component/directive/service lifecycle — without implementing `OnDestroy`.

```typescript
@Component({ template: '' })
export class MyComponent {
  constructor(private destroyRef: DestroyRef) {
    // Register any cleanup
    this.destroyRef.onDestroy(() => {
      console.log('Component destroyed — cleanup here');
    });
  }
}

// takeUntilDestroyed() uses DestroyRef internally
@Component({ template: '' })
export class MyComponent {
  users: User[] = [];

  constructor(private userService: UserService) {
    this.userService.getUsers().pipe(
      takeUntilDestroyed() // no ngOnDestroy needed
    ).subscribe(users => this.users = users);
  }
}
```

---

## 28. `@defer` Blocks (Angular 17+)

**Q: What is `@defer` and when to use it?**

Lazy-loads a component template chunk only when needed — great for below-the-fold content.

```html
<!-- Load when element enters viewport -->
@defer (on viewport) {
  <app-heavy-chart [data]="chartData" />
} @placeholder {
  <div class="skeleton" style="height:300px"></div>
} @loading (minimum 500ms) {
  <app-spinner />
} @error {
  <p>Failed to load chart.</p>
}

<!-- Load after 2 seconds idle -->
@defer (on idle; after 2s) {
  <app-recommendations />
}

<!-- Load on user interaction -->
@defer (on interaction) {
  <app-comments />
}

<!-- Load when condition is true -->
@defer (when isLoggedIn) {
  <app-user-dashboard />
}
```

> **Interview point:** `@defer` is Angular's answer to React's `Suspense`. It splits the bundle automatically — no manual `loadComponent` needed.

---

## 29. Environment Configuration

**Q: How to manage environments in Angular?**

```typescript
// src/environments/environment.ts (dev)
export const environment = {
  production: false,
  apiUrl: 'http://localhost:3000/api',
  featureFlag: true
};

// src/environments/environment.prod.ts
export const environment = {
  production: true,
  apiUrl: 'https://api.myapp.com',
  featureFlag: false
};

// In service — same import works in all environments
import { environment } from '../environments/environment';

@Injectable({ providedIn: 'root' })
export class ApiService {
  private baseUrl = environment.apiUrl;

  getUsers() {
    return this.http.get(`${this.baseUrl}/users`);
  }
}
```

```json
// angular.json — file replacement at build time
"fileReplacements": [
  { "replace": "src/environments/environment.ts",
    "with": "src/environments/environment.prod.ts" }
]
```

> Build: `ng build --configuration=production` swaps the file automatically.


---

## 30. Interceptors — Advanced Patterns

**Q: How to add a loading spinner via interceptor?**

```typescript
@Injectable()
export class LoadingInterceptor implements HttpInterceptor {
  private activeRequests = 0;

  constructor(private loadingService: LoadingService) {}

  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    if (this.activeRequests === 0) this.loadingService.show();
    this.activeRequests++;

    return next.handle(req).pipe(
      finalize(() => {
        this.activeRequests--;
        if (this.activeRequests === 0) this.loadingService.hide();
      })
    );
  }
}
```

**Q: How to clone and modify a request?**

```typescript
// Requests are immutable — always clone
const modified = req.clone({
  url: req.url.replace('http://', 'https://'),
  setHeaders: { Authorization: `Bearer ${token}` },
  setParams: { version: 'v2' }
});
return next.handle(modified);
```

> **Interview point:** Interceptors run in order of registration for requests, and in reverse order for responses.

---

## 31. `@HostListener` vs `fromEvent` (RxJS)

**Q: When to use each for DOM events?**

```typescript
// @HostListener — simple, declarative, directive-friendly
@Directive({ selector: '[appClickTrack]' })
export class ClickTrackDirective {
  @HostListener('click', ['$event'])
  onClick(event: MouseEvent) {
    console.log('Clicked at', event.clientX, event.clientY);
  }

  @HostListener('window:scroll', ['$event'])
  onScroll() {
    console.log('Window scrolled');
  }
}

// fromEvent — use when you need RxJS operators (debounce, filter, etc.)
@Component({ template: `<input #searchInput />` })
export class SearchComponent implements AfterViewInit {
  @ViewChild('searchInput') inputRef!: ElementRef;

  ngAfterViewInit() {
    fromEvent<InputEvent>(this.inputRef.nativeElement, 'input').pipe(
      debounceTime(300),
      map(e => (e.target as HTMLInputElement).value),
      distinctUntilChanged(),
      switchMap(query => this.searchService.search(query)),
      takeUntilDestroyed(this.destroyRef)
    ).subscribe(results => this.results = results);
  }
}
```

---

## 32. Renderer2 vs Direct DOM Access

**Q: Why use Renderer2 instead of direct `nativeElement` manipulation?**

```typescript
// ❌ Direct DOM — breaks SSR (Angular Universal), unsafe
constructor(private el: ElementRef) {}
ngOnInit() {
  this.el.nativeElement.style.color = 'red'; // not SSR safe
}

// ✅ Renderer2 — SSR safe, platform-agnostic
constructor(private el: ElementRef, private renderer: Renderer2) {}
ngOnInit() {
  this.renderer.setStyle(this.el.nativeElement, 'color', 'red');
  this.renderer.addClass(this.el.nativeElement, 'active');
  this.renderer.setAttribute(this.el.nativeElement, 'aria-label', 'Close');
  this.renderer.listen(this.el.nativeElement, 'click', () => console.log('clicked'));
}
```

> **Interview point:** Renderer2 abstracts the DOM — works in server-side rendering (SSR), web workers, and native mobile environments.

---

## 33. Angular Universal (SSR)

**Q: What is Angular Universal?**

Server-Side Rendering (SSR) for Angular — the server pre-renders HTML and sends it to the browser.

```typescript
// Add SSR to existing app
ng add @angular/ssr

// Check for platform in code (avoid browser-only APIs in SSR)
import { isPlatformBrowser, isPlatformServer } from '@angular/common';
import { PLATFORM_ID } from '@angular/core';

@Component({ template: '' })
export class MyComponent {
  constructor(@Inject(PLATFORM_ID) private platformId: Object) {
    if (isPlatformBrowser(this.platformId)) {
      // localStorage, window, navigator — browser only
      localStorage.setItem('key', 'value');
    }
    if (isPlatformServer(this.platformId)) {
      // server-side logic
    }
  }
}
```

**Benefits:** Faster First Contentful Paint (FCP), better SEO (crawlers see full HTML), social media previews.

---

## 34. `ng-template`, `TemplateRef`, `ViewContainerRef`

**Q: How to render templates programmatically?**

```typescript
@Component({
  template: `
    <ng-template #errorTpl let-msg="message">
      <div class="alert">⚠️ {{ msg }}</div>
    </ng-template>

    <ng-template #successTpl let-msg="message">
      <div class="success">✅ {{ msg }}</div>
    </ng-template>

    <ng-container #outlet></ng-container>
    <button (click)="showError()">Show Error</button>
    <button (click)="showSuccess()">Show Success</button>
  `
})
export class NotificationComponent {
  @ViewChild('errorTpl') errorTpl!: TemplateRef<any>;
  @ViewChild('successTpl') successTpl!: TemplateRef<any>;
  @ViewChild('outlet', { read: ViewContainerRef }) outlet!: ViewContainerRef;

  showError() {
    this.outlet.clear();
    this.outlet.createEmbeddedView(this.errorTpl, { message: 'Something went wrong!' });
  }

  showSuccess() {
    this.outlet.clear();
    this.outlet.createEmbeddedView(this.successTpl, { message: 'Saved successfully!' });
  }
}
```

> **Interview point:** This pattern powers reusable modal/toast libraries — the caller passes a `TemplateRef`, the library renders it inside a `ViewContainerRef`.

---

## 35. Reactive Forms — `valueChanges` & `statusChanges`

**Q: How to react to form field changes programmatically?**

```typescript
@Component({ template: '' })
export class FilterComponent implements OnInit {
  filterForm = this.fb.group({
    search: [''],
    category: ['all'],
    priceMin: [0],
    priceMax: [1000]
  });

  ngOnInit() {
    // React to any form change
    this.filterForm.valueChanges.pipe(
      debounceTime(300),
      distinctUntilChanged((a, b) => JSON.stringify(a) === JSON.stringify(b)),
      takeUntilDestroyed(this.destroyRef)
    ).subscribe(filters => this.applyFilters(filters));

    // React to a single control
    this.filterForm.get('category')!.valueChanges.pipe(
      takeUntilDestroyed(this.destroyRef)
    ).subscribe(cat => this.loadCategoryData(cat));

    // React to validity changes
    this.filterForm.statusChanges.subscribe(status => {
      // status: 'VALID' | 'INVALID' | 'PENDING' | 'DISABLED'
      this.isFormReady = status === 'VALID';
    });

    // Programmatically set value without triggering valueChanges
    this.filterForm.setValue({ search: '', category: 'all', priceMin: 0, priceMax: 1000 },
      { emitEvent: false }
    );
  }

  applyFilters(filters: any) { /* call API */ }
  loadCategoryData(cat: string) { /* load category */ }
}
```

---

## 36. Internationalization (i18n)

**Q: How does Angular handle i18n?**

```html
<!-- Mark text for translation with i18n attribute -->
<h1 i18n="@@welcomeTitle">Welcome to our app</h1>
<p i18n>Hello, {{ username }}!</p>
<button i18n="submit button|Action button@@submitBtn">Submit</button>
```

```bash
# Extract translation messages
ng extract-i18n --output-path src/locale

# Generates messages.xlf — translate into messages.fr.xlf, messages.de.xlf etc.

# Build for specific locale
ng build --localize
ng serve --configuration=fr
```

```typescript
// angular.json
"i18n": {
  "sourceLocale": "en-US",
  "locales": {
    "fr": "src/locale/messages.fr.xlf",
    "de": "src/locale/messages.de.xlf"
  }
}
```

> **Interview point:** Angular's built-in i18n compiles a separate bundle per locale at build time. For runtime language switching, use `ngx-translate` library instead.

---

## 37. Security in Angular

**Q: How does Angular protect against XSS?**

Angular automatically sanitizes values bound to the DOM. Known as **template security**.

```typescript
import { DomSanitizer, SafeHtml, SafeUrl } from '@angular/platform-browser';

@Component({
  template: `
    <!-- Angular auto-escapes this — XSS safe -->
    <p>{{ userInput }}</p>

    <!-- [innerHTML] sanitizes HTML automatically -->
    <div [innerHTML]="htmlContent"></div>

    <!-- If you TRUST the content (use carefully) -->
    <div [innerHTML]="trustedHtml"></div>
    <img [src]="trustedUrl" />
  `
})
export class SecurityComponent {
  userInput = '<script>alert("xss")</script>'; // rendered as text, not executed
  htmlContent = '<b>Bold text</b>'; // safe HTML, rendered
  trustedHtml: SafeHtml;
  trustedUrl: SafeUrl;

  constructor(private sanitizer: DomSanitizer) {
    // Only use bypassSecurity if you 100% control the content
    this.trustedHtml = this.sanitizer.bypassSecurityTrustHtml('<b>Trusted</b>');
    this.trustedUrl = this.sanitizer.bypassSecurityTrustUrl('https://trusted.com/img.png');
  }
}
```

**CSRF Protection:**
```typescript
// Angular's HttpClient reads XSRF-TOKEN cookie and sends as X-XSRF-TOKEN header automatically
// Enable in module:
imports: [HttpClientXsrfModule.withOptions({
  cookieName: 'XSRF-TOKEN',
  headerName: 'X-XSRF-TOKEN'
})]
```

> **Interview point:** Angular's XSS protection is on by default — never use `bypassSecurityTrust*` on user input. Only use it on content you generate yourself.

---

## 38. Signal-based Inputs & Outputs (Angular 17.1+)

**Q: What are signal-based inputs?**

New API — inputs are signals instead of decorated properties.

```typescript
import { Component, input, output, model } from '@angular/core';

@Component({
  selector: 'app-user-card',
  template: `
    <h2>{{ name() }}</h2>
    <p>Role: {{ role() }}</p>
    <p>Status: {{ isActive() ? 'Active' : 'Inactive' }}</p>
    <button (click)="toggle()">Toggle</button>
  `
})
export class UserCardComponent {
  // Signal inputs (replaces @Input)
  name = input.required<string>();         // required input
  role = input<string>('user');            // optional with default
  isActive = model<boolean>(false);        // two-way bindable signal

  // Signal output (replaces @Output EventEmitter)
  userClicked = output<string>();

  toggle() {
    this.isActive.update(v => !v);         // update model signal
    this.userClicked.emit(this.name());
  }
}

// Parent usage
// <app-user-card [name]="'Alice'" [(isActive)]="activeState" (userClicked)="onUser($event)" />
```

> **Interview point:** Signal inputs are more performant — they're compatible with `ChangeDetectionStrategy.OnPush` without needing `markForCheck()`. `model()` replaces the `@Input` + `@Output` two-way binding pattern.

---

## 39. Route Data & Static Data Passing

**Q: How to pass static data to routes?**

```typescript
// Route definition
const routes: Routes = [
  {
    path: 'admin',
    component: AdminComponent,
    data: {
      title: 'Admin Panel',
      role: 'admin',
      breadcrumb: 'Administration'
    }
  }
];

// In component — read route data
@Component({ template: `<h1>{{ title }}</h1>` })
export class AdminComponent implements OnInit {
  title = '';

  constructor(private route: ActivatedRoute) {}

  ngOnInit() {
    this.title = this.route.snapshot.data['title'];

    // Or observable for child routes
    this.route.data.subscribe(data => {
      this.title = data['title'];
    });
  }
}

// Practical use: dynamic page titles
@Injectable({ providedIn: 'root' })
export class TitleService {
  constructor(private router: Router, private title: Title) {
    this.router.events.pipe(
      filter(e => e instanceof NavigationEnd),
      map(() => {
        let route = this.router.routerState.snapshot.root;
        while (route.firstChild) route = route.firstChild;
        return route.data['title'] || 'My App';
      })
    ).subscribe(title => this.title.setTitle(title));
  }
}
```

---

## 40. Injection Tokens & Multi-Providers

**Q: When to use InjectionToken and multi providers?**

```typescript
import { InjectionToken, inject } from '@angular/core';

// Typed injection token (replaces OpaqueToken)
export const APP_CONFIG = new InjectionToken<AppConfig>('APP_CONFIG');
export const VALIDATORS = new InjectionToken<ValidatorFn[]>('VALIDATORS');

// Provide in module or bootstrap
providers: [
  {
    provide: APP_CONFIG,
    useValue: { apiUrl: 'https://api.myapp.com', timeout: 5000 }
  },

  // Multi-provider — collects all values into an array
  { provide: VALIDATORS, useValue: noWhitespaceValidator, multi: true },
  { provide: VALIDATORS, useValue: profanityValidator, multi: true },
  { provide: VALIDATORS, useValue: lengthValidator, multi: true },
]

// Inject in service
@Injectable({ providedIn: 'root' })
export class ApiService {
  private config = inject(APP_CONFIG);     // modern inject() function
  private validators = inject(VALIDATORS); // receives array of all validators

  getUsers() {
    return this.http.get(`${this.config.apiUrl}/users`);
  }
}
```

> **Interview point:** `HTTP_INTERCEPTORS` itself uses `multi: true` — that's why you always provide interceptors with `multi: true`. Each interceptor is an item in the interceptor array.

