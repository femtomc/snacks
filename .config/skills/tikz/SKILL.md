---
description: "Writing TikZ diagrams in .tex files"
---

# TikZ

Compositional, publication-quality TikZ graphics.

## The mental model

TikZ is a declarative graphics DSL embedded in TeX. Everything composes through
**pgfkeys**, a hierarchical key-value system. A pgfkeys *style* is a named
bundle of options that injects its options into the current parse. Styles are
first-class functions over the option set.

Composition hierarchy, coarsest to finest:

```
tikzpicture  →  scope  →  path/node/pic  →  style/option  →  pgfkey
```

A **scope** groups options inside a TeX group (locally scoped state). A
**style** bundles options for reuse. A **pic** runs a named, parameterized
chunk of TikZ in a fresh scope. A **node** is both a drawn shape and a named
coordinate that persists across scopes.

## Foundational patterns

### Styles compose through application

```latex
% These are equivalent — a style is code that injects keys:
foo/.style={draw, red}
foo/.code={\pgfkeysalso{draw, red}}

\tikzset{my base/.style={draw, thick}}
\tikzset{my base/.append style={red}}              % adds, keeps base
\tikzset{my derived/.style={my base, fill=blue!20}}  % inherits everything
```

`.append style` adds; `.prefix style` prepends. Both leave the original intact.

### The "every" pattern

TikZ pre-declares empty styles at every processing stage. Filling one changes
every instance:

```latex
every picture/.style={}    every scope/.style={}
every path/.style={}       every node/.style={}
every edge/.style={draw}   every child/.style={}
```

Libraries add domain hooks: `every state`, `every concept`, `every entity`.

### Nodes are visual elements and named coordinates

```latex
\node[circle, draw] (A) at (0,0) {$\alpha$};
\node[rectangle, draw] (B) at (3,0) {$\beta$};
\draw[->] (A.east) -- (B.west);
\draw[->] (A.north) to[bend left] (B.north);
```

Anchors: `north`, `south`, `east`, `west`, compass combinations, `base`, `mid`,
angle-based (`A.45`), shape-specific.

### Pics

A pic runs named TikZ code in a fresh scope, exposing named coordinates:

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

`pic actions` propagates the caller's draw/fill into the pic body. Three layer
slots: `background code`, `code`, `foreground code`.

### Scopes isolate state

```latex
\begin{scope}[rotate=30, red, thick]
  \draw (0,0) -- (1,1);   % rotated, red, thick
\end{scope}
\draw (0,0) -- (1,1);     % defaults restored
```

The `scopes` library adds shorthand: `{[red] \draw ...;}`.

### Coordinate arithmetic (calc library)

```latex
($(A)!0.5!(B)$)           % midpoint
($(A)!1cm!(B)$)           % 1cm from A toward B
($(A) + (1,0.5)$)         % vector addition
($(A)!(P)!(B)$)           % projection of P onto A--B
(A |- B)                  % x from A, y from B (perpendicular intersection)
```

Named intersections (intersections library):

```latex
\draw[name path=c1] (0,0) circle (1);
\draw[name path=c2] (1,0) circle (1);
\fill[name intersections={of=c1 and c2, by={P,Q}}]
  (P) circle (2pt) (Q) circle (2pt);
```

### foreach

```latex
\foreach \x/\label in {0/a, 1/b, 2/c}
  \node at (\x, 0) {\label};

\foreach \x [evaluate=\x as \shade using \x*10] in {0,...,10}
  \node[fill=red!\shade!yellow] at (\x, 0) {\x};

\foreach \x [remember=\x as \prev (initially A)] in {B,...,H}
  \draw (\prev) -- (\x);

\foreach \x [count=\i from 0] in {a,...,e}
  \node at (\i, 0) {\x};
```

## Design patterns from the masters

### 1. Define / Get / Draw separation (tkz-euclide)

Compute coordinates, name them, then render:

```latex
\tkzDefPoint(0,0){A}
\tkzDefPoint(5,2){B}
\tkzInterCC(A,B)(B,A)             % compute intersections
\tkzGetPoints{C}{D}               % bind to names
\tkzDrawCircles(A,B B,A)
\tkzDrawPolygon(A,B,C)
```

The define layer wraps in `\pgfinterruptboundingbox` so construction geometry
does not affect output size.

### 2. The @@-convention for safe extension (tikz-feynman)

