---
description: "Generating diagrams or thinking about visual communication"
---

# Diagrams

A diagram works when its spatial layout encodes the logical structure of the
domain — proximity means relatedness, containment means membership, direction
means flow or dependency. When the correspondence holds, the viewer gets
inferences for free (Larkin & Simon 1987). When it does not, the diagram is
illustrated text and the spatial medium does no work.

The test: does the layout do inferential work, or does the text carry all the
meaning while the layout watches?

## Recognition

Signals that prose is the wrong medium:

**You are describing a topology** — three or more entities with relationships.
"A asserts X to B, which observes X and asserts Y to C..." By the third entity
the reader is reconstructing a graph from sequential input.

**Your prose is dominated by spatial prepositions** — "inside the facet,"
"between the relay and the dataspace," "flows from the bridge to the daemon."
Containment, adjacency, and direction words mean the content has spatial
structure that prose is encoding inefficiently.

**A paragraph still feels unclear.** If you cannot reconstruct the structure
from your own explanation, neither can the reader.

**You are describing a transformation.** Before/after, source/target. Side-by-side
diagrams let the eye do the differencing prose forces the reader to simulate.

**You are enumerating states and transitions.** Any "in state A, if event E,
move to state B" enumeration is a graph.

**The user asked "how does X work?" and X has interacting parts.**

### Choosing the diagram type

| You are showing...                        | Use                    |
| ----------------------------------------- | ---------------------- |
| What components exist and who uses them   | System context diagram |
| Steps and decisions in a process          | Flowchart              |
| Messages between actors in one scenario   | Sequence diagram       |
| Modes of a single entity and its triggers | State diagram          |
| Nested scopes or containment              | Box-in-box             |
| Change over time or ordering              | Timeline               |
| Quantities and comparisons                | Chart or table         |

A flowchart advances on completion; a state machine transitions only when
triggered; a sequence diagram models multi-actor collaboration in one scenario.

### When not to diagram

- One-sentence relationships ("A calls B").
- Expert audiences who already hold the structure as a schema (expertise
  reversal effect).
