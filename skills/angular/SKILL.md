---
name: angular
description: Angular 17+ coding patterns. Use when building or editing Angular components, services, or templates. Covers signals, standalone components, services, HTTP, RBAC guards, and PrimeNG usage.
---

# Angular 17+ Patterns

Read `CLAUDE.md` in the project root for project-specific file locations, feature module names, and canonical service examples before writing code.

---

## State management — signals

```typescript
// Service: private signal + readonly accessor
private readonly _items = signal<Item[]>([]);
readonly items = this._items.asReadonly();

// Derived state
readonly count = computed(() => this._items().length);

// Component input/output (Angular 17+)
readonly person = input<Person | null>(null);
readonly close = output<void>();
```

## Dependency injection

```typescript
// Always use inject() — not constructor injection
private readonly peopleSvc = inject(PeopleService);
private readonly http = inject(HttpClient);
```

## Services

```typescript
@Injectable({ providedIn: 'root' })
export class MyService {
  private readonly _data = signal<MyModel[]>([]);
  readonly data = this._data.asReadonly();
  readonly loading = signal(false);

  load(): void {
    this.loading.set(true);
    this.http.get<MyModel[]>('/api/my').subscribe({
      next: (items) => { this._data.set(items); this.loading.set(false); },
      error: () => { this.loading.set(false); },
    });
  }

  // Optimistic update pattern
  update(id: string, patch: Partial<MyModel>): void {
    const original = this._data().find(x => x.id === id);
    this._data.update(list => list.map(x => x.id === id ? { ...x, ...patch } : x));
    this.http.patch<MyModel>(`/api/my/${id}`, patch).subscribe({
      next: (updated) => this._data.update(list => list.map(x => x.id === id ? updated : x)),
      error: () => this._data.update(list => list.map(x => x.id === id ? original! : x)),
    });
  }
}
```

## Components — standalone

```typescript
@Component({
  selector: 'app-my-component',
  imports: [FormsModule, TooltipModule],   // no NgModules
  templateUrl: './my-component.html',
  styleUrl: './my-component.scss',
})
export class MyComponent {
  private readonly mySvc = inject(MyService);
  readonly items = this.mySvc.data;
}
```

## Templates — control flow (Angular 17+)

```html
@if (loading()) {
  <span>Loading...</span>
} @else {
  @for (item of items(); track item.id) {
    <div>{{ item.name }}</div>
  }
}
```

## RBAC guards

```typescript
// On the parent page component, not in the editor
protected readonly canManage = computed(() =>
  this.currentUserSvc.hasAnyRole('MANAGER', 'SENIOR_MANAGER', 'SYNERGHUB_ADMIN')
);
```

Pass down as input:
```html
<app-my-editor [canEdit]="canManage()" />
```

In the editor — disable fields, hide save button:
```html
<input [ngModel]="value()" [disabled]="!canEdit()" />
@if (canEdit()) {
  <button (click)="save()">Save</button>
}
```

## PrimeNG

```typescript
imports: [TooltipModule]
```
```html
<button pTooltip="Delete" tooltipPosition="bottom">...</button>
```

## File layout

```
src/app/features/<feature>/
  components/<name>/
    <name>.ts
    <name>.html
    <name>.scss
  services/
    <name>.service.ts
  models/
    <name>.ts
```
