---
description: "Modifying .tex files (non-TikZ content)"
---

# LaTeX

How to produce publication-quality documents. Covers everything outside TikZ
graphics (see `tikz.md` for that).

## The mental model

TeX processes input in four stages: **assign catcodes** (each character gets a
category — escape, group delimiter, math shift, letter, etc.), **tokenize**
(characters become tokens), **expand** (macros substitute), **execute** (tokens
produce typeset output or state changes).

The key consequence: **catcodes are assigned at tokenization time, before
expansion.** A macro that changes catcodes cannot affect arguments already
tokenized. This is why `\verb` breaks inside other commands — by the time
`\verb` runs, its argument characters have already been tokenized with their
normal catcodes, so the verbatim catcode reassignment arrives too late. It is
also why `\makeatletter` must appear before code that uses `@`-commands: `@`
must be recategorized as a letter before TeX scans the command name.

LaTeX is a macro layer over TeX. Packages are macro libraries. When something
breaks, the explanation is always in this four-stage pipeline.

## Microtypography

### microtype

`\usepackage{microtype}` activates three refinements that improve line breaking
and margin alignment without any markup changes:

- **Protrusion (margin kerning):** Small characters — hyphens, periods, serif
  tips — protrude slightly past the margin, making the text edge _optically_
  straight rather than mechanically straight.
- **Font expansion:** Characters stretch or shrink imperceptibly (default up to
  2%) to reduce interword spacing variation. This gives the line-breaking
  algorithm more room to find good breaks.
- **Tracking:** Letterspacing adjustment, especially for small caps.

The default `stretch`/`shrink` value of 20 causes visible blurring from
rasterization artifacts. Reduce to 10:

```latex
\usepackage[
  activate={true,nocompatibility},
  final,
  tracking=true,
  factor=1100,       % 10% more protrusion than default
  stretch=10,        % reduce from 20 to eliminate rasterization blur
  shrink=10
]{microtype}
```

Protrusion pushes characters into the margin, which misaligns page numbers in
tables of contents. Disable it locally:

```latex
\microtypesetup{protrusion=false}
\tableofcontents
\microtypesetup{protrusion=true}
```

Small caps benefit from light letterspacing (typographic convention: 5--12%
extra tracking):

```latex
\SetTracking{encoding={*}, shape=sc}{40}   % 0.04em
```

Note: `acmart` already loads microtype. Do not load it again — use
`\microtypesetup{...}` to customize.

### Sentence spacing

TeX inserts extra space after sentence-ending punctuation (`.`, `!`, `?`). It
suppresses this extra space when a capital letter precedes the period, on the
assumption that a capital before a period indicates an abbreviation ("Ph.D."),
not a sentence end. Two commands correct misclassification:

```latex
He had a PhD\@.  Next sentence.    % \@ resets the capital suppression
It was David vs.\ Goliath.         % backslash-space forces non-sentence space
```

Common cases needing `\ `: `e.g.\ `, `i.e.\ `, `et al.\ `, `Fig.\ `, `Eq.\ `.
Use `~` for the same effect plus no line break: `Fig.~\ref{fig:x}`.

`\frenchspacing` disables extra sentence spacing entirely. If you enable it,
`\@` and `\ ` become unnecessary.

### Horizontal spacing in math

TeX classifies every math element as one of eight **atom types** (Ord, Op, Bin,
Rel, Open, Close, Punct, Inner) and inserts spacing between adjacent atoms
according to a fixed table. The manual spacing commands override this:

| Command  | Width        | Use                                      |
| -------- | ------------ | ---------------------------------------- |
| `\!`     | -3mu         | Tighten double integrals: `\int\!\!\int` |
| `\,`     | 3mu (1/6 em) | Before differentials: `f(x)\,dx`         |
| `\:`     | 4mu          | Between related terms                    |
| `\;`     | 5mu          | Set-builder bar: `\{x \;\mid\; x > 0\}`  |
| `\quad`  | 18mu (1 em)  | Major logical separation                 |
| `\qquad` | 36mu (2 em)  | Between equation and condition           |

When the default atom classification produces wrong spacing, override it:

```latex
\mathbin{#}    % force binary operator spacing around #
\mathrel{#}    % force relational spacing
\mathord{#}    % force ordinary atom (suppress automatic spacing)
```

