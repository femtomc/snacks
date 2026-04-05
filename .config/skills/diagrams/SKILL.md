---
description: "Generating diagrams or thinking about visual communication"
---

# Diagrams

A diagram works when its spatial layout encodes the logical structure of the
domain. Proximity in the diagram means relatedness in the domain. Containment
means membership. Direction means flow or dependency. When these correspondences
hold, the viewer gets inferences for free — they perceive conclusions that prose
would force them to derive step by step (Larkin & Simon 1987). When the
correspondences do not hold — when proximity is arbitrary, containment is
decorative, direction is aesthetic — the diagram is illustrated text. The viewer
reads labels sequentially, gaining nothing from the spatial medium.

The test: does the layout do inferential work, or does the text carry all the
meaning while the layout watches?

## Recognition

The decision to diagram is not "would a picture be nice here?" It is noticing,
mid-explanation, that you are fighting the medium — that prose is forcing the
reader to reconstruct spatial structure from linear description. These are the
signals.

**You are describing a topology.** Three or more entities with relationships
between them. "A asserts X to B, which observes X and asserts Y to C, which in
turn..." — by the third entity the reader is holding a graph in working memory
from sequential input. Draw the graph. The reader perceives the whole topology
at once; text gives it one edge at a time.

**Your prose is dominated by spatial prepositions.** "Inside the facet,"
"between the relay and the dataspace," "flows from the bridge to the daemon."
When containment, adjacency, and direction words dominate a paragraph about
non-physical things, the thing you are describing has spatial structure that
prose is encoding inefficiently. Show it spatially.

**You have written a paragraph and it still feels unclear.** Re-read your own
explanation. If you cannot immediately reconstruct the structure, neither can
the reader. The difficulty is evidence that prose is the wrong medium for this
particular content.

**You are describing a transformation.** Before and after. Old protocol and new
protocol. Source language and target language. Two states with a named operation
between them. Side-by-side diagrams let the reader's eye do the differencing
that prose forces them to simulate mentally.

**You are enumerating states and transitions.** "In state A, if event E occurs,
move to state B" — any enumeration of this form is a graph. State machines
described in prose require the reader to simulate the machine to understand it.
A state diagram lets them trace paths by following arrows.

**The user asked "how does X work?" and X has interacting parts.** The answer
for a system with moving parts is almost always a labeled picture.

### Choosing the diagram type

The structure of the problem selects the diagram, not your preference:

| You are showing...                        | Use                    |
| ----------------------------------------- | ---------------------- |
| What components exist and who uses them   | System context diagram |
| Steps and decisions in a process          | Flowchart              |
| Messages between actors in one scenario   | Sequence diagram       |
| Modes of a single entity and its triggers | State diagram          |
| Nested scopes or containment              | Box-in-box diagram     |
| Change over time or ordering              | Timeline               |
| Quantities and comparisons                | Chart or table         |

A flowchart models a procedure — it advances on completion. A state machine
models reactive behavior — it transitions only when triggered. A sequence
diagram models collaboration between multiple actors in one scenario. Using the
wrong type for a structure produces a confusing diagram even when the content is
correct.

### When not to diagram

Do not diagram when the relationship fits in one sentence. "A calls B" does not
need a picture.

Do not diagram for an expert audience that already holds the structure as a
mental schema. A diagram that scaffolds a novice is redundant to an expert — the
expert must actively ignore it, which costs attention rather than saving it
(Mayer's expertise reversal effect).

Do not add a decorative illustration because a page "needs a visual." Visuals
that are interesting but irrelevant to the explanation measurably reduce
comprehension by consuming working memory on material that cannot be integrated
into the reader's mental model (Mayer's seductive details effect).

Do not diagram when the information is comparative rather than topological. Use
a table.

Do not diagram a system you cannot keep current. A stale diagram is worse than
no diagram — new readers cannot distinguish stale from current and build
incorrect mental models. Only diagram if the output can be regenerated,
co-located with its source, or describes a stable structure.

## Drafting

A diagram is drafted iteratively. Expect two to three passes.

### 1. Write the caption first

Before generating anything, write one sentence stating what the diagram
communicates — not what it contains. "This diagram shows that retraction
propagates inward through three levels of facet nesting" is a communication
goal. "This diagram shows facets and actors" is an inventory.

