---
description: "Writing TikZ diagrams in .tex files"
---

# TikZ

How to write compositional, publication-quality TikZ graphics.

## The mental model

TikZ is a declarative graphics DSL embedded in TeX. Everything composes through
one mechanism: **pgfkeys**, a hierarchical key-value system. A pgfkeys **style**
is a named bundle of options that, when invoked, injects its options into the
current parse. Styles are first-class functions over the option set.

The composition hierarchy, from coarsest to finest:

```
tikzpicture  →  scope  →  path/node/pic  →  style/option  →  pgfkey
```

A **scope** groups options and graphics state inside a TeX group; everything
inside the scope is local. A **style** bundles options for reuse. A **pic** is a
named, parameterized chunk of TikZ code that executes in a fresh scope. A
**node** is both a drawn shape and a named coordinate that persists across
scopes. Draw a node, then wire to it by name from anywhere in the picture.

## Foundational patterns

### 1. Styles compose through application

```latex
% These are equivalent — a style is code that injects more keys:
foo/.style={draw, red}
foo/.code={\pgfkeysalso{draw, red}}
```

Extend a style without replacing it:

```latex
\tikzset{my base/.style={draw, thick}}
\tikzset{my base/.append style={red}}     % adds red, keeps draw+thick
\tikzset{my derived/.style={my base, fill=blue!20}}  % inherits everything
```

`.append style` adds options to an existing style; `.prefix style` prepends
them. Both leave the original intact. The @@-convention (Pattern 2) uses this to
let users extend library styles without overwriting the base definition.

### 2. The "every" pattern

TikZ pre-declares empty styles at every processing stage. Filling one changes
every instance of that category:

```latex
every picture/.style={}    every scope/.style={}
every path/.style={}       every node/.style={}
every edge/.style={draw}   every child/.style={}
```

Libraries add domain-specific hooks: `every state`, `every concept`,
`every entity`. Setting `every state/.style={fill=blue!20}` changes every
automaton state in the picture.

### 3. Nodes are visual elements and named coordinates

A node draws a shape and registers a named coordinate with anchors (attachment
points). Subsequent commands reference the node by name:

```latex
\node[circle, draw] (A) at (0,0) {$\alpha$};
\node[rectangle, draw] (B) at (3,0) {$\beta$};
\draw[->] (A.east) -- (B.west);      % anchor-precise connection
\draw[->] (A.north) to[bend left] (B.north);
```

Anchors: `north`, `south`, `east`, `west`, compass combinations, `base` (text
baseline), `mid` (x-height), angle-based (`A.45`), and shape-specific anchors
for multi-part nodes.

### 4. Pics

A pic executes a named chunk of TikZ code in a fresh scope at a given position.
It exposes named coordinates that the caller references:

```latex
\tikzset{
  my widget/.pic={
    \coordinate (-left)  at (-1, 0);
    \coordinate (-right) at ( 1, 0);
    \draw[pic actions] (-left) -- (0,1) -- (-right);
  }
}
\tikz {
  \pic (W1) at (0,0) {my widget};
  \pic (W2) at (4,0) {my widget};
  \draw[dashed] (W1-right) -- (W2-left);  % cross-pic wiring
}
```

`pic actions` propagates the caller's draw/fill options into the pic body. Three
code slots control layering: `background code`, `code`, `foreground code`.

### 5. Scopes isolate state

A scope creates a TeX group. All `\def` assignments, style overrides, and
clipping paths inside it vanish when it ends:

```latex
\begin{scope}[rotate=30, red, thick]
  \draw (0,0) -- (1,1);   % rotated, red, thick
\end{scope}
\draw (0,0) -- (1,1);     % unrotated, default color, default width
```

The `scopes` library adds brace-based shorthand: `{[red] \draw ...;}`.

### 6. Coordinate arithmetic

The `calc` library enables arithmetic on coordinates:

```latex
($(A)!0.5!(B)$)           % midpoint of A and B
($(A)!1cm!(B)$)           % 1cm from A toward B
($(A) + (1,0.5)$)         % vector addition
($(A)!(P)!(B)$)           % projection of P onto line A--B
(A |- B)                  % x from A, y from B (perpendicular intersection)
```

Named intersections via the `intersections` library:

```latex
\draw[name path=c1] (0,0) circle (1);
\draw[name path=c2] (1,0) circle (1);
\fill[name intersections={of=c1 and c2, by={P,Q}}]
  (P) circle (2pt) (Q) circle (2pt);
```

### 7. foreach

```latex
% Multiple variables with slash separation
\foreach \x/\label in {0/a, 1/b, 2/c}
  \node at (\x, 0) {\label};

% Computed values
\foreach \x [evaluate=\x as \shade using \x*10] in {0,...,10}
  \node[fill=red!\shade!yellow] at (\x, 0) {\x};

% State across iterations
\foreach \x [remember=\x as \prev (initially A)] in {B,...,H}
  \draw (\prev) -- (\x);

% Position tracking
\foreach \x [count=\i from 0] in {a,...,e}
  \node at (\i, 0) {\x};

% Nested (automatic body collection)
\foreach \x in {0,...,3}
  \foreach \y in {0,...,3}
    \draw (\x, \y) circle (0.2);
```

## Design patterns from the masters

### Pattern 1: Define / Get / Draw separation (tkz-euclide)

Separate computation from rendering:

- **Define** — compute coordinates with no visual side effects
- **Get** — bind anonymous results to named handles
- **Draw** — render already-defined objects

```latex
\tkzDefPoint(0,0){A}              % define
\tkzDefPoint(5,2){B}
\tkzInterCC(A,B)(B,A)             % compute intersections
\tkzGetPoints{C}{D}               % bind results to names
\tkzDrawCircles(A,B B,A)          % render
\tkzDrawPolygon(A,B,C)
```

The define layer wraps computations in `\pgfinterruptboundingbox` so
construction geometry doesn't affect the output size. Points are the only
persistent objects. Circles, lines, and polygons are derived from points at draw
time.

Computations deposit results into well-known registers (`tkzPointResult`,
`tkzFirstPointResult`, `\tkzLengthResult`). `\tkzGetPoint{X}` aliases the
register to a chosen name. Each computation writes to a fixed register; the
caller decides the name.

### Pattern 2: The @@-convention for safe extension (tikz-feynman)

Every domain concept uses a three-part key structure:

```latex
every dot@@/.style={...}    % (a) internal implementation
every dot/.style={           % (b) user customization hook
  /tikzfeynman/every dot@@/.append style={#1}
}
dot/.style={                 % (c) activation key (what users write)
  /tikzfeynman/every dot@@
}
```

`\tikzfeynmanset{every dot={red}}` appends red to the base `@@` definition
without replacing it.

### Pattern 3: Namespace with search fallthrough

Create a dedicated key family. Unresolved keys fall through to TikZ:

```latex
\pgfkeys{
  /tikzfeynman/.is family,
  /tikzfeynman/.search also={/tikz},
}
```

Inside the DSL environment, domain keys (`fermion`, `boson`, `dot`) and TikZ
keys (`draw`, `red`, `thick`) coexist. `.search also` tries unresolved keys
against `/tikz`. tikzlings chains four levels:
`/bear/.search also={/tikz, /pgf, /thing}`.

### Pattern 4: draw=none + postaction for visual stacking (tikz-feynman)

A **postaction** executes after the path geometry is computed. Suppress the
default draw, then render as a postaction:

```latex
every boson@@/.style={
  draw=none,                    % suppress default rendering
  decoration={name=none},
  postaction={                  % render AFTER path geometry is computed
    draw,
    decoration={complete sines, amplitude=1mm, segment length=2mm},
    decorate=true,
  },
},
```

Multiple postactions on the same path compose independently. Charged particles
inherit the base boson style and add an arrow postaction on top.