### Vertical spacing

Never use `\vskip` in LaTeX documents — it is a Plain TeX primitive that ends
the current paragraph immediately if used mid-paragraph. Use `\vspace`, which
defers the space insertion via `\vadjust`.

**Rubber lengths** — dimensions with stretch and shrink components — absorb
page-breaking pressure. TeX distributes stretch/shrink proportionally across all
rubber lengths on a page:

```latex
\vspace{12pt plus 3pt minus 2pt}   % natural 12pt, can stretch to 15, shrink to 10
\vspace{0pt plus 1fill}            % infinitely stretchable (pushes content to bottom)
```

Display equation spacing (tighten for space-constrained papers):

```latex
\setlength{\abovedisplayskip}{6pt plus 2pt minus 4pt}
\setlength{\belowdisplayskip}{6pt plus 2pt minus 4pt}
```

### The phantom family

Three commands create invisible boxes that reserve space for alignment:

- `\phantom{X}` — invisible box with the exact width, height, and depth of X
- `\hphantom{X}` — width of X only (zero height and depth)
- `\vphantom{X}` — height and depth of X only (zero width)

```latex
% Align positive and negative numbers by inserting invisible minus sign
\begin{cases}
  \phantom{-}1 & \text{if } x > 0 \\
            -1  & \text{if } x < 0
\end{cases}

% Force parentheses tall enough to match a fraction in another subexpression
\left( \vphantom{\frac{a}{b}} x + y \right)
= \left( \frac{a}{b} \right)
```

`\smash{X}` is the inverse — typesets X at full size but reports zero height and
depth to TeX, preventing tall content from disrupting line spacing. With
amsmath: `\smash[t]{X}` zeros only height, `\smash[b]{X}` zeros only depth.

```latex
% Prevent tall denominator from pushing next align line down
f(x) &= \frac{1}{\smash[b]{1 + \frac{1}{x}}}
```

## Math typesetting

### Delimiters: avoid \left/\right

`\left`/`\right` classify delimiters as **Inner** atoms rather than Open/Close
atoms. TeX inserts thin space between an Op atom (like `\sin`) and an Inner
atom, but zero space between an Op and an Open atom. The result: spurious space
after operators.

```latex
% BAD: thin space inserted between \sin and the parenthesis
$\sin\left(\frac{x}{2}\right)$

% GOOD: \bigl produces an Open atom, no spurious space
$\sin\bigl(\frac{x}{2}\bigr)$
```

The manual sizing hierarchy (`l`/`r`/`m` suffixes produce correct atom classes):

```latex
\bigl  \bigr       % ~1.2x normal size
\Bigl  \Bigr       % ~1.8x
\biggl \biggr      % ~2.4x
\Biggl \Biggr      % ~3.0x
```

Define semantic delimiter commands with `mathtools` to avoid choosing sizes
manually at every call site:

```latex
\DeclarePairedDelimiter{\abs}{\lvert}{\rvert}
\DeclarePairedDelimiter{\norm}{\lVert}{\rVert}
\DeclarePairedDelimiter{\ceil}{\lceil}{\rceil}
\DeclarePairedDelimiter{\floor}{\lfloor}{\rfloor}

\abs{x}                    % default size
\abs*{\frac{a}{b}}         % auto-sized via \left/\right
\abs[\Big]{\frac{a}{b}}    % explicit size override
```

### Semantic operators

`\DeclareMathOperator` produces upright font, correct operator-class spacing,
and optional limits placement. Each of these properties matters:

```latex
\DeclareMathOperator{\tr}{tr}
\DeclareMathOperator{\diag}{diag}
\DeclareMathOperator*{\argmax}{arg\,max}   % * places subscripts below in display

$\tr(A)$                          % upright, operator spacing
$\argmax_{x \in S} f(x)$         % limits below in display mode
```

For one-off operators: `\operatorname{Spec}(R)`.

Why alternatives fail: `$tr(A)$` renders italic, so "tr" looks like the product
t times r. `$\mathrm{tr}(A)$` renders upright but produces Ordinary-atom spacing
— no thin space before the parenthesis. `$\text{tr}(A)$` inherits the document
body font, which could be sans-serif.

### \text vs \mathrm vs \operatorname