The caption disciplines the prompt. Every element in the diagram must serve the
caption's claim. Elements that do not participate in the communication goal do
not belong.

### 2. Prompt with structure, not aesthetics

The prompt describes spatial arrangement and relationships. Structure first,
style second.

**Components and arrangement.** Name every element and its position relative to
the others. "Three boxes left to right, connected by arrows" — not "a system
with three components." "Dataspace node at center, four actor nodes surrounding
it" — not "actors connected to a dataspace." State containment explicitly:
"actor B is inside dataspace D, shown as a nested box."

**Relationships and direction.** Name connections and how they flow. "Arrow from
each actor to the dataspace, labeled 'assert'" — not "actors communicate with
the dataspace." State direction: "left to right," "top-down," "bidirectional."

**Exclusions.** Generative models default toward visual richness — gradients,
shadows, ambient color, decorative elements. Technical diagrams need restraint.
State what you do not want: "no decorative elements, no gradients, no background
texture, white background, flat colors." This layer is the most frequently
omitted and produces the largest improvement when added.

**Abstraction level.** AI generates at the abstraction level implied by its
training distribution — usually one level more detailed than you want. Specify
explicitly: "show only top-level subsystems, not individual services" or "show
individual service endpoints, not subsystem groups."

Use `diagram generate` for technical diagrams. The tool auto-detects diagram
type from the prompt and appends appropriate style tokens (layout conventions,
exclusions, flat color). Use `--raw` to skip expansion, or `--llm` for
LLM-powered prompt rewriting via OpenRouter.

For DSL-first workflows where you need precise layout control, write the
structure in Mermaid or D2, then use `diagram from-dsl` to re-render through
FLUX with visual polish.

### 3. Evaluate against the caption

After generation, read the image. Compare against the caption from step 1 line
by line, not by general impression:

- Does the diagram communicate the caption's claim?
- Can the reader identify every component named in the prompt?
- Is the visual hierarchy correct — does the most important element draw the eye
  first?
- Are labels legible?
- Is anything present that does not serve the caption?

### 4. Refine

For targeted corrections, use `diagram edit` with one specific change per call:

```bash
diagram edit diagram.png "make the center node larger"
diagram edit diagram.png "add label 'retract' to the downward arrow"
diagram edit diagram.png "remove the background gradient"
```

Precise spatial language produces better edits than broad instructions like
"make it cleaner." Use `--lock` to protect elements that should not change:

```bash
diagram edit diagram.png "restyle the arrows" --lock "node positions and labels"
```

For region-specific changes, use `diagram fill` with a mask:

```bash
diagram fill diagram.png --rect 200,300,400,200 -p "Redis cache cluster"
diagram fill diagram.png --select "the center box" -p "replace with cylinder"
```

For structural problems — wrong arrangement, missing relationships, incorrect
topology — re-generate from scratch with the corrections folded into a new
prompt. Do not iteratively correct a structurally wrong diagram. Use
`diagram branch` to fork from an earlier step without losing the history chain:

```bash
diagram history          # find the step to fork from
diagram branch 0 "same layout but add a cache layer between app and DB"
```

Iteration fixes structural errors (wrong connections, missing elements) better
than aesthetic errors (poor spacing, cluttered layout). Use iteration for
structure. Re-generate for aesthetics.

## Visual coherence

Visual properties are semantic, not decorative. Position, proximity, size,
color, containment, and direction all carry meaning whether or not you intend
them to. The difference between a diagram that communicates and one that
confuses is whether these spatial semantics were chosen deliberately.

### The 200-millisecond gist

The viewer forms an impression of the diagram before reading any label. In
roughly 200ms the visual system extracts position, size, color, density, and
enclosure across the entire image — in parallel, preattentively, without
conscious effort (Ware 2004). This gist determines what the viewer expects the
diagram to be about.

If the gist contradicts the intended message — if the largest element is not the
most important, if the color clustering implies groupings that do not exist —
the viewer resists the diagram even after reading the labels. Design the gist
first: ask what the viewer perceives in the first glance, then fix the layout
before fixing the labels.

### Hierarchy

Establish one dominant focal point — the element the reader should see first.
Give it dominant visual weight through at least two of: size, contrast,
isolation (surrounding whitespace), color saturation. Assign every other element
to one of two subordinate levels: supporting structure and context.