```latex
every dot@@/.style={...}    % (a) internal implementation
every dot/.style={           % (b) user customization hook
  /tikzfeynman/every dot@@/.append style={#1}
}
dot/.style={                 % (c) activation key
  /tikzfeynman/every dot@@
}
```

`\tikzfeynmanset{every dot={red}}` appends red without replacing the base.

### 3. Namespace with search fallthrough

```latex
\pgfkeys{
  /tikzfeynman/.is family,
  /tikzfeynman/.search also={/tikz},
}
```

Inside the DSL environment, domain keys (`fermion`, `boson`) and TikZ keys
(`draw`, `red`) coexist. tikzlings chains four levels:
`/bear/.search also={/tikz, /pgf, /thing}`.

### 4. draw=none + postaction for visual stacking

```latex
every boson@@/.style={
  draw=none,
  postaction={
    draw,
    decoration={complete sines, amplitude=1mm, segment length=2mm},
    decorate=true,
  },
},
```

Multiple postactions on the same path compose independently. Charged particles
inherit the boson style and add an arrow postaction on top.

### 5. The cube/block pic for 3D layer diagrams (PetarV-)

```latex
\tikzset{pics/cube/.style args={#1/#2/#3/#4}{code={
  \begin{scope}[line width=#4mm]
    \begin{scope}                   % per-face clip prevents fill bleed
      \clip (-#1,-#2,0) -- (#1,-#2,0) -- (#1,#2,0) -- (-#1,#2,0) -- cycle;
      \filldraw (-#1,-#2,0) -- (#1,-#2,0) -- (#1,#2,0) -- (-#1,#2,0) -- cycle;
    \end{scope}
    % Top face, left face similar.
    \node[inner sep=0] (-A) at (-#1-#3*0.5, 0, -#3*0.5) {};
    \node[inner sep=0] (-B) at (#1-#3*0.5, 0, -#3*0.5) {};
  \end{scope}
}}}
```

Varying parameters encodes architecture (e.g. CNN: shrinking width/height with
growing depth).

### 6. Style inheritance for type hierarchies (tikz-bayesnet)

```latex
\tikzstyle{latent} = [circle, fill=white, draw=black, minimum size=20pt]
\tikzstyle{obs}    = [latent, fill=gray!25]      % override fill
\tikzstyle{det}    = [latent, diamond]            % override shape
\tikzstyle{const}  = [rectangle, inner sep=0pt]   % different base

% Plates compose via the fit library:
\newcommand{\plate}[4][]{
  \node[wrap=#3] (#2-wrap) {};
  \node[plate caption=#2-wrap] (#2-cap) {#4};
  \node[plate=(#2-wrap)(#2-cap), #1] (#2) {};
}
```

### 7. Parameterized custom commands

```latex
\newcommand\drawNodes[2]{
  \foreach \neurons [count=\lyrIdx] in #2 {
    \foreach \n [count=\nIdx] in \neurons
      \node[neuron] (#1-\lyrIdx-\nIdx) at (...) {\n};
  }
}
```

`#1` namespaces nodes so multiple networks coexist in one tikzpicture. A
command returning a small tikzpicture can be a node's content:

```latex
\newcommand{\distro}[3]{
  \begin{tikzpicture}
    \draw[blue, thick] plot[domain=-1:1, samples=40]
      ({\t}, {#1*exp(-10*\t^2) + #2*exp(-60*(\t-0.6)^2) + #3*...});
  \end{tikzpicture}
}
\node at (0,0) {\distro{1}{0}{0}};
```

### 8. Natural-language key-value arguments (tkz-euclide)

```latex
\pgfkeys{/tkzDefPointBy/.cd,
  translation/.code args  = {from #1 to #2}{...},
  rotation/.code args     = {center #1 angle #2}{...},
  reflection/.code args   = {over #1--#2}{...},
}

\tkzDefPointBy[rotation=center B angle 36](C)
\tkzDefPointBy[reflection=over A--B](M)
```

### 9. White-underlay for edge crossing (PetarV-)

```latex
\path[-stealth, ultra thick, white] (X1) edge[bend left=45] (R22);
\path[-stealth, thick]              (X1) edge[bend left=45] (R22);
```

The white line erases the crossing point; the colored line draws a visual
bridge.

### 10. declare function + pgfplots (walmes)

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

## Building a domain library

Five steps from tikz-feynman, tikz-bayesnet, automata, mindmap, tkz-euclide:

```latex
% 1. Key family with fallthrough
\pgfkeys{
  /mydomain/.is family,
  /mydomain/.search also={/tikz},
}
\def\mydomainset{\pgfqkeys{/mydomain}}

% 2. Vocabulary as styles via the @@-convention
\mydomainset{
  every widget@@/.style={draw, circle, minimum size=1cm},
  every widget/.style={/mydomain/every widget@@/.append style={#1}},
  widget/.style={/mydomain/every widget@@},
}

% 3. Environment with key routing
\newenvironment{mydomain}[1][]{%
  \begin{scope}%
  \pgfkeys{/tikz/.unknown/.code={%
    \pgfkeys{/mydomain/\pgfkeyscurrentname/.try={##1}}%
  }}%
  \mydomainset{#1}%
}{\end{scope}}

% 4. Compound commands
\newcommand{\edge}[3][]{%
  \foreach \x in {#2} {
    \foreach \y in {#3} {\path (\x) edge [->, #1] (\y);};
  };
}

% 5. User-facing "every" hooks
\mydomainset{every widget={fill=blue!20}}
```

## Practical techniques

### 3D rendering

```latex
% A. tikz-3dplot (set angles once, all coords project)
\tdplotsetmaincoords{75}{50}
\begin{tikzpicture}[tdplot_main_coords]
  \tdplotsetcoord{P}{\rvec}{\thetavec}{\phivec}

% B. Oblique custom axes (simpler isometric)
\begin{tikzpicture}[x=(-15:0.9), y=(90:0.9), z=(-150:1.1)]

% C. Clip-then-fill — draw faces in painter's order, each in its own \clip
```

### Graph drawing (LuaTeX)

```latex
\usetikzlibrary{graphs, graphdrawing}
\usegdlibrary{trees, layered, force}

\graph[tree layout, sibling distance=8mm] {
  a -> { b, c -> { d, e } }
};

\graph[spring layout] {              % sublayouts
  // [tree layout] { a -> {b, c} };
  a -> 1;
};
```

### Decoration markings

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
\draw[->] (M-1-1) -- (M-1-2);     % name-row-col
```

### Chains

```latex
\begin{tikzpicture}[start chain=going right, node distance=5mm,
                     every on chain/.style={draw}, every join/.style={->}]
  \node[on chain] {A};
  \node[on chain, join] {B};
  \node[on chain, join] {C};
\end{tikzpicture}
```

### Panel composition

```latex
\begin{scope}[shift={(0,0)}]    ...first panel...    \end{scope}
\begin{scope}[shift={(7,0)}]    ...second panel...   \end{scope}
```

### Saveboxes (avoid nested tikzpictures)

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

```latex
\draw[-stealth, thick] (A) -- (B);                                  % deterministic
\draw[-stealth, thick, decoration={snake, segment length=2mm,
  amplitude=0.3mm, post length=1.5mm}, decorate] (A) -- (B);        % stochastic
\draw[-stealth, thick, decoration={zigzag, segment length=2mm,
  amplitude=0.3mm, post length=1.5mm}, decorate] (A) -- (B);        % attention
```

Offset anchors prevent parallel edges from overlapping:
`(A.120) -- (B.-30)`, `(A.135) -- (B.-45)`.

## Standalone document

```latex
\documentclass[crop, tikz]{standalone}
\usetikzlibrary{positioning, calc, arrows.meta}

\begin{document}
\begin{tikzpicture}
  ...
\end{tikzpicture}
\end{document}
```

`[crop, tikz]` produces tightly cropped output. For galleries, pair each `.tex`
with a `.yml` sidecar (title, tags, attribution).

## Transformation ordering

```latex
\draw[rotate=30, xshift=2cm] ...  % rotate first, then shift
\draw[xshift=2cm, rotate=30] ...  % shift first, then rotate (different!)
```

**Coordinate** transformations affect coordinates only. **Canvas**
transformations (`transform canvas={scale=2}`) also scale line widths and text
— rarely what you want.

## Specialized techniques

### Two-pass rendering for 3D occlusion

TikZ has no z-buffer. Use toggles to selectively redraw front faces:

```latex
\newtoggle{redraw}
\newtoggle{redraw2}

% Pass 1: full cubes + arrows
\togglefalse{redraw} \togglefalse{redraw2}
\pic[fill=blue!30] (A) {cube={1.8/1.8/1/1}};
\pic[fill=red!30]  (B) {cube={0.9/0.9/2/1}};
\draw[-stealth, thick] (A-B) -- (B-A);

