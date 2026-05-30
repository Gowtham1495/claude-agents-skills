---
name: pptx
description: PowerPoint generation using PptxGenJS in an Angular app. Use when building a client-side slide deck export feature. Covers slide layout, text blocks, colors, pagination, and file download. Based on the QBR Report feature in Synerghub.
---

# PptxGenJS — Client-Side PowerPoint Generation

All PPT generation happens in the Angular frontend — no backend file generation required. The backend only provides data via REST API.

Read `CLAUDE.md` for the project's feature module locations and service patterns.

---

## REQUIRED: Get a reference screenshot before writing any slide code

If the user has provided a reference PPT file or wants to match an existing layout:

**Always ask for a screenshot first. Never infer layout from anything else.**

```
"Before I write coordinates, I need to see the reference visually.
Can you share a screenshot of the slide(s) you want to match?"
```

Then use the `Read` tool on the image file to view it directly:
```typescript
// Read tool accepts image paths (PNG, JPG, etc.)
// View the screenshot to confirm every layout detail visually
```

### Why XML/text extraction is not enough — lesson learned

Extracting text from a PPTX file (unzipping and reading slide XML) gives you text content and rough coordinates, but it **cannot reliably tell you**:
- Whether labels are row headers or column headers in a table
- Which sections overlay or layer on top of each other
- Visual grouping and alignment that exists only in the rendered slide
- The actual colour of fills (theme references vs. hex values differ)
- Whether a section is a text box or a table cell

**Concretely:** "Business Leader | Product Owner | Tech Delivery Owner" extracted as a text sequence looks identical whether it is a single-column list (one label per row) or a five-column table header (all labels in one row). Only the rendered screenshot makes this unambiguous.

### Before writing any `renderSlide()` code, confirm all of these visually:

| Question | Why it can't be inferred from XML |
|---|---|
| Are role labels columns or rows? | Text order in XML follows DOM, not visual direction |
| Are Overall/Scope/Schedule table columns or row labels? | Same reason |
| Which sections are side-by-side vs. stacked? | Overlapping shapes have unordered XML positions |
| What are the exact background colours? | Theme refs like `dk1`, `lt1` don't map to hex without theme file |
| Is the footer above or below a table? | Z-order and y-position both matter; text extraction only gives y |

### Workflow for pixel-to-pixel matching

1. User shares reference `.pptx` file
2. **Ask for a screenshot** — do not skip this step
3. Use `Read` tool to view the screenshot image
4. Confirm with the user: describe what you see section by section and ask them to verify
5. Only after visual confirmation: extract exact coordinates from PPTX XML as a cross-check
6. Write coordinates; show the user an ASCII layout diagram and ask for confirmation before coding
7. After generating the PPT, ask the user to compare visually and report any differences

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

## Tables

Use `addTable` for any grid with headers, coloured cells, or multi-column data.
Cell options allow per-cell fill, colour, font, alignment:

```typescript
const rows = [
  // Header row
  [
    { text: 'Col A', options: { bold: true, color: 'FFFFFF', fill: { color: '07316D' }, fontSize: 9 } },
    { text: 'Col B', options: { bold: true, color: 'FFFFFF', fill: { color: '07316D' }, fontSize: 9 } },
  ],
  // Data row
  [
    { text: 'value 1', options: { fontSize: 9, color: '1F1F1F' } },
    { text: 'G', options: { bold: true, fontSize: 10, color: 'FFFFFF', fill: { color: '00B050' } } },
  ],
];

slide.addTable(rows as any[][], {   // cast to any[][] to avoid TS union type errors
  x: 0, y: 1.5, w: 13.26, h: 1.4,
  border: { type: 'solid', pt: 0.5, color: 'AAAAAA' },
  colW: [4.0, 2.0],  // must sum to w
});
```

**Important:** TypeScript will infer a strict union type from mixed cell option shapes. Always declare data row arrays as `any[][]` or cast the full argument with `as any[][]`.

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
- `src/app/features/projects/components/qbr-report/qbr-report.ts` — full generation logic
- `src/app/features/projects/components/weekly-report/weekly-report.ts` — pixel-matched layout with `addTable` for headers, health grid, issues, risks, and deliverables

Read these before building a new report feature to reuse patterns.