### Pattern 5: The cube/block pic for 3D layer diagrams (PetarV-)

A `pic` that draws a 3D rectangular prism. Each face is drawn inside its own
`\clip` scope to prevent fill from bleeding past face boundaries. Named anchors
(`-A`, `-B`) allow inter-layer wiring:

```latex
\tikzset{pics/cube/.style args={#1/#2/#3/#4}{code={
  \begin{scope}[line width=#4mm]
    % Front face: clip boundary, then fill
    \begin{scope}
      \clip (-#1,-#2,0) -- (#1,-#2,0) -- (#1,#2,0) -- (-#1,#2,0) -- cycle;
      \filldraw (-#1,-#2,0) -- (#1,-#2,0) -- (#1,#2,0) -- (-#1,#2,0) -- cycle;
    \end{scope}
    % Top face, left face (similar)
    ...
    % Named anchors for inter-layer wiring
    \node[inner sep=0] (-A) at (-#1-#3*0.5, 0, -#3*0.5) {};
    \node[inner sep=0] (-B) at (#1-#3*0.5, 0, -#3*0.5) {};
  \end{scope}
}}}
```

Varying the four parameters encodes architecture: shrinking width/height (1.8 ->
0.9 -> 0.45) with growing depth (1 -> 2 -> 6) represents spatial reduction and
channel growth in a CNN.

### Pattern 6: Style inheritance for type hierarchies (tikz-bayesnet)

Derived styles override only the properties that differ from the base:

```latex
\tikzstyle{latent} = [circle, fill=white, draw=black, minimum size=20pt]
\tikzstyle{obs}    = [latent, fill=gray!25]     % override fill only
\tikzstyle{det}    = [latent, diamond]           % override shape only
\tikzstyle{const}  = [rectangle, inner sep=0pt]  % different base entirely
```

**Plates** (labeled bounding boxes) compose via the `fit` library, which
auto-sizes a node to enclose a set of other nodes:

```latex
\newcommand{\plate}[4][]{
  \node[wrap=#3] (#2-wrap) {};           % measure interior
  \node[plate caption=#2-wrap] (#2-cap) {#4};  % place label
  \node[plate=(#2-wrap)(#2-cap), #1] (#2) {};  % draw boundary fitting both
}
```

Plates nest: the outer plate fits the inner plate node like any other node.

### Pattern 7: Parameterized custom commands (janosh, walmes)

`\newcommand` macros stamp out repeated substructure:

```latex
% Neural network: orthogonal composition commands
\newcommand\drawNodes[2]{
  \foreach \neurons [count=\lyrIdx] in #2 {
    \foreach \n [count=\nIdx] in \neurons
      \node[neuron] (#1-\lyrIdx-\nIdx) at (...) {\n};
  }
}
\newcommand\denselyConnectNodes[2]{...}
\newcommand\connectSomeNodes[2]{...}
```

The `#1` namespace parameter allows multiple independent networks in one
tikzpicture. Three orthogonal commands (place, connect-all, connect-selectively)
compose to build both a fully-connected net and a masked autoencoder from the
same primitives.

A command that returns a small tikzpicture can be placed as node content:

```latex
\newcommand{\distro}[3]{
  \begin{tikzpicture}
    \draw[blue, thick] plot[domain=-1:1, samples=40]
      ({\t}, {#1*exp(-10*\t^2) + #2*exp(-60*(\t-0.6)^2) + #3*...});
  \end{tikzpicture}
}
\node at (0,0) {\distro{1}{0}{0}};
\node at (3,0) {\distro{0.5}{0.8}{0.3}};
```

### Pattern 8: Natural-language key-value arguments (tkz-euclide)

`.code args` embeds English prepositions in the pattern-matching syntax:

```latex
\pgfkeys{/tkzDefPointBy/.cd,
  translation/.code args  = {from #1 to #2}{...},
  rotation/.code args     = {center #1 angle #2}{...},
  reflection/.code args   = {over #1--#2}{...},
  projection/.code args   = {onto #1--#2}{...},
  homothety/.code args    = {center #1 ratio #2}{...},
}
```