Three levels of visual hierarchy is the practical limit. Attempting four or five
produces diminishing contrast between adjacent levels, making the reading order
ambiguous. Everything in the diagram should be assigned to a level before layout
begins.

### Grouping

Proximity, similarity, enclosure, and alignment trigger mandatory perceptual
grouping (Gestalt principles). The viewer groups elements before interpreting
them. This process is automatic — the viewer cannot choose not to see nearby
elements as related, cannot choose not to read similarly-colored nodes as the
same category.

Accidental grouping is as real as intentional grouping. Two unrelated nodes
positioned close together will be perceived as related. Three elements sharing a
fill color will look like the same category regardless of labels.

Audit every diagram for unintended groupings. Use whitespace and explicit
bounding regions to prevent the perceptual system from merging distinct
structures.

### Color

Build color scales in a perceptually uniform color space — HCL, OKLCH, or CIELAB
— not HSL or RGB. In HSL, equal numeric steps produce unequal perceived steps:
yellows at a given "lightness" appear much lighter than blues at the same value.
This creates false visual discontinuities that readers misread as data features.

For sequential scales (light to dark), vary luminance only while holding hue and
chroma constant. For categorical distinctions, use ColorBrewer qualitative
palettes. Never use rainbow colormaps for ordered data — they produce perceptual
artifacts near yellow-green that readers mistake for meaningful transitions.

Test every palette with a color-blindness simulator. Deuteranopia (red-green
color blindness) affects approximately 8% of men.

