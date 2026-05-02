---
description: "Modifying .tex files (non-TikZ content)"
---

# LaTeX

Publication-quality documents outside TikZ (see the tikz skill for graphics).

## The mental model

TeX runs in four stages: assign catcodes, tokenize, expand, execute. Catcodes
are assigned at tokenization, before expansion — which is why `\verb` breaks
inside macro arguments (the argument is already tokenized) and why
`\makeatletter` must precede `@`-commands. Every TeX bug traces back to this
pipeline.

## Microtypography

### microtype

```latex
\usepackage[
  activate={true,nocompatibility},
  final,
  tracking=true,
  factor=1100,       % 10% more protrusion than default
  stretch=10,        % default 20 causes rasterization blur
  shrink=10
]{microtype}
```

Three refinements: protrusion (small chars overhang the margin), font expansion
(±2% width to relieve the line-breaker), tracking (letterspacing for small
caps). Reduce stretch/shrink from 20 to 10 to eliminate visible blurring.

Protrusion misaligns ToC page numbers. Disable locally:

```latex
\microtypesetup{protrusion=false}
\tableofcontents
\microtypesetup{protrusion=true}
```

Small caps need tracking: `\SetTracking{encoding={*}, shape=sc}{40}` (0.04em).

`acmart` already loads microtype — use `\microtypesetup{...}` to customize, do
not reload.

### Sentence spacing

TeX inserts extra space after `.`, `!`, `?`, but suppresses it when a capital
precedes the period (assuming abbreviation). Two corrections:

```latex
He had a PhD\@.  Next sentence.    % \@ resets capital suppression
It was David vs.\ Goliath.         % \  forces non-sentence space
```

Common cases needing `\ `: `e.g.\ `, `i.e.\ `, `et al.\ `, `Fig.\ `. Use `~`
for the same effect plus no line break: `Fig.~\ref{fig:x}`. `\frenchspacing`
disables sentence spacing entirely.

### Math spacing

TeX classifies math elements into eight atom types and spaces them by a fixed
table.

| Command  | Width    | Use                                      |
| -------- | -------- | ---------------------------------------- |
| `\!`     | -3mu     | Tighten double integrals: `\int\!\!\int` |
| `\,`     | 3mu      | Before differentials: `f(x)\,dx`         |
| `\:`     | 4mu      | Between related terms                    |
| `\;`     | 5mu      | Set-builder bar: `\{x \;\mid\; x > 0\}`  |
| `\quad`  | 18mu     | Major separation                         |
| `\qquad` | 36mu     | Equation and condition                   |

Override atom class with `\mathbin{#}`, `\mathrel{#}`, `\mathord{#}` when the
default is wrong.

### Vertical spacing

Never use `\vskip` in LaTeX — it ends the paragraph mid-stream. Use `\vspace`.
Rubber lengths absorb page-break pressure:

```latex
\vspace{12pt plus 3pt minus 2pt}
\vspace{0pt plus 1fill}            % infinitely stretchable

\setlength{\abovedisplayskip}{6pt plus 2pt minus 4pt}
\setlength{\belowdisplayskip}{6pt plus 2pt minus 4pt}
```

### The phantom family

- `\phantom{X}` — invisible box with X's full dimensions
- `\hphantom{X}` — width only
- `\vphantom{X}` — height and depth only

```latex
\begin{cases}
  \phantom{-}1 & \text{if } x > 0 \\
            -1  & \text{if } x < 0
\end{cases}

\left( \vphantom{\frac{a}{b}} x + y \right) = \left( \frac{a}{b} \right)
```

`\smash{X}` is the inverse — full-size output, zero reported height/depth.
`\smash[t]{X}`/`\smash[b]{X}` zero only one side.

## Math typesetting

### Delimiters: avoid \left/\right

`\left`/`\right` produce Inner atoms, which insert a thin space after operators
like `\sin`. Manual sizing produces the right Open/Close atoms:

```latex
$\sin\left(\frac{x}{2}\right)$    % BAD: spurious space after \sin
$\sin\bigl(\frac{x}{2}\bigr)$     % GOOD
```

