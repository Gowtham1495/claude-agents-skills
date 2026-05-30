---
name: pptx
description: PowerPoint generation using PptxGenJS in an Angular app. Use when building a client-side slide deck export feature. Covers slide layout, text blocks, colors, pagination, and file download. Based on the QBR Report feature in Synerghub.
---

# PptxGenJS — Client-Side PowerPoint Generation

All PPT generation happens in the Angular frontend — no backend file generation required. The backend only provides data via REST API.

Read `CLAUDE.md` for the project's feature module locations and service patterns.

---

## Library

```json
"pptxgenjs": "^4.0.1"
```

Import dynamically to avoid bloating the initial bundle:

```typescript
const PptxGenJS = (await import('pptxgenjs')).default;
const pptx = new PptxGenJS();
```

---

## Slide setup

```typescript
// Widescreen layout (standard for modern presentations)
pptx.defineLayout({ name: 'WIDE', width: 13.33, height: 7.5 });
pptx.layout = 'WIDE';
```

---

## Adding a slide

```typescript
const slide = pptx.addSlide();
```

---

## Text blocks

```typescript
slide.addText('Header Title', {
  x: 0, y: 0, w: 13.33, h: 0.6,
  fontSize: 21.33,
  bold: true,
  color: 'FFFFFF',
  fill: { color: '07316D' },    // dark blue header bar
  align: 'center',
  valign: 'middle',
  fontFace: 'Aptos',
});
```

**Multi-line text with bullets:**
```typescript
slide.addText(
  lines.map((line, i) => ({
    text: line,
    options: { bullet: i > 0, fontSize: 13.33 },
  })),
  { x: 0.2, y: 1.0, w: 6.0, h: 5.0, fontFace: 'Aptos', valign: 'top' }
);
```

**Mixed styles in one text block (title + body):**
```typescript
slide.addText([
  { text: 'Section Header', options: { bold: true, fontSize: 16, breakLine: true } },
  { text: 'Bullet line 1', options: { bullet: true, fontSize: 13.33, breakLine: true } },
  { text: 'Bullet line 2', options: { bullet: true, fontSize: 13.33 } },
], { x, y, w, h, fontFace: 'Aptos', valign: 'top' });
```

---

## Background fill on a text box

```typescript
slide.addText('Content', {
  x, y, w, h,
  fill: { color: teamColor, transparency: 80 },  // light tint
  line: { color: teamColor, width: 1 },
});
```

---

## Height estimation for pagination

When dynamically placing content across slides, estimate how tall a block will be:

```typescript
function estimateHeight(text: string, fontSize: number, boxWidth: number): number {
  const charsPerLine = Math.floor((boxWidth * 72) / (fontSize * 0.6));
  const lines = text.split('\n').reduce((acc, line) => {
    return acc + Math.max(1, Math.ceil(line.length / charsPerLine));
  }, 0);
  const lineHeightInches = (fontSize / 72) * 1.4;
  return lines * lineHeightInches;
}
```

Use this to decide whether to place content in the current slot or overflow to the next slide.

---

## Typical two-column layout pattern (QBR-style)

```typescript
const SLOT = {
  left:  { x: 0.2,  y: 0.7, w: 6.3, h: 6.2 },
  right: { x: 6.83, y: 0.7, w: 6.3, h: 6.2 },
};

let slide = pptx.addSlide();
addHeader(slide, ...);  // reusable header function
addFooter(slide, ...);  // reusable footer function

let currentSlotIndex = 0;  // 0 = left, 1 = right

for (const team of teams) {
  if (currentSlotIndex >= 2) {
    slide = pptx.addSlide();
    addHeader(slide, ...);
    addFooter(slide, ...);
    currentSlotIndex = 0;
  }
  const slot = currentSlotIndex === 0 ? SLOT.left : SLOT.right;
  renderTeamContent(slide, team, slot);
  currentSlotIndex++;
}
```

---

## File download

```typescript
await pptx.writeFile({
  fileName: `Report-${startDate}-to-${endDate}-${today}.pptx`,
});
// Triggers browser native download dialog
```

---

## Angular integration pattern

```typescript
protected readonly generating = signal(false);
protected readonly exportMessage = signal<{ text: string; type: 'success' | 'error' } | null>(null);

protected async generatePptx(): Promise<void> {
  this.generating.set(true);
  this.exportMessage.set(null);
  try {
    const PptxGenJS = (await import('pptxgenjs')).default;
    const pptx = new PptxGenJS();
    pptx.defineLayout({ name: 'WIDE', width: 13.33, height: 7.5 });
    pptx.layout = 'WIDE';

    // ... build slides ...

    await pptx.writeFile({ fileName: `MyReport-${today}.pptx` });
    this.exportMessage.set({ text: 'Report exported successfully.', type: 'success' });
  } catch (err) {
    this.exportMessage.set({ text: 'Export failed. Please try again.', type: 'error' });
  } finally {
    this.generating.set(false);
  }
}
```

Template button:
```html
<button (click)="generatePptx()" [disabled]="generating() || loading()">
  <i class="pi pi-download"></i>
  {{ generating() ? 'Generating…' : 'Export PPT' }}
</button>
@if (exportMessage()) {
  <span [class]="'msg msg--' + exportMessage()!.type">{{ exportMessage()!.text }}</span>
}
```

---

## Reference implementation

The complete working example is in the Synerghub UI repo:
- `src/app/features/projects/components/qbr-report/qbr-report.ts` — full generation logic (500 lines)
- `src/app/features/projects/components/qbr-report/qbr-report.html` — template with export button and preview cards

Read it before building a new report feature to reuse the header/footer helpers and slot pagination logic.