For this pipeline: specify the accent color directly in the prompt ("accent
color: blue") for consistency across a project. For project-wide style
consistency, create a `.diagram-style.json` with a `style_ref` pointing to a
reference image — all `generate` and `edit` calls will match its visual style
automatically. Use categorical color only when it encodes semantically distinct
categories.

### Typography

Choose one sans-serif family for the entire diagram set. Regular weight (400)
for labels, semibold (600) for component names. Never light weights at small
sizes — they lose contrast against backgrounds.

Three type sizes: title, labels, annotations. No more than three. Horizontal
labels only — rotated text adds processing time per label and signals
insufficient layout planning. Shorten label text rather than rotating it.

Use tabular (monospaced-width) figures wherever numbers appear, so columns and
callouts align.

### Layout

For node-link diagrams, minimize edge crossings above all other aesthetic
considerations. Edge crossing reduction is the single strongest measured
predictor of comprehension speed and accuracy in graph-reading tasks. Even a few
unnecessary crossings significantly degrade understanding.

Align nodes to an implicit grid. Even a coarse grid produces the symmetry signal
that viewers parse as organized. Maintain at least 1.5x the node size as minimum
spacing between adjacent nodes — elements touching or nearly touching read as
accidentally placed.

Match layout direction to the structure's natural reading order: `horizontal`
for pipelines and timelines, `vertical` for call stacks and layered
architectures, `hierarchical` for trees, `circular` for cycles.

### Style tokens

For a set of diagrams in the same project, define a style vocabulary before
drawing:

- Fixed shape for each semantic role (databases are cylinders, external services
  are hexagons — always).
- Fixed color for each semantic role (primary components: accent color;
  secondary: gray; error paths: red — always).
- Fixed edge types: solid for synchronous/primary, dashed for async/optional. No
  more than three edge types.
- Consistent size hierarchy: system > subsystem > component.

Apply these without deviation. A reader who has seen one diagram in the set
should orient immediately in the next. Consistency across diagrams signals
disciplined thinking and increases credibility independently of content quality.

## SVG round-trip

The diagram tool supports a full raster-to-vector-to-raster workflow for precise
post-generation edits.

### Vectorize

```bash
diagram vectorize diagram.png                    # defaults tuned for technical diagrams
diagram vectorize diagram.png --hierarchical cutout  # cleaner layers for manual editing
```

Use losslessly compressed PNG as input. JPEG compression artifacts are traced as
real edges. Generate rasters at high resolution — use `-W 1200` or larger.

Tune vectorization by content type:

| Content                      | -f (speckle) | -p (color) | -c (corner) |
| ---------------------------- | ------------ | ---------- | ----------- |
| Flat-color technical diagram | 6-8          | 3-4        | 70-90       |
| Logo or illustration         | 4            | 5-6        | 60          |
| Gradient-rich image          | 2-3          | 7-8        | 45-55       |

### Edit SVG, then rasterize back

Labels, colors, and stroke widths are plain XML attributes in the SVG —
search-and-replace works. The SVG preserves spatial layout from the raster, so
repositioning is not needed for label or color fixes.

```bash
# Edit the SVG in a text editor, then rasterize back to PNG
diagram rasterize diagram.svg -W 1024

# Feed the corrected PNG back through edit or fill
diagram edit diagram.png "add a cache layer between app and database"
```

### Post-vectorization inspection

Check for three common artifacts:

**Merged thin lines.** Lower `-f` (filter_speckle) if thin lines are
disappearing.

**Text degradation.** Rasterized text becomes curves — not selectable or
searchable. Replace traced glyph shapes with SVG `<text>` elements after
conversion for label-critical diagrams.

**Color banding.** Increase `-p` (color_precision) if gradient regions show
discrete steps.

## diagram vs. TikZ

| Need                                         | Use       |
| -------------------------------------------- | --------- |
| Pixel-precise layout, mathematical labels    | TikZ      |
| Reproducible from source, version-controlled | TikZ      |
| LaTeX integration                            | TikZ      |
| Parameterized diagram families               | TikZ      |
| Rapid iteration on a visual concept          | `diagram` |
| Organic or illustrative visuals              | `diagram` |
| Diagrams for web, markdown, non-LaTeX output | `diagram` |
| One-off explanatory diagram in conversation  | `diagram` |

TikZ gives exact control and reproducibility. `diagram` gives speed and visual
range. Use whichever makes the diagram exist.

## References

### Cognitive foundations

- Larkin & Simon, "Why a Diagram is (Sometimes) Worth Ten Thousand Words"
  (_Cognitive Science_ 11, 1987) — the three computational mechanisms by which
  diagrams reduce cognitive work: locality, search reduction, perceptual
  inference. A diagram helps only when spatial layout is isomorphic to logical
  structure.
- Shimojima, "Semantic Properties of Diagrams and Their Cognitive Potentials"
  (_Cognitive Science_, 2013) — free rides: inferences the viewer gets from
  spatial constraints without explicit reasoning. Eye-tracking confirmation that
  reasoners exploit spatial constraints in real time.
- Tversky, "Visualizing Thought" (_Topics in Cognitive Science_, 2011) —
  Congruence Principle (visual structure must match conceptual structure) and
  Apprehension Principle (the match must be readily perceived). Diagrams as
  externalized working memory.
- Tversky, Morrison & Betrancourt, "Animation: Can It Facilitate?"
  (_IJHCS_, 2002) — animation consistently fails to improve comprehension over
  static diagrams because it is transient and viewer-paced.
- Mayer, _Cambridge Handbook of Multimedia Learning_ — capacity model of
  multimedia learning. Key results: multimedia principle (words + pictures >
  words alone), coherence (irrelevant elements hurt), contiguity (spatial
  separation hurts), expertise reversal (novice scaffolding is expert noise),
  seductive details (interesting irrelevancies reduce learning).

### Perception and design

- Ware, _Information Visualization: Perception for Design_ (2004) — preattentive
  processing (gist in 200ms), channel accuracy ranking (position > length >
  angle > area > color saturation > hue), visual queries.
- Bertin, _Semiology of Graphics_ (1967) — the visual variables (position, size,
  shape, value, color, orientation, texture) and their retinal properties
  (selective, associative, quantitative, ordered).
- Tufte, _The Visual Display of Quantitative Information_ (1983) — data-ink
  ratio, chartjunk, small multiples.
- Tufte, _Envisioning Information_ (1990) — layering and separation, micro/macro
  readings.
- Bateman et al., "Useful Junk?" (_CHI_, 2010) — embellishment that is
  conceptually related to content improves long-term memorability without
  degrading comprehension. Pure decoration does not help.
- Brewer, ColorBrewer (colorbrewer2.org) — perceptually discriminable palettes
  for categorical, sequential, and diverging data. Colorblind-safe filtering.

### Diagram practice

- Brown, _The C4 Model for Visualising Software Architecture_ — four zoom levels
  (context, container, component, code) matched to audience. Level 4 should be
  generated, not hand-drawn.
- Roam, _The Back of the Napkin_ (2008) — six problem types (who/what, how much,
  where, when, how, why) and their canonical visual forms.