Sizes: `\bigl/r` (1.2x), `\Bigl/r` (1.8x), `\biggl/r` (2.4x), `\Biggl/r`
(3.0x). Or define semantic delimiters with `mathtools`:

```latex
\DeclarePairedDelimiter{\abs}{\lvert}{\rvert}
\DeclarePairedDelimiter{\norm}{\lVert}{\rVert}
\DeclarePairedDelimiter{\ceil}{\lceil}{\rceil}
\DeclarePairedDelimiter{\floor}{\lfloor}{\rfloor}

\abs{x}                    % default size
\abs*{\frac{a}{b}}         % auto-sized via \left/\right
\abs[\Big]{\frac{a}{b}}    % explicit override
```

### Semantic operators

```latex
\DeclareMathOperator{\tr}{tr}
\DeclareMathOperator*{\argmax}{arg\,max}   % * places limits below in display
$\argmax_{x \in S} f(x)$
```

For one-offs: `\operatorname{Spec}(R)`. The `\mathrm{tr}(A)` form gives wrong
spacing (Ordinary atom, no thin space before `(`); `\text{tr}` inherits the
body font.

### \text vs \mathrm vs \operatorname

| Command              | Spaces? | Atom class | Use for                                |
| -------------------- | ------- | ---------- | -------------------------------------- |
| `\text{...}`         | yes     | Ordinary   | Words in math: "for all"               |
| `\mathrm{...}`       | no      | Ordinary   | Upright constants: `\mathrm{e}`, `\d`  |
| `\operatorname{...}` | no      | Operator   | Named functions: `\operatorname{Gal}`  |

`\mathrm{for all}` collapses to "forall". Use `\text` for multi-word phrases.

### Punctuation atoms

| Notation   | Atom class  | Use                                |
| ---------- | ----------- | ---------------------------------- |
| `:`        | Relation    | Set-builder: `\{x : x > 0\}`       |
| `\colon`   | Punctuation | Function typing: `f\colon A \to B` |
| `\mid`     | Relation    | Conditional: `P(A \mid B)`         |
| `\lvert`   | Open        | Absolute value: `\lvert x \rvert`  |

### Multi-line equations

| Environment | Alignment  | Numbering  | Nesting           |
| ----------- | ---------- | ---------- | ----------------- |
| `align`     | At `&`     | Each line  | Standalone        |
| `aligned`   | At `&`     | —          | Inside `equation` |
| `gather`    | Centered   | Each line  | Standalone        |
| `multline`  | Left/right | One number | Standalone        |
| `split`     | At `&`     | —          | Inside `equation` |

`\intertext{...}` (amsmath) inserts a paragraph between aligned lines.
`\shortintertext{...}` (mathtools) is tighter.

### mathtools utilities

```latex
\sum_{\mathclap{1 \le i \le j \le n}} x_{ij}      % zero-width centered
X + \smashoperator{\sum_{1 \le i \le j \le n}} x_{ij} + Y
\adjustlimits\lim_{n\to\infty} \sup_{x\in A} f_n(x)

\mathtoolsset{showonlyrefs, showmanualtags}       % suppress unreferenced numbers

f(x) = \begin{dcases}                              % \displaystyle in left col
  \frac{1}{x} & \text{if } x \ne 0 \\
  0           & \text{if } x = 0
\end{dcases}
```

### Dots

`\dots` (amsmath) inspects the next token and chooses baseline or centered. When
ambiguous, use the semantic variants: `\dotsc` (commas), `\dotsb` (operators),
`\dotsi` (integrals).

### Commutative diagrams

```latex
\begin{tikzcd}
  A \arrow[r, "f"] \arrow[d, "g"'] & B \arrow[d, "h"] \\
  C \arrow[r, "k"]                 & D
\end{tikzcd}
```

Direction is composable letters (`r`, `l`, `u`, `d`, `rd`). Labels default to
the right; `'` flips them. Visual editors: q.uiver.app, tikzcd.yichuanshen.de.