% Pass 2: redraw front faces only — covers arrows passing behind
\toggletrue{redraw} \toggletrue{redraw2}
\pic[fill=blue!30] (A) {cube={1.8/1.8/1/1}};
\pic[fill=red!30]  (B) {cube={0.9/0.9/2/1}};
```

### path picture

Drawing code clipped to a node's shape:

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

Names a scope's bounding box as a node for cross-scope positioning:

```latex
\begin{scope}[local bounding box=encoder]
  ...
\end{scope}
\begin{scope}[shift={($(encoder.east)+(2,0)$)}, local bounding box=decoder]
  ...
\end{scope}
\draw[->] (encoder.east) -- (decoder.west);
```

### Bounding box isolation

```latex
\pgfinterruptboundingbox
  \coordinate (aux) at (intersection of A--B and C--D);
\endpgfinterruptboundingbox
```

### Rendering mode switch via macro redefinition

```latex
\ifbear@threeD
  \def\bear@part@draw[##1]{\shade[ball color=##1]}
\else
  \def\bear@part@draw[##1]{\fill[##1]}
\fi
% Every body part calls \bear@part@draw[\bear@body]
```

The whole figure switches rendering mode without touching part code.

### Domain synonyms via \let

```latex
\let\tkzNinePointCenter\tkzEulerCenter
\let\tkzLemoinePoint\tkzSymmedianCenter

% Or in keys, dispatch multiple keys to the same target:
euler/.code = \def\tkz@numtc{5},
nine/.code  = \def\tkz@numtc{5},
```

### after node path

```latex
\tikzset{
  initial/.style={after node path={
    \draw[->] ($(##1.west)+(-1cm,0)$) -- (##1.west);
  }},
}
```

`##1` refers to the just-placed node. The chains library uses the same hook for
`join` edges.

### Oblique projection

```latex
\newcommand{\myProjection}[2]{
  \pgftransformcm{1}{0}{0.4}{0.5}{\pgfpoint{#1cm}{#2cm}}
}
\begin{scope} \myProjection{0}{0}  ... \end{scope}
\begin{scope} \myProjection{0}{3}  ... \end{scope}
% Interlayer connections: \pgftransformreset inside scope
```

## References

### Manual

- [PGF/TikZ Manual](https://tikz.dev/) — complete reference.
  [pics](https://tikz.dev/tikz-pics), [scopes](https://tikz.dev/tikz-scopes),
  [foreach](https://tikz.dev/pgffor),
  [graph drawing](https://tikz.dev/gd-usage-tikz) are the most relevant
  chapters.

### Repositories studied

- [al-ma-dev/tkz-euclide](https://github.com/al-ma-dev/tkz-euclide) — Define/Get/Draw,
  natural-language key-value
- [JP-Ellis/tikz-feynman](https://github.com/JP-Ellis/tikz-feynman) —
  @@-convention, postaction stacking, namespace fallthrough
- [PetarV-/TikZ](https://github.com/PetarV-/TikZ) — cube pic, two-pass
  occlusion, white-underlay
- [janosh/tikz](https://github.com/janosh/tikz) — parameterized commands,
  standalone+YML sidecar
- [jluttine/tikz-bayesnet](https://github.com/jluttine/tikz-bayesnet) — style
  inheritance, fit-based plates
- [samcarter/tikzlings](https://github.com/samcarter/tikzlings) — rendering
  mode switch, search-also chains
- [HarisIqbal88/PlotNeuralNet](https://github.com/HarisIqbal88/PlotNeuralNet) —
  3D NN diagrams with Python pipeline
- [IzaakWN/CodeSnippets](https://github.com/IzaakWN/CodeSnippets) — 3dplot,
  oblique projection
- [walmes/Tikz](https://github.com/walmes/Tikz) — 298 statistics figures;
  declare function, pgfplots
- [f0nzie/tikz_favorites](https://github.com/f0nzie/tikz_favorites) — 257
  examples; path picture, savebox
- [pgf-tikz/pgf](https://github.com/pgf-tikz/pgf) — pgfkeys internals, library
  architecture, gd Lua bridge

### Books and galleries

- Kottwitz, _LaTeX Graphics with TikZ_ (Packt, 2023)
- [TikZ.net](https://tikz.net/), [TeXample.net](https://texample.net/),
  [TeX.SE Nice scientific pictures](https://tex.stackexchange.com/questions/158668/nice-scientific-pictures-show-off)
