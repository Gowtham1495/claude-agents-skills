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

## TypeScript type inference — common pitfalls

### 1. Heterogeneous object-literal arrays → strict union type

When you build an array from object literals with different optional properties, TypeScript infers a union type from the first element. Adding a property later that isn't on every union member causes an error.

```typescript
// ✗ Fails — TypeScript infers options type from the first .map(), then rejects
//   the `italic: true` in the fallback push() call
const rows = items.map((x) => [
  { text: x.name, options: { bold: true, fontSize: 9 } },
]);
rows.push([{ text: 'none', options: { fontSize: 9, italic: true } }]); // TS error

// ✓ Declare the variable as any[][] upfront — one annotation, no casts needed
const rows: any[][] = items.map((x) => [
  { text: x.name, options: { bold: true, fontSize: 9 } },
]);
rows.push([{ text: 'none', options: { fontSize: 9, italic: true } }]); // OK
```

Similarly, when passing a mixed-type array to an external library call (e.g. `addTable`):
```typescript
// ✓ Cast at the call site
slide.addTable([headerRow, ...dataRows] as any[][], { ... });
```

**Rule:** When an array is built from heterogeneous objects or populated after construction, declare it as `any[]` or `any[][]`. Only use `as any[][]` casts at call sites when you can't annotate the variable.

---

### 2. `$any()` in templates is not always enough

Angular's strict template type checker sometimes rejects `$any()` casts for indexed access on typed objects (e.g. `obj[$any(key)]`), even though the equivalent works in `.ts` files.

```html
<!-- ✗ Angular strict mode may still error -->
[ngModel]="getHealth(id)[$any(field)]"

<!-- ✓ Add a typed helper method in the component class -->
[ngModel]="getHealthField(id, $any(field))"
```

```typescript
// In the component .ts — narrow the type so the template call is unambiguous
protected getHealthField(id: string, field: keyof Omit<MyType, 'id'>): ValueType {
  return this.getData(id)[field];
}
```

**Rule:** If a template expression requires an indexed access on a typed object, move the logic into a typed component method. Never rely solely on `$any()` for indexed access.

---

### 3. `effect()` + `untracked()` for reactive signal initialization

When signal A should be reset whenever signal B changes, use `effect` + `untracked` to avoid reactive loops:

```typescript
constructor() {
  // Re-initialise selectedIds whenever the project list changes (e.g. team filter)
  effect(() => {
    const ids = new Set(this.activeProjects().map((p) => p.id));
    untracked(() => this.selectedIds.set(ids)); // write without registering as dependency
  });
}
```

**Rule:** Reads inside `effect()` are reactive dependencies. Writes to signals inside `effect()` must be wrapped in `untracked()` or they trigger infinite loops.

---

### 4. Records cannot support presence-flag PATCH DTOs

Java records generate accessor methods (`.field()`) and are immutable — they cannot have the `@JsonSetter` + boolean flag pattern needed to distinguish `null` (clear the field) from absent (leave unchanged).

If a PATCH field needs to be clearable to `null`, the DTO **must be a class**, not a record:

```java
// ✗ Record — cannot distinguish null-sent from not-sent
public record MyPatchRequest(String name, String ownerId) {}

// ✓ Class with presence flag — null-sent clears the value
public class MyPatchRequest {
    private String ownerId;
    private boolean ownerIdPresent;

    @JsonSetter("ownerId")
    public void setOwnerId(String v) { this.ownerId = v; this.ownerIdPresent = true; }
    public boolean isOwnerIdPresent() { return ownerIdPresent; }
    public String getOwnerId() { return ownerId; }
}
```

When converting an existing record to a class, also update all call sites that used record-style accessors (`.field()`) to getter-style (`.getField()`).

---

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

---

## Dark mode in component SCSS — critical rule

### Always use `:host-context(.app-dark)`, never `:root.app-dark`

Angular's view encapsulation adds `[_ngcontent-xxx]` attribute selectors to every rule
in a component's `.scss` file. `:root.app-dark .my-class` becomes
`:root.app-dark .my-class[_ngcontent-xxx]`, which silently fails to match.
`:host-context(.app-dark)` is the only form that survives encapsulation correctly.

```scss
/* ✗ WRONG — dark override silently ignored in component styles */
:root.app-dark {
  .notif-item--pending { background: #3f1f1f; }
}

/* ✓ CORRECT */
:host-context(.app-dark) {
  .notif-item--pending { background: #3f1f1f; }
}
```

### Prefer CSS custom properties over hardcoded hex for semantic colours

When a colour carries semantic meaning (error, warning, hover feedback), use a custom
property so both light and dark modes are handled by the global theme, not a per-component
override block.

```scss
/* ✗ Requires a manual dark override for every component that uses it */
.notif-item { background: #fef2f2; }

/* ✓ Single definition in styles.scss covers all components in all modes */
.notif-item { background: var(--app-error-soft); }
```

If the required token doesn't exist yet, add it to `styles.scss` with light and dark
values rather than hardcoding hex in the component.

### Always define `:hover` for interactive elements

Any element with `cursor: pointer` or that is clickable must have a `:hover` style.
Use `var(--app-hover)` (already defined for both modes) as the default hover background.

```scss
/* ✗ No feedback — user can't tell the item is clickable */
.notif-item { background: var(--app-bg); cursor: pointer; }

/* ✓ */
.notif-item {
  background: var(--app-bg);
  cursor: pointer;
  &:hover { background: var(--app-hover); }
}
```

### Dark mode checklist before committing any new component

- [ ] Every background/text colour uses a CSS variable OR has a `:host-context(.app-dark)` override
- [ ] No `:root.app-dark` in any component `.scss` file
- [ ] Every `cursor: pointer` element has a `:hover` state
- [ ] Switched to dark mode in browser and visually confirmed all states look correct