## Layout and composition

### Float placement

`[htbp!]` are *permissions*, not commands. Default is `[tbp]` (no `h`). One
oversized float jams the FIFO queue and pushes everything to the document end.

```latex
\renewcommand{\topfraction}{0.85}
\renewcommand{\bottomfraction}{0.85}
\renewcommand{\textfraction}{0.15}
\renewcommand{\floatpagefraction}{0.7}
```

`\FloatBarrier` (placeins) flushes pending floats. `\usepackage[section]{placeins}`
auto-barriers each section. Avoid `[H]` — it disables page-breaking entirely.

For acmart `figure*`: `[t]`/`[p]` only by default; add `dblfloatfix` for `[b]`.

### Width lengths

| Length         | Measures             | Varies with                    |
| -------------- | -------------------- | ------------------------------ |
| `\textwidth`   | Full text area       | Page layout only               |
| `\columnwidth` | Current column       | One- vs two-column mode        |
| `\linewidth`   | Current line         | Lists, minipages, any nesting  |

Use `\linewidth` by default. Inside `figure*` (spans columns), use `\textwidth`.

### Side-by-side

```latex
\begin{minipage}[t]{0.48\textwidth}
  Left
\end{minipage}%              % % prevents space from line break
\hfill
\begin{minipage}[t]{0.48\textwidth}
  Right
\end{minipage}
```

`[t]` aligns top baselines. Without it, mismatched heights center vertically.

### Sub-figures

```latex
\begin{figure}[htbp]
  \begin{subfigure}[b]{0.48\textwidth}
    \centering
    \includegraphics[width=\linewidth]{fig_a.pdf}
    \caption{First.}\label{fig:sub-a}
  \end{subfigure}\hfill
  \begin{subfigure}[b]{0.48\textwidth}
    \centering
    \includegraphics[width=\linewidth]{fig_b.pdf}
    \caption{Second.}\label{fig:sub-b}
  \end{subfigure}
  \caption{Overall.}\label{fig:both}
\end{figure}
```

Requires `subcaption`. Each sub-figure gets its own `\caption` and `\label`.

### Compact lists

```latex
\usepackage[inline]{enumitem}

\begin{itemize}[nosep]              % no vertical spacing
\begin{enumerate}[noitemsep]        % no inter-item spacing
\begin{enumerate}[label=(\alph*)]   % custom labels

The steps are \begin{enumerate*}[label=(\arabic*)]
  \item parse, \item transform, \item emit.
\end{enumerate*}
```

### Page-level (proofing only)

```latex
\enlargethispage{\baselineskip}    % grow current page by one line
\pagebreak[3]                       % strong suggestion (0–4)
\nopagebreak[4]                     % forbid break
\needspace{4\baselineskip}          % force page if <4 lines remain
\widowpenalty=300
\clubpenalty=300
```

## Tables

### booktabs

No vertical rules. Three horizontal weights:

```latex
\begin{tabular}{@{}lcc@{}}
  \toprule
  Method & Accuracy & Time \\
  \midrule
  Alpha  & 94.2\%   & 3.9s \\
  Beta   & 91.7\%   & 0.8s \\
  \addlinespace                      % subtle group separator
  Gamma  & 88.1\%   & 0.3s \\
  \bottomrule
\end{tabular}
```

`@{}` strips outer column padding. `\cmidrule(lr){2-4}` draws a partial rule
trimmed on both sides.

### Column formatting

```latex
\newcolumntype{L}{>{\raggedright\arraybackslash}X}
\newcolumntype{R}{>{\raggedleft\arraybackslash}X}
```

`\arraybackslash` restores `\\` after `\raggedright` redefines it.

### Decimal alignment

```latex
\begin{tabular}{l S[table-format=2.1] S[table-format=1.1e-1]}
  \toprule
  {Method} & {Time} & {Error} \\         % brace non-numeric headers
  \midrule
  Alpha    & 3.9    & 1.3e-7 \\
  \bottomrule
\end{tabular}
```

### Table notes