Usage reads like a construction procedure:

```latex
\tkzDefPointBy[rotation=center B angle 36](C)
\tkzDefPointBy[reflection=over A--B](M)
```

### Pattern 9: White-underlay for edge crossing (PetarV-)

Draw a thick white line first, then the actual edge on top. The white line
erases the crossing point, creating a visual bridge:

```latex
\path[-stealth, ultra thick, white] (X1) edge[bend left=45] (R22);
\path[-stealth, thick]              (X1) edge[bend left=45] (R22);
```

### Pattern 10: declare function + pgfplots (walmes)

`declare function` defines mathematical functions at the TikZ level. Functions
compose (`betapdf` calls `gamma`):

```latex
\begin{tikzpicture}[
  declare function={
    normalpdf(\x,\mu,\sigma) =
      (2*3.1415*\sigma^2)^(-0.5) * exp(-(\x-\mu)^2/(2*\sigma^2));
    gamma(\z) = (2.506628*sqrt(1/\z) + ...)*exp((-ln(1/\z)-1)*\z);
    betapdf(\x,\a,\b) = gamma(\a+\b)/(gamma(\a)*gamma(\b))
                         * \x^(\a-1) * (1-\x)^(\b-1);
  }]
```

Then `\addplot[smooth, thick] {normalpdf(x, 0, 1)};` inside a pgfplots axis.

## Building a domain-specific TikZ library

Five steps, generalized from tikz-feynman, tikz-bayesnet, automata, mindmap, and
tkz-euclide:

### Step 1: Create a key family with fallthrough

```latex
\pgfkeys{
  /mydomain/.is family,
  /mydomain/.search also={/tikz},
}
\def\mydomainset{\pgfqkeys{/mydomain}}
```

### Step 2: Define domain vocabulary as styles

Use the @@-convention for each concept:

```latex
\mydomainset{
  every widget@@/.style={draw, circle, minimum size=1cm},
  every widget/.style={/mydomain/every widget@@/.append style={#1}},
  widget/.style={/mydomain/every widget@@},
}
```

### Step 3: Wire key routing in the environment

Inside your environment, install an `.unknown` handler that tries your family:

```latex
\newenvironment{mydomain}[1][]{%
  \begin{scope}%
  \pgfkeys{/tikz/.unknown/.code={%
    \pgfkeys{/mydomain/\pgfkeyscurrentname/.try={##1}}%
  }}%
  \mydomainset{#1}%
}{%
  \end{scope}%
}
```

### Step 4: Define compound commands that compose primitives

```latex
\newcommand{\edge}[3][]{%
  \foreach \x in {#2} {
    \foreach \y in {#3} {
      \path (\x) edge [->, #1] (\y);
    };
  };
}
```

### Step 5: Expose "every" hooks for user customization

Users modify appearance globally without touching the library:

```latex
\mydomainset{every widget={fill=blue!20}}
```

## Practical techniques

### 3D rendering

**Strategy A: tikz-3dplot.** Set viewing angles once; all coordinates
participate in the projection:

```latex
\tdplotsetmaincoords{75}{50}
\begin{tikzpicture}[tdplot_main_coords]
  \tdplotsetcoord{P}{\rvec}{\thetavec}{\phivec}
  % auto-generates P, Px, Py, Pz, Pxy projections
```

**Strategy B: oblique custom axes.** Simpler; good for isometric views:

```latex
\begin{tikzpicture}[x=(-15:0.9), y=(90:0.9), z=(-150:1.1)]
```

**Strategy C: clip-then-fill.** Draw faces in painter's order, each inside its
own `\clip` scope to prevent fill from bleeding past face boundaries.

### Graph drawing (LuaTeX only)

Declare graph structure; let a layout algorithm compute positions:

```latex
\usetikzlibrary{graphs, graphdrawing}
\usegdlibrary{trees, layered, force}

\graph[tree layout, sibling distance=8mm] {
  a -> { b, c -> { d, e } }
};
```

Sublayouts apply different algorithms to subgraphs:

```latex
\graph[spring layout] {
  // [tree layout] { a -> {b, c} };  % inner: tree
  // [tree layout] { 1 -> 2 };       % inner: tree
  a -> 1;                             % outer: force-directed
};
```

### Decoration markings

Place arbitrary content at parametric positions along a path:

```latex
\draw[postaction={decorate, decoration={markings,
  mark=at position 0.5 with {\node[above] {midpoint};},
  mark=between positions 0 and 1 step 1cm with {\arrow{stealth}},
}}] (0,0) .. controls (2,2) .. (4,0);
```

### Matrix of nodes

```latex
\matrix (M) [matrix of math nodes, row sep=0.5cm, column sep=1cm] {
  a & b & c \\
  d & e & f \\
};
\draw[->] (M-1-1) -- (M-1-2);     % reference by (name-row-col)
```

Style individual cells inline (`|[red]| x`) or by position
(`row 2 column 3/.style=red`).

### Chains

```latex
\begin{tikzpicture}[start chain=going right, node distance=5mm,
                     every on chain/.style={draw}, every join/.style={->}]
  \node[on chain] {A};
  \node[on chain, join] {B};
  \node[on chain, join] {C};
\end{tikzpicture}
```

Nodes auto-name as `chain-1`, `chain-2`, etc. `join` draws edges between
consecutive nodes.

### Panel composition

Multiple sub-diagrams in one tikzpicture via shifted scopes:

```latex
\begin{scope}[shift={(0,0)}]
  ...first panel...
\end{scope}
\begin{scope}[shift={(7,0)}]
  ...second panel...
\end{scope}
```

### Saveboxes

Avoid nested tikzpictures (which are generally broken) by pre-rendering into
saveboxes:

```latex
\newsavebox\mybox
\savebox\mybox{
  \begin{tikzpicture}[scale=0.2]
    \draw plot[smooth] coordinates {...};
  \end{tikzpicture}
}
\node at (3,2) {\usebox\mybox};
```

### Semantic edge types

Assign decorations to semantic categories:

```latex
% Deterministic connection
\draw[-stealth, thick] (A) -- (B);

% Stochastic / lateral connection
\draw[-stealth, thick, decoration={snake, segment length=2mm,
  amplitude=0.3mm, post length=1.5mm}, decorate] (A) -- (B);

% Attention head
\draw[-stealth, thick, decoration={zigzag, segment length=2mm,
  amplitude=0.3mm, post length=1.5mm}, decorate] (A) -- (B);
```

Offset anchors prevent parallel edges from overlapping: `(A.120) -- (B.-30)`,
`(A.135) -- (B.-45)`, `(A.150) -- (B.-60)`.

## Standalone document pattern

```latex
\documentclass[crop, tikz]{standalone}
\usetikzlibrary{positioning, calc, arrows.meta}

\begin{document}
\begin{tikzpicture}
  ...
\end{tikzpicture}
\end{document}
```

`[crop, tikz]` produces a tightly cropped output with no page margins. Each
figure loads only the libraries it uses. Total independence in exchange for
minor duplication. For gallery projects, pair each `.tex` with a `.yml` sidecar
(title, tags, description, attribution).

## Transformation ordering

```latex
\draw[rotate=30, xshift=2cm] ...  % rotate first, then shift
\draw[xshift=2cm, rotate=30] ...  % shift first, then rotate (different!)
```

**Coordinate transformations** affect only coordinates. **Canvas
transformations** (`transform canvas={scale=2}`) also scale line widths and
text, which is rarely what you want. Use `transform shape` to opt nodes into
coordinate transforms.

## Specialized techniques

### Two-pass rendering for 3D occlusion

TikZ has no z-buffer. Instead, draw in two passes with toggle flags:

```latex
\newtoggle{redraw}   % controls whether left face is drawn
\newtoggle{redraw2}  % controls whether top face is drawn

% Pass 1: draw all cubes with all faces, then all arrows
\togglefalse{redraw} \togglefalse{redraw2}
\pic[fill=blue!30] (A) {cube={1.8/1.8/1/1}};
\pic[fill=red!30]  (B) {cube={0.9/0.9/2/1}};
\draw[-stealth, thick] (A-B) -- (B-A);   % arrow between layers

% Pass 2: redraw front faces only (occludes arrows behind blocks)
\toggletrue{redraw} \toggletrue{redraw2}
\pic[fill=blue!30] (A) {cube={1.8/1.8/1/1}};
\pic[fill=red!30]  (B) {cube={0.9/0.9/2/1}};
```

Pass 2 skips the left and top faces (controlled by toggle flags inside the cube
pic definition), so only the front face redraws — covering arrows that should
appear behind the block.

### path picture

`path picture` executes drawing code clipped to a node's shape boundary:

```latex
\tikzset{
  neuron/.style={circle, fill=black!25, minimum size=17pt, inner sep=0pt,
    path picture={
      \draw[red, thick] plot[domain=-0.3:0.3, samples=11, smooth]
        ({\x}, {0.05*tanh(\x*10)});
    }},
}
```

### local bounding box

`local bounding box` names the bounding box of a scope, turning it into a node
that other scopes can reference for positioning:

```latex
\begin{scope}[local bounding box=encoder]
  ... draw encoder diagram ...
\end{scope}
\begin{scope}[shift={($(encoder.east)+(2,0)$)}, local bounding box=decoder]
  ... draw decoder diagram ...
\end{scope}
\draw[->] (encoder.east) -- (decoder.west);
```

### Bounding box isolation

`\pgfinterruptboundingbox` prevents invisible construction geometry from
affecting the output size:

```latex
\pgfinterruptboundingbox
  \coordinate (aux) at (intersection of A--B and C--D);
\endpgfinterruptboundingbox
```

tkz-euclide wraps every `\tkzDef*` command this way. The construction graph is
invisible; only `\tkzDraw*` commands contribute to the bounding box.

### Rendering mode switch via macro redefinition

Redefine a drawing primitive based on options to switch rendering modes:

```latex
\ifbear@threeD
  \def\bear@part@draw[##1]{\shade[ball color=##1]}
\else
  \def\bear@part@draw[##1]{\fill[##1]}
\fi
% Every body part uses \bear@part@draw[\bear@body]
```

Every body part calls `\bear@part@draw[\bear@body]`. The entire animal switches
between flat fill, ball-color shading, or contour outline without changing any
body-part code.

### Domain synonyms via \let aliases

`\let` creates a zero-cost alias:

```latex
\let\tkzNinePointCenter\tkzEulerCenter
\let\tkzLemoinePoint\tkzSymmedianCenter
\let\tkzBaryCenter\tkzCentroid
```

In key-value options, map multiple keys to the same dispatch target:

```latex
euler/.code = \def\tkz@numtc{5},
nine/.code  = \def\tkz@numtc{5},   % same target
```

The DSL speaks the language of different mathematical traditions (Euler center =
nine-point center, Lemoine point = Grebe point) without code duplication.

### after node path

`after node path` executes code after a node is placed. `##1` refers to the node
just created. The automata library uses this to draw initial-state arrows:

```latex
\tikzset{
  initial/.style={after node path={
    \draw[->] ($(##1.west)+(-1cm,0)$) -- (##1.west);
  }},
}
```

The chains library uses the same hook to draw `join` edges.

### Oblique projection

`\pgftransformcm` applies an affine transformation matrix. Use it for
multiplexed/stacked layers:

```latex
\newcommand{\myProjection}[2]{
  \pgftransformcm{1}{0}{0.4}{0.5}{\pgfpoint{#1cm}{#2cm}}
}
\begin{scope}
  \myProjection{0}{0}
  ... draw layer 1 ...
\end{scope}
\begin{scope}
  \myProjection{0}{3}
  ... draw layer 2 ...
\end{scope}
% Interlayer connections: use \pgftransformreset inside scope
```

Each layer draws in its own skewed coordinate system. Interlayer connections
call `\pgftransformreset` inside their scope to draw in screen space.

## Common mistakes

- `transform canvas={scale=2}` doubles line widths and text. You probably want
  `scale=2`, which affects only coordinates.
- Nodes must be declared before referenced by name. You can't draw an arrow to
  `(B)` if `(B)` hasn't been placed yet.
- Without `pic actions` in a pic definition, `\pic[fill=red]{...}` has no effect
  on the pic body.
- Nested tikzpictures are broken. Use scopes, pics, or saveboxes.
- `\tikzstyle` is deprecated. Use `\tikzset{name/.style={...}}`.

## References

### Manual

- [PGF/TikZ Manual](https://tikz.dev/) — the complete online reference; the
  [pics](https://tikz.dev/tikz-pics), [scopes](https://tikz.dev/tikz-scopes),
  [foreach](https://tikz.dev/pgffor), and
  [graph drawing](https://tikz.dev/gd-usage-tikz) chapters are the most relevant
  to compositional work

### Repositories studied

- [al-ma-dev/tkz-euclide](https://github.com/al-ma-dev/tkz-euclide) — Alain
  Matthes' Euclidean geometry DSL; the Define/Get/Draw separation and
  natural-language key-value patterns originate here
- [JP-Ellis/tikz-feynman](https://github.com/JP-Ellis/tikz-feynman) — Feynman
  diagram DSL; source of the @@-convention, postaction stacking, and namespace
  fallthrough patterns
- [PetarV-/TikZ](https://github.com/PetarV-/TikZ) — 60 publication-ready ML
  architecture figures; source of the cube pic, two-pass occlusion, and
  white-underlay patterns
- [janosh/tikz](https://github.com/janosh/tikz) — 137 standalone physics/ML
  figures with YML sidecar metadata; source of the parameterized command and
  standalone document patterns
- [jluttine/tikz-bayesnet](https://github.com/jluttine/tikz-bayesnet) — Bayesian
  network DSL; source of the style-inheritance hierarchy and fit-based plate
  patterns
- [samcarter/tikzlings](https://github.com/samcarter/tikzlings) — composable
  character figures; source of the rendering mode switch and search-also
  fallthrough chain patterns
- [HarisIqbal88/PlotNeuralNet](https://github.com/HarisIqbal88/PlotNeuralNet) —
  3D neural network diagrams with Python generation pipeline
- [IzaakWN/CodeSnippets](https://github.com/IzaakWN/CodeSnippets) — Izaak
  Neutelings' particle physics TikZ; tikz-3dplot and oblique projection
  techniques
- [walmes/Tikz](https://github.com/walmes/Tikz) — 298 statistics teaching
  figures; declare function composition and pgfplots patterns
- [f0nzie/tikz_favorites](https://github.com/f0nzie/tikz_favorites) — 257
  curated examples; path picture, savebox, and Kalman filter matrix patterns
- [pgf-tikz/pgf](https://github.com/pgf-tikz/pgf) — the PGF/TikZ source; pgfkeys
  internals, library extension architecture, graph drawing Lua bridge

### Books

- Stefan Kottwitz, _LaTeX Graphics with TikZ_ (Packt, 2023) — practical guide by
  the maintainer of TikZ.net, TeXample.net, and PGFplots.net

### Galleries

- [TikZ.net](https://tikz.net/) — physics-focused gallery by Izaak Neutelings
- [TeXample.net](https://texample.net/) — the original TikZ example gallery
- [TeX.SE: Nice scientific pictures show off](https://tex.stackexchange.com/questions/158668/nice-scientific-pictures-show-off)
  — community showcase with source code