| Command              | Font source   | Spaces preserved? | Atom class | Use for                                        |
| -------------------- | ------------- | ----------------- | ---------- | ---------------------------------------------- |
| `\text{...}`         | Document body | Yes               | Ordinary   | Words in math: "for all", "if"                 |
| `\mathrm{...}`       | Math Roman    | No                | Ordinary   | Upright constants: `\mathrm{e}`, `\mathrm{d}x` |
| `\operatorname{...}` | Math Roman    | No                | Operator   | Named functions: `\operatorname{Gal}`          |

The critical distinction: `\mathrm{for all}` collapses to "forall" because
`\mathrm` ignores spaces. Use `\text{for all}` for multi-word phrases.

### Punctuation atoms

| Notation | Command           | Atom class  | Correct use                        |
| -------- | ----------------- | ----------- | ---------------------------------- |
| `:`      | bare              | Relation    | Set-builder: `\{x : x > 0\}`       |
| `:`      | `\colon`          | Punctuation | Function typing: `f\colon A \to B` |
| `\|`     | `\mid`            | Relation    | Conditional: `P(A \mid B)`         |
| `\|`     | `\lvert`/`\rvert` | Open/Close  | Absolute value: `\lvert x \rvert`  |

The bare `:` produces thick space on both sides (relation). `\colon` produces no
space before and thin space after (punctuation). For function signatures,
`\colon` is always correct.

### Multi-line equations

| Environment | Alignment  | Numbering  | Nesting           | Use                            |
| ----------- | ---------- | ---------- | ----------------- | ------------------------------ |
| `align`     | At `&`     | Each line  | Standalone        | Multiple aligned equations     |
| `aligned`   | At `&`     | —          | Inside `equation` | Sub-alignment, one number      |
| `gather`    | Centered   | Each line  | Standalone        | Unrelated centered equations   |
| `multline`  | Left/right | One number | Standalone        | One long equation, broken      |
| `split`     | At `&`     | —          | Inside `equation` | One equation split, one number |

`\intertext{...}` (amsmath) inserts a full paragraph between aligned lines
without breaking alignment. `\shortintertext{...}` (mathtools) does the same
with less vertical space.

### mathtools

**`\mathclap`** — zero-width centered box. Prevents wide subscripts from pushing
adjacent content:

```latex
\sum_{\mathclap{1 \le i \le j \le n}} x_{ij}
```

Also `\mathllap` (protrudes left) and `\mathrlap` (protrudes right).

**`\smashoperator`** — collapses the horizontal extent of operator limits:

```latex
X + \smashoperator{\sum_{1 \le i \le j \le n}} x_{ij} + Y
```

**`\adjustlimits`** — vertically aligns subscripts across consecutive operators.
Without it, `\lim` and `\sup` subscripts sit at different depths:

```latex
\adjustlimits\lim_{n\to\infty} \sup_{x\in A} f_n(x)
```

**`showonlyrefs`** — suppresses equation numbers on unreferenced equations:

```latex
\mathtoolsset{showonlyrefs, showmanualtags}
```

**`dcases`** — sets the left column in `\displaystyle` so fractions render at
full size:

```latex
f(x) = \begin{dcases}
  \frac{1}{x} & \text{if } x \ne 0 \\
  0            & \text{if } x = 0
\end{dcases}
```

### Dots

`\dots` (amsmath) inspects the following token and selects baseline dots
(`\ldots`, for commas) or centered dots (`\cdots`, for binary operators). When
the following token is ambiguous or absent, use the semantic variants: `\dotsc`
(commas), `\dotsb` (binary operators), `\dotsi` (integrals).

### Commutative diagrams

Use `tikz-cd`. Arrow direction is composable letters: `r` (right), `l` (left),
`u` (up), `d` (down), `rd` (diagonal). Labels default to the right side of the
arrow; add `'` for the left side.

```latex
\begin{tikzcd}
  A \arrow[r, "f"] \arrow[d, "g"'] & B \arrow[d, "h"] \\
  C \arrow[r, "k"]                 & D
\end{tikzcd}
```