`\footnote` does not work inside `tabular`. Use `threeparttable`:

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

### Overflow

```latex
\begin{adjustbox}{max width=\columnwidth}
  \begin{tabular}{...} ... \end{tabular}
\end{adjustbox}
```

`max width` shrinks only when needed.

## Code listings

```latex
\lstdefinestyle{professional}{
  basicstyle=\ttfamily\footnotesize,
  keywordstyle=\color{kw}\bfseries,
  commentstyle=\color{fgdim}\itshape,
  stringstyle=\color{hd},
  numbers=left, numberstyle=\tiny\color{fgdim},
  numbersep=8pt,
  breaklines=true, columns=flexible,
  xleftmargin=\parindent,
  frame=single, rulecolor=\color{codepaneborder},
}

\lstdefinelanguage{Tiny}{
  morekeywords={def, let, match, if, else, fun, do, end, spawn, assert, retract},
  sensitive=true,
  morecomment=[l]{\#},
  morestring=[b]",
  literate={->}{{$\rightarrow$}}2 {=>}{{$\Rightarrow$}}2,
}
```

`\verb|...|` and `\lstinline|...|` cannot appear inside macro arguments
(catcode conflict). Use `\texttt{...}` with manual escaping there.

`escapeinside` switches back to LaTeX mid-listing:

```latex
\lstset{escapeinside={(*@}{@*)}}

\begin{lstlisting}
def mean(xs):
    return sum(xs) / len(xs)  (*@$\leftarrow \frac{\sum x_i}{n}$@*)
\end{lstlisting}
```

`listings` needs no shell-escape (use for journal submissions). `minted` needs
Python + `--shell-escape` but produces better tokenization for 300+ languages.

## Paragraph shaping

Gentlest to most aggressive:

```latex
{\looseness=-1 ... \par}                       % set N lines shorter/longer
\setlength{\emergencystretch}{1em}             % third pass; \sloppy uses 3em
\begin{sloppypar} ... \end{sloppypar}          % \tolerance=9999, stretch=3em
```

Standard `\raggedright` disables hyphenation. `\RaggedRight` from `ragged2e`
preserves it for narrow columns.

## Cross-referencing

### cleveref

```latex
\usepackage[capitalise,noabbrev,nameinlink]{cleveref}
% Load order: varioref, hyperref, cleveref.

\cref{fig:a,fig:b,fig:c}    % "Figures 1 to 3"
\Cref{eq:main}               % capitalized for sentence start
\crefrange{thm:a}{thm:c}    % "Theorems 1 to 3"
```

### Label placement

`\label` records the most recently incremented counter. In a float, the counter
increments at `\caption`, so `\label` must come **after** `\caption`. Reversing
them silently records the section counter instead.

Prefix labels: `fig:`, `tab:`, `sec:`, `eq:`, `thm:`, `lem:`, `def:`, `lst:`.

### hyperref

```latex
\hypersetup{
  colorlinks = true,
  linkcolor  = {blue!70!black},
  citecolor  = {green!50!black},
  urlcolor   = {blue!80!black},
}

\section{\texorpdfstring{$k$-means}{k-means} Clustering}   % bookmarks fallback
```

### Footnotes in floats

`\footnote` silently disappears or misnumbers inside `figure`/`table`. Use
`\footnotemark` inside, `\footnotetext` after; or `threeparttable` for tables.

## Draft mode

```latex
\usepackage{showframe}      % margin/header/footer boundaries
\usepackage{showlabels}     % \label names in margin
\usepackage[obeyDraft]{todonotes}
\todo{Fix this argument}
\missingfigure{Add results plot}
\listoftodos
\overfullrule=10mm                       % black bars next to overfull boxes
```

## Performance

| Problem                | Fix                                                 |
| ---------------------- | --------------------------------------------------- |
| Complex TikZ           | `\tikzexternalize[prefix=figures-ext/]`             |
| Large images           | Downsize to 300 DPI; JPEG for photos                |
| Unused packages        | Audit `\usepackage` — each costs load time          |
| Monolithic compilation | `\include`/`\includeonly` per chapter               |
| Full interaction       | `pdflatex -interaction=batchmode`                   |