- Decoration. Visuals irrelevant to the explanation reduce comprehension by
  consuming working memory (Mayer's seductive details effect).
- Comparative information. Use a table.
- Anything you cannot keep current. A stale diagram is worse than no diagram.

## Drafting

Two to three passes.

### 1. Write the caption first

State what the diagram *communicates*, not what it contains. "Retraction
propagates inward through three levels of facet nesting" is a goal. "Facets and
actors" is an inventory. The caption disciplines the prompt — every element
must serve the claim.

### 2. Prompt with structure, not aesthetics

- **Components and arrangement.** Name every element and its position. "Three
  boxes left to right, connected by arrows" — not "a system with three
  components." State containment: "actor B inside dataspace D, shown as a
  nested box."
- **Relationships and direction.** "Arrow from each actor to the dataspace,
  labeled 'assert'" — not "actors communicate with the dataspace." State
  direction: "left to right," "top-down," "bidirectional."
- **Exclusions.** Generative models default to gradients, shadows, decoration.
  Say what you do not want: "no decorative elements, no gradients, white
  background, flat colors." This single layer produces the largest improvement.
- **Abstraction level.** AI generates one level more detailed than you want.
  Specify: "show only top-level subsystems" or "show individual endpoints."

Use `diagram generate` for technical diagrams (auto-detects type, appends
style tokens). `--raw` skips expansion; `--llm` uses OpenRouter rewriting.

For DSL-first workflows, write structure in Mermaid or D2, then
`diagram from-dsl` to re-render through FLUX.

### 3. Evaluate against the caption

Read the image. Compare to the caption line by line, not by impression:

- Does it communicate the caption's claim?
- Can the reader identify every named component?
- Is the visual hierarchy correct — does the most important element draw the
  eye first?
- Are labels legible?
- Anything present that does not serve the caption?

### 4. Refine

```bash
diagram edit diagram.png "make the center node larger"
diagram edit diagram.png "add label 'retract' to the downward arrow"
diagram edit diagram.png "remove the background gradient"

diagram edit diagram.png "restyle the arrows" --lock "node positions and labels"

diagram fill diagram.png --rect 200,300,400,200 -p "Redis cache cluster"
diagram fill diagram.png --select "the center box" -p "replace with cylinder"
```

For structural problems — wrong arrangement, missing topology — re-generate
from scratch. Do not iteratively patch a structurally wrong diagram. Use
`diagram branch` to fork from an earlier step:

```bash
diagram history          # find a step to fork from
diagram branch 0 "same layout but add a cache layer between app and DB"
```

Iterate for structure, regenerate for aesthetics.

## Visual coherence

Position, proximity, size, color, containment, and direction all carry meaning
whether you intend them to.

### The 200ms gist

The viewer extracts position, size, color, density, enclosure across the entire
image in roughly 200ms — preattentively, before reading any label (Ware 2004).
This gist determines what the viewer expects the diagram to be about. If the
gist contradicts the message — if the largest element is not the most
important, if color clustering implies non-existent groupings — the viewer
resists even after reading labels.

### Hierarchy

Establish one dominant focal point. Give it weight via at least two of: size,
contrast, isolation, color saturation. Three levels of visual hierarchy is the
practical limit — more produces ambiguous reading order.

### Grouping

Proximity, similarity, enclosure, and alignment trigger mandatory perceptual
grouping (Gestalt). The viewer cannot choose not to see nearby elements as
related. Audit every diagram for *unintended* groupings — two unrelated nodes
positioned close will be perceived as related; three elements sharing a fill
color will look like one category.

### Color

Build scales in a perceptually uniform color space — HCL, OKLCH, CIELAB — not
HSL or RGB. In HSL, equal numeric steps produce unequal perceived steps.

For sequential scales, vary luminance only, hold hue and chroma. For categorical
distinctions, use ColorBrewer qualitative palettes. Never use rainbow colormaps
for ordered data — the yellow-green region produces perceptual artifacts. Test
with a color-blindness simulator (deuteranopia affects ~8% of men).

For project-wide consistency, create `.diagram-style.json` with a `style_ref`
pointing to a reference image — all `generate` and `edit` calls match its
style.

### Typography

One sans-serif family for the whole set. Regular (400) for labels, semibold
(600) for component names. Never light weights at small sizes. Three sizes
maximum: title, labels, annotations. Horizontal labels only — rotation signals
insufficient layout planning. Use tabular figures for aligned numbers.

### Layout

For node-link diagrams, minimize edge crossings above all other aesthetic
considerations — this is the strongest measured predictor of comprehension
speed. Align nodes to an implicit grid. Maintain at least 1.5x node size as
minimum spacing.

Match direction to natural reading order: `horizontal` for pipelines and
timelines, `vertical` for call stacks, `hierarchical` for trees, `circular` for
cycles.

### Style tokens

For a diagram set, fix a vocabulary before drawing:

- One shape per semantic role (databases are cylinders, external services are
  hexagons — always).
- One color per semantic role (primary: accent; secondary: gray; error: red).
- ≤3 edge types: solid for synchronous/primary, dashed for async/optional.
- Consistent size hierarchy: system > subsystem > component.

Apply without deviation. A reader who has seen one diagram in the set should
orient immediately in the next.

## SVG round-trip

```bash
diagram vectorize diagram.png                       # defaults for tech diagrams
diagram vectorize diagram.png --hierarchical cutout # cleaner layers
```

Use lossless PNG. JPEG artifacts get traced as edges. Generate at high
resolution: `-W 1200` or larger.

| Content                      | -f (speckle) | -p (color) | -c (corner) |
| ---------------------------- | ------------ | ---------- | ----------- |
| Flat-color technical diagram | 6-8          | 3-4        | 70-90       |
| Logo or illustration         | 4            | 5-6        | 60          |
| Gradient-rich image          | 2-3          | 7-8        | 45-55       |

Edit SVG (labels, colors, strokes are plain XML), then rasterize back:

```bash
diagram rasterize diagram.svg -W 1024
diagram edit diagram.png "add a cache layer between app and database"
```

Common artifacts: merged thin lines (lower `-f`), text degradation (rasterized
glyphs are not searchable — replace with `<text>` for label-critical diagrams),
color banding (raise `-p`).

## diagram vs. TikZ

| Need                                         | Use       |
| -------------------------------------------- | --------- |
| Pixel-precise layout, mathematical labels    | TikZ      |
| Reproducible from source, version-controlled | TikZ      |
| LaTeX integration                            | TikZ      |
| Parameterized diagram families               | TikZ      |
| Rapid iteration on a visual concept          | `diagram` |
| Organic or illustrative visuals              | `diagram` |
| Web/markdown/non-LaTeX output                | `diagram` |
| One-off explanatory diagram in conversation  | `diagram` |

## References

### Cognitive foundations

- Larkin & Simon, "Why a Diagram is (Sometimes) Worth Ten Thousand Words"
  (_Cognitive Science_ 11, 1987) — locality, search reduction, perceptual
  inference. Diagrams help when spatial layout is isomorphic to logical
  structure.
- Shimojima, "Semantic Properties of Diagrams" (_Cognitive Science_, 2013) —
  free rides: inferences from spatial constraints.
- Tversky, "Visualizing Thought" (_Topics in Cognitive Science_, 2011) —
  Congruence and Apprehension Principles.
- Tversky, Morrison & Betrancourt, "Animation: Can It Facilitate?" (_IJHCS_,
  2002) — animation consistently fails to improve comprehension over static
  diagrams.
- Mayer, _Cambridge Handbook of Multimedia Learning_ — multimedia, coherence,
  contiguity, expertise reversal, seductive details.

### Perception and design

- Ware, _Information Visualization: Perception for Design_ (2004) —
  preattentive processing, channel accuracy ranking.
- Bertin, _Semiology of Graphics_ (1967) — visual variables and retinal
  properties.
- Tufte, _The Visual Display of Quantitative Information_ (1983) — data-ink
  ratio, chartjunk.
- Tufte, _Envisioning Information_ (1990) — layering, micro/macro readings.
- Bateman et al., "Useful Junk?" (_CHI_ 2010) — embellishment related to content
  improves memorability; pure decoration does not.
- Brewer, ColorBrewer (colorbrewer2.org) — perceptually discriminable palettes.

### Diagram practice

- Brown, _The C4 Model for Visualising Software Architecture_ — four zoom
  levels; level 4 should be generated.
- Roam, _The Back of the Napkin_ (2008) — six problem types and their canonical
  visual forms.