Visual editors [q.uiver.app](https://q.uiver.app/) and
[tikzcd.yichuanshen.de](https://tikzcd.yichuanshen.de/) export tikz-cd code.

## Layout and composition

### Float placement

The specifiers `[htbp!]` are **permissions**, not commands. `h` permits
placement here, `t` at page top, `b` at page bottom, `p` on a float-only page,
`!` relaxes the fraction constraints. Default is `[tbp]` — note the absence of
`h`.

Floats that cannot be placed enter a FIFO holding queue. One stuck float —
typically an oversized figure — blocks all subsequent floats of the same type.
This is usually why figures pile up at the end of a document.

Relaxed float parameters for academic papers:

```latex
\renewcommand{\topfraction}{0.85}
\renewcommand{\bottomfraction}{0.85}
\renewcommand{\textfraction}{0.15}
\renewcommand{\floatpagefraction}{0.7}
```

`\FloatBarrier` (from `placeins`) flushes all pending floats at the current
point. `\usepackage[section]{placeins}` auto-inserts barriers before each
`\section`.

Avoid `[H]` (from `float` package). It forces absolute placement by disabling
TeX's page-breaking algorithm, which typically produces worse results than
fixing the actual float constraints.

### Two-column figures (acmart)

`figure*` spans both columns but only permits `[t]` or `[p]` placement by
default. For `[b]`, use the `dblfloatfix` package. No package enables `[h]` for
`figure*` in two-column mode.

If a `figure*` appears too late in the output, move its definition earlier in
the source.

### Width lengths

| Length         | Measures             | Varies with                           |
| -------------- | -------------------- | ------------------------------------- |
| `\textwidth`   | Full text area width | Page layout only                      |
| `\columnwidth` | Current column width | One-column vs two-column mode         |
| `\linewidth`   | Current line width   | Lists, minipages, quotes, any nesting |

`\linewidth` adapts to the innermost enclosing environment. Use it for maximum
portability. Inside `figure*` (which spans both columns), use `\textwidth`.

### Side-by-side content

```latex
\begin{minipage}[t]{0.48\textwidth}
  Left content
\end{minipage}%              % <-- % prevents interword space from line break
\hfill
\begin{minipage}[t]{0.48\textwidth}
  Right content
\end{minipage}
```

The `[t]` alignment aligns top baselines. Without it, minipages of different
heights are vertically centered relative to each other.

### Sub-figures

```latex
\begin{figure}[htbp]
  \begin{subfigure}[b]{0.48\textwidth}
    \centering
    \includegraphics[width=\linewidth]{fig_a.pdf}
    \caption{First.}
    \label{fig:sub-a}
  \end{subfigure}
  \hfill
  \begin{subfigure}[b]{0.48\textwidth}
    \centering
    \includegraphics[width=\linewidth]{fig_b.pdf}
    \caption{Second.}
    \label{fig:sub-b}
  \end{subfigure}
  \caption{Overall caption.}
  \label{fig:both}
\end{figure}
```

Requires the `subcaption` package. Each sub-figure gets its own `\caption` and
`\label`. The sum of widths plus spacing must not exceed `\textwidth`.

### Compact lists with enumitem

```latex
\usepackage[inline]{enumitem}

\begin{itemize}[nosep]              % remove all vertical spacing
\begin{enumerate}[noitemsep]        % remove only inter-item spacing
\begin{enumerate}[label=(\alph*)]   % custom labels: (a), (b), ...

% Inline list (flows within a paragraph)
The steps are \begin{enumerate*}[label=(\arabic*)]
  \item parse, \item transform, and \item emit.
\end{enumerate*}
```

### Page-level composition

Apply these only when polishing final page breaks — they are proofing-stage
tools, not structural ones.

```latex
\enlargethispage{\baselineskip}    % add one line to current page
\enlargethispage{-\baselineskip}   % remove one line

\pagebreak[3]       % strong suggestion to break here (scale: 0--4)
\nopagebreak[4]     % forbid break here

\needspace{4\baselineskip}         % if < 4 lines remain, force new page

\widowpenalty=300    % discourage single last line at top of new page
\clubpenalty=300     % discourage single first line at bottom of page
```

## Tables

### The booktabs philosophy

No vertical rules. Three horizontal rules of descending visual weight:
`\toprule` (thick), `\midrule` (medium), `\bottomrule` (thick).

```latex
\begin{tabular}{@{}lcc@{}}
  \toprule
  Method & Accuracy & Time \\
  \midrule
  Alpha  & 94.2\%   & 3.9s \\
  Beta   & 91.7\%   & 0.8s \\
  \addlinespace                      % subtle vertical gap between groups
  Gamma  & 88.1\%   & 0.3s \\
  \bottomrule
\end{tabular}
```

`@{}` strips outer column padding so rules align flush with the text block.
`\cmidrule(lr){2-4}` draws a partial rule spanning columns 2--4, trimmed on left
and right to prevent adjacent rules from visually merging. `\addlinespace`
separates row groups more subtly than a full `\midrule`.

### Column formatting

The `array` package provides `>{}` and `<{}` decorators that inject code before
and after every cell in a column:

```latex
\newcolumntype{L}{>{\raggedright\arraybackslash}X}   % for tabularx
\newcolumntype{R}{>{\raggedleft\arraybackslash}X}
```

`\arraybackslash` restores `\\` after alignment commands like `\raggedright`,
which redefine `\\` and would otherwise break the table's row-ending mechanism.

### Decimal alignment with siunitx

The `S` column type from `siunitx` aligns numbers at the decimal point.
Non-numeric headers must be wrapped in braces:

```latex
\begin{tabular}{l S[table-format=2.1] S[table-format=1.1e-1]}
  \toprule
  {Method} & {Time} & {Error} \\
  \midrule
  Alpha    & 3.9    & 1.3e-7 \\
  Gamma    & 14.1   & 5.2e-8 \\
  \bottomrule
\end{tabular}
```

### Table notes with threeparttable

`\footnote` does not work inside `tabular`. Use `threeparttable`, which provides
`\tnote` markers and a `tablenotes` environment whose width matches the table:

```latex
\begin{threeparttable}
  \caption{Results}
  \begin{tabular}{lcc}
    \toprule
    Method & Accuracy\tnote{a} \\
    \midrule
    Alpha  & 94.2\% \\
    \bottomrule
  \end{tabular}
  \begin{tablenotes}
    \item[a] Measured on test set B.
  \end{tablenotes}
\end{threeparttable}
```

### Overflow protection

`adjustbox` with `max width` scales content down only if it exceeds the target.
Content that fits is untouched:

```latex
\begin{adjustbox}{max width=\columnwidth}
  \begin{tabular}{...}
    ... potentially too-wide table ...
  \end{tabular}
\end{adjustbox}
```

## Code listings

### listings configuration

```latex
\lstdefinestyle{professional}{
  basicstyle=\ttfamily\footnotesize,
  keywordstyle=\color{kw}\bfseries,
  commentstyle=\color{fgdim}\itshape,
  stringstyle=\color{hd},
  numbers=left,
  numberstyle=\tiny\color{fgdim},
  numbersep=8pt,
  breaklines=true,
  columns=flexible,                    % proportional character spacing
  xleftmargin=\parindent,              % indent to match body text
  frame=single,
  rulecolor=\color{codepaneborder},
}
```

### Custom language definition

```latex
\lstdefinelanguage{Tiny}{
  morekeywords={def, let, match, if, else, fun, do, end,
                spawn, assert, retract, send, observe},
  sensitive=true,
  morecomment=[l]{\#},
  morestring=[b]",
  literate=
    {->}{{$\rightarrow$}}2
    {=>}{{$\Rightarrow$}}2,
}
```

### Inline code

`\verb|...|` preserves special characters but cannot appear inside macro
arguments (`\section`, `\footnote`, `\textbf`) — the catcode reassignment
conflicts with argument scanning. `\lstinline|...|` has the same limitation. Use
`\texttt{...}` when code must appear inside other commands. It works everywhere
but requires manual escaping of `\`, `{`, `}`, `#`, `$`, `%`, `&`, `_`.

### Escaping to LaTeX inside listings

The `escapeinside` option defines delimiters that switch from verbatim mode back
to LaTeX processing:

```latex
\lstset{escapeinside={(*@}{@*)}}

\begin{lstlisting}
def mean(xs):
    return sum(xs) / len(xs)  (*@$\leftarrow \frac{\sum x_i}{n}$@*)
\end{lstlisting}
```

### minted vs listings

`listings` requires no external dependencies and works with any LaTeX build
pipeline. `minted` delegates to Pygments for lexer-quality tokenization across
300+ languages but requires Python and `--shell-escape`. Use `listings` for
journal submissions (some forbid shell-escape). Use `minted` when you control
the build and want accurate highlighting with less configuration.

## Paragraph shaping

Tools for fixing bad line breaks, ordered from gentlest to most aggressive.

### \looseness

Requests that TeX set a paragraph N lines longer (positive) or shorter
(negative) than optimal:

```latex
{\looseness=-1 This paragraph will be set one line shorter than optimal,
if TeX can do so without exceeding tolerance.\par}
```

Must appear before `\par` (or blank line). Works best on paragraphs of 5+ lines.
TeX silently ignores the request if it cannot satisfy it within tolerance.
Resets to 0 after each paragraph — set it individually.

### \emergencystretch

Adds extra assumed stretchability to every line in a third pass of the paragraph
breaker:

```latex
\setlength{\emergencystretch}{1em}   % \sloppy uses 3em
```

Produces visibly loose lines rather than overfull boxes. Apply incrementally
(0.5em, then 1em) and inspect the result.

### \tolerance and \pretolerance

TeX breaks paragraphs in passes: first without hyphenation (badness threshold
`\pretolerance`, default 100), then with hyphenation (threshold `\tolerance`,
default 200), then with `\emergencystretch` if set. For a single problematic
paragraph:

```latex
\begin{sloppypar}
Problematic paragraph here.
\end{sloppypar}
```

`sloppypar` sets `\tolerance=9999` and `\emergencystretch=3em` within its scope.

### RaggedRight in narrow columns

Standard `\raggedright` disables hyphenation entirely, producing very ragged
margins. `\RaggedRight` from `ragged2e` preserves hyphenation while allowing a
ragged right edge:

```latex
\usepackage{ragged2e}
\begin{minipage}{0.4\textwidth}\RaggedRight
  Narrow text that still hyphenates when lines would otherwise be too short.
\end{minipage}
```

## Cross-referencing

### cleveref

`\cref` inspects the label's counter type and automatically formats the
reference name. It sorts, compresses, and groups multiple references:

```latex
\usepackage[capitalise,noabbrev,nameinlink]{cleveref}
% Load order: varioref (if used), hyperref, cleveref.

\cref{fig:a,fig:b,fig:c}    % "Figures 1 to 3"
\Cref{eq:main}               % "Equation 5" (capitalized for sentence start)
\crefrange{thm:a}{thm:c}    % "Theorems 1 to 3"
```

### Label placement

`\label` records the value of the most recently incremented counter. In a float,
the counter is incremented by `\caption`, so `\label` must come **after**
`\caption`. Placing `\label` before `\caption` silently records the section
counter instead of the figure counter — a silent, common bug.

Use prefixes to prevent collisions in large documents: `fig:`, `tab:`, `sec:`,
`eq:`, `thm:`, `lem:`, `def:`, `lst:`, `app:`.

### hyperref

```latex
\hypersetup{
  colorlinks = true,
  linkcolor  = {blue!70!black},
  citecolor  = {green!50!black},
  urlcolor   = {blue!80!black},
}
```

Section titles appear in PDF bookmarks, which cannot render math or special
commands. Use `\texorpdfstring` to provide a plain-text fallback:

```latex
\section{\texorpdfstring{$k$-means}{k-means} Clustering}
```

### Footnotes in floats

`\footnote` inside `figure` or `table` environments silently disappears or
misnumbers because the float is moved away from the footnote insertion point.
Three workarounds:

- `\footnotemark` inside the float, `\footnotetext` immediately after
- Wrap the table body in a `minipage` (footnotes appear at minipage bottom)
- Use `threeparttable` with `\tnote` (best for tables — see Tables section)

## Draft mode

```latex
\usepackage{showframe}      % draws margin, header, footer boundaries
\usepackage{showlabels}     % renders \label names in the margin
\usepackage[obeyDraft]{todonotes}
\todo{Fix this argument}
\missingfigure{Add results plot}
\listoftodos                % generates hyperlinked TODO index
```

`\overfullrule=10mm` draws black bars in the margin next to every overfull hbox
— essential for catching lines that extend past the text block before
submission.

## Performance

### Speed killers

| Problem                | Fix                                                 |
| ---------------------- | --------------------------------------------------- |
| Complex TikZ diagrams  | Externalize (see below)                             |
| Large/hi-res images    | Downsize to 300 DPI; JPEG for photographs           |
| Unused packages        | Audit `\usepackage` calls; each one costs load time |
| Monolithic compilation | `\include`/`\includeonly` to compile one chapter    |
| Full interaction mode  | `pdflatex -interaction=batchmode`                   |

### tikz externalization

Each tikzpicture compiles once into a standalone PDF. Subsequent builds skip
recompilation and `\includegraphics` the cached result:

```latex
\usetikzlibrary{external}
\tikzexternalize[prefix=figures-ext/]
% Compile with: pdflatex -shell-escape main.tex
```

For parallel figure compilation:

```latex
\tikzexternalize[mode=list and make]
% Then: pdflatex main && make -j$(nproc) -f main.makefile && pdflatex main
```

### latexmk

Automates multi-pass compilation (bibtex, cross-references, index). Watches
files and recompiles on change with `-pvc`:

```perl
# .latexmkrc
$pdf_mode = 1;
$pdflatex = 'pdflatex -shell-escape -synctex=1 -interaction=nonstopmode %O %S';
@default_files = ('main.tex');
```

## The dark arts

### \NewDocumentCommand

Replaces `\newcommand` with richer argument specifications: star variants,
multiple optional arguments, and `-NoValue-` detection for distinguishing
"omitted" from "empty."

```latex
\NewDocumentCommand{\heading}{s O{} m}{%
  \IfBooleanTF{#1}
    {\section*{#3}}           % \heading*{Title}: unnumbered
    {\section[#2]{#3}}        % \heading[Short]{Title}: optional short form
}
```

All commands defined this way are automatically `\protected` — they survive
`\edef` and `\write` without `\protect`.

### etoolbox: surgical command modification

Modify a single fragment of an existing command without rewriting the entire
definition:

```latex
\patchcmd{\cmd}{search}{replace}{success}{failure}
\pretocmd{\cmd}{code to prepend}{success}{failure}
\apptocmd{\cmd}{code to append}{success}{failure}
```

`\patchcmd` replaces the first occurrence of `search` in `\cmd`'s body with
`replace`. For commands defined with `\DeclareRobustCommand` (which wraps the
body in a `\protect` layer), use `xpatch` instead.

### Expandability

`\edef` and `\write` force full expansion of their argument. Many LaTeX commands
produce invalid tokens when fully expanded — this is the **fragile command**
problem. Protection mechanisms:

```latex
\edef\foo{\noexpand\textbf{hello}}           % prevent expansion of one token
\edef\foo{\unexpanded{\textbf{some text}}}   % prevent expansion of a group
```

`\NewDocumentCommand` produces `\protected` definitions that are immune to
forced expansion. This is the modern solution — if all your commands use
`\NewDocumentCommand`, fragility ceases to be a concern.

### Lengths and dimensions

`em` and `ex` scale with the current font (use for spacing that should track
font size). `pt`, `mm`, `cm` are fixed physical measurements (use for page
layout). TeX's `pt` (1/72.27 in) differs from PostScript/PDF's `bp` (1/72 in) —
use `bp` when interfacing with external tools.

Arithmetic with `\dimexpr` requires the dimension to precede any multiplier:

```latex
\the\dimexpr\textwidth - 2cm\relax        % subtraction
\the\dimexpr 1pt * 10\relax               % correct: dimension * number
% INVALID: \the\dimexpr 10 * 1pt\relax    % number * dimension fails
```

Multiplying a rubber length by a number discards the stretch/shrink components,
producing a rigid length.

### xcolor expressions

The `!` operator blends colors by percentage. The second color defaults to white
if omitted:

```latex
\color{blue!40!red}        % 40% blue, 60% red
\color{red!30}             % 30% red, 70% white (implicit)
\colorlet{dim}{black!40}   % named 40% gray
```

### Hook system (LaTeX 2020+)

Generic hooks for environments and commands require no prior declaration — they
exist implicitly for every environment and command:

```latex
\AddToHook{env/theorem/before}{...}    % before \begin{theorem}
\AddToHook{cmd/section/after}{...}     % after \section executes
\AddToHook{shipout/foreground}{...}    % drawn atop every shipped page
```

## Common mistakes

- **`\left`/`\right` everywhere.** Produces Inner atoms with wrong spacing after
  operators. Use manual sizing (`\bigl`/`\bigr`) or `\DeclarePairedDelimiter`.
- **`\label` before `\caption`.** Records the section counter instead of the
  figure counter. Always place `\label` after `\caption`.
- **Loading `geometry` in acmart.** ACM prohibits margin changes. TAPS will
  reject the submission.
- **`\verb` inside macro arguments.** Catcode conflict — the argument is
  tokenized before `\verb` can reassign catcodes. Use `\texttt` or the
  `cprotect` package.
- **Missing `~` before `\ref`.** Permits a line break between "Figure" and "3".
  Use `Figure~\ref{fig:x}` or `\cref` (which handles this automatically).
- **`\mathrm{for all}` in math.** Spaces are ignored inside `\mathrm`, producing
  "forall". Use `\text{for all}`.
- **`[H]` float placement.** Disables the page-breaking algorithm. Fix the float
  constraints instead (relax fractions, add `\FloatBarrier`, reposition the
  float in source).
- **`\parskip > 0` with paragraph indentation.** Choose one signaling method for
  new paragraphs: indentation or vertical space, not both.

## References

- Donald Knuth, _The TeXbook_ (Addison-Wesley, 1984) — the definitive TeX
  reference. Chapters 17--18 on math spacing atoms, Chapter 14 on line breaking,
  Appendix G on the mathematical spacing table
- Leslie Lamport, _LaTeX: A Document Preparation System_ (Addison-Wesley, 1994)
  — the original LaTeX manual, still the clearest explanation of floats, cross-
  references, and document structure
- Frank Mittelbach & Michel Goossens, _The LaTeX Companion_ (Addison-Wesley, 3rd
  ed., 2023) — comprehensive coverage of packages and internals. The
  authoritative reference for `amsmath`, `mathtools`, `booktabs`, `hyperref`,
  `cleveref`, and hundreds of others
- Robert Bringhurst, _The Elements of Typographic Style_ (Hartley & Marks, 4th
  ed., 2012) — the typographic principles behind microtypography, spacing, and
  page composition. Why protrusion works, why vertical rules harm tables, why
  small caps need tracking
- [The `microtype` package documentation](https://ctan.org/pkg/microtype) —
  Robert Schlicht. Protrusion, expansion, and tracking configuration. The
  `stretch=10` recommendation comes from Siarhei Khirevich's
  [thesis typesetting guide](https://www.khirevich.com/latex/microtype/)
- [The `mathtools` package documentation](https://ctan.org/pkg/mathtools) —
  Morten Hogholm & Lars Madsen. `\DeclarePairedDelimiter`, `\mathclap`,
  `\smashoperator`, `\adjustlimits`, `dcases`, `showonlyrefs`
- [The `booktabs` package documentation](https://ctan.org/pkg/booktabs) — Simon
  Fear. The "no vertical rules" philosophy and the design rationale behind
  `\toprule`/`\midrule`/`\bottomrule`
- Nick Higham,
  [Better LaTeX Tables with Booktabs](https://nhigham.com/2019/11/19/better-latex-tables-with-booktabs/)
  — practical application of the booktabs philosophy with before/after examples
- Christian Feuersanger,
  [Notes on Programming in TeX](https://pgfplots.sourceforge.net/TeX-programming-notes.pdf)
  — the best explanation of TeX's expansion mechanism, catcodes, and
  `\expandafter` chains. Written by the pgfplots author
- Martin J. Osborne,
  [Notes on Page Makeup Using LaTeX](https://www.economics.utoronto.ca/osborne/latex/PMAKEUP.HTM)
  — the expert workflow for final page composition: `\looseness`,
  `\enlargethispage`, widow/orphan control
- Rob J. Hyndman,
  [Controlling Figure and Table Placement in LaTeX](https://robjhyndman.com/hyndsight/latex-floats/)
  — clear explanation of the float queue, specifier semantics, and why floats
  pile up
- Joseph Wright,
  [From `\newcommand` to `\NewDocumentCommand`](https://www.texdev.net/2010/05/23/from-newcommand-to-newdocumentcommand/)
  — the rationale for `xparse`/LaTeX3 command definition and why it supersedes
  `\newcommand`