For parallel TikZ compilation:

```latex
\tikzexternalize[mode=list and make]
% pdflatex main && make -j$(nproc) -f main.makefile && pdflatex main
```

`latexmk` automates multi-pass; watches with `-pvc`:

```perl
# .latexmkrc
$pdf_mode = 1;
$pdflatex = 'pdflatex -shell-escape -synctex=1 -interaction=nonstopmode %O %S';
@default_files = ('main.tex');
```

## The dark arts

### \NewDocumentCommand

Replaces `\newcommand` with star variants, multiple optionals, and `-NoValue-`
detection. All commands so defined are `\protected` (survive `\edef`/`\write`).

```latex
\NewDocumentCommand{\heading}{s O{} m}{%
  \IfBooleanTF{#1}
    {\section*{#3}}            % \heading*{Title}: unnumbered
    {\section[#2]{#3}}         % \heading[Short]{Title}: optional short form
}
```

### etoolbox

Modify a fragment of an existing command without rewriting it:

```latex
\patchcmd{\cmd}{search}{replace}{success}{failure}
\pretocmd{\cmd}{code to prepend}{success}{failure}
\apptocmd{\cmd}{code to append}{success}{failure}
```

For `\DeclareRobustCommand` definitions, use `xpatch`.

### Lengths

`em`/`ex` scale with font; `pt`/`mm`/`cm` are fixed. TeX `pt` = 1/72.27 in;
PostScript `bp` = 1/72 in — use `bp` when interfacing with external tools.

```latex
\the\dimexpr\textwidth - 2cm\relax
\the\dimexpr 1pt * 10\relax       % dimension * number; reverse fails
```

### xcolor

```latex
\color{blue!40!red}        % 40% blue, 60% red
\color{red!30}             % 30% red, 70% white (implicit)
\colorlet{dim}{black!40}
```

### Hooks (LaTeX 2020+)

```latex
\AddToHook{env/theorem/before}{...}
\AddToHook{cmd/section/after}{...}
\AddToHook{shipout/foreground}{...}
```

## References

- Knuth, _The TeXbook_ (1984) — Chs 17–18 (math atoms), Ch 14 (line breaking),
  App G (math spacing table)
- Lamport, _LaTeX: A Document Preparation System_ (1994) — original manual
- Mittelbach & Goossens, _The LaTeX Companion_ (3rd ed., 2023) — authoritative
  package reference
- Bringhurst, _The Elements of Typographic Style_ (4th ed., 2012) — typographic
  principles behind microtype, spacing, page composition
- [microtype docs](https://ctan.org/pkg/microtype) — Schlicht; `stretch=10`
  comes from [Khirevich's guide](https://www.khirevich.com/latex/microtype/)
- [mathtools docs](https://ctan.org/pkg/mathtools) — `\DeclarePairedDelimiter`,
  `\mathclap`, `\smashoperator`, `\adjustlimits`, `dcases`, `showonlyrefs`
- [booktabs docs](https://ctan.org/pkg/booktabs) — Fear; the no-vertical-rules
  philosophy
- Higham,
  [Better LaTeX Tables with Booktabs](https://nhigham.com/2019/11/19/better-latex-tables-with-booktabs/)
- Feuersanger,
  [Notes on Programming in TeX](https://pgfplots.sourceforge.net/TeX-programming-notes.pdf)
  — expansion, catcodes, `\expandafter` chains
- Osborne,
  [Notes on Page Makeup Using LaTeX](https://www.economics.utoronto.ca/osborne/latex/PMAKEUP.HTM)
  — `\looseness`, `\enlargethispage`, widow/orphan control
- Hyndman,
  [Controlling Figure and Table Placement](https://robjhyndman.com/hyndsight/latex-floats/)
  — float queue and specifier semantics
- Wright,
  [From `\newcommand` to `\NewDocumentCommand`](https://www.texdev.net/2010/05/23/from-newcommand-to-newdocumentcommand/)
