# snacks

Dotfiles and agent configuration for Pop!_OS 24.04 (COSMIC) and macOS, managed
by [yadm](https://yadm.io).

```bash
yadm clone git@github.com:femtomc/snacks.git
yadm bootstrap
```

## What's here

**Shell** — zsh with oh-my-zsh, vi mode, and emacs insert-mode bindings.
Modern replacements aliased in: `eza`, `bat`, `fzf`, `zoxide`. Starship
prompt. Tool paths (conda, mise, bun, go, CUDA, fly.io) are guarded so they
activate only on machines where they exist.

**Desktop** — COSMIC compositor with per-workspace autotiling, gruvbox-inspired
dark theme, and custom keyboard shortcuts. keyd remaps Super to act as a pure
Command modifier for Mac-style app shortcuts (Super+C/V/Z/S/A/T/W/Q/F send
Ctrl equivalents), while Super+Arrow/Number pass through to COSMIC for tiling
and workspaces. Launcher bound to Ctrl+Space.

**Terminal** — Ghostty (primary) and Kitty. Gruvbox-material theme, TX-02 font,
translucent background.

**Multiplexers** — tmux (Ctrl-A prefix, vi-mode copy, 50K scrollback, sixel
passthrough, tmux-resurrect) and Zellij (same prefix, gruvbox theme, zjstatus
bar, autolock/forgot/room plugins, dev layout).

**Editors** — Neovim via LazyVim (gruvbox, Lean 4, oil.nvim, typst preview),
Zed (vim mode, PragmataPro, ruff), VS Code (vim mode, TX-02, neovim backend).

**Git** — delta for side-by-side diffs, `gh auth` credential helper, diff3
merge conflicts, global gitignore.

**Agent skills** — 13 skill files in `~/.config/skills/` symlinked into both
`~/.claude/skills/` and `~/.codex/skills/`. Covers writing, commits, testing,
Zig, Python, Lean, LaTeX, TikZ, diagrams, flexibility, references, bellman
(work-graph orchestrator), and smg (semantic architecture graph).

**Agent configs** — `CLAUDE.md` + `settings.json` for Claude Code, `AGENTS.md`
+ `config.toml` for Codex. Both reference the shared skill symlinks.

**Secrets** — `.secrets` encrypted via `yadm encrypt` with a GPG key and stored
as `.local/share/yadm/archive`. Run `yadm decrypt` after cloning.

## Bootstrap

`yadm bootstrap` is idempotent — each tool is skipped if already installed. On
Linux it uses apt; on macOS, Homebrew.

| Method | Tools |
|--------|-------|
| apt / brew | git, curl, wget, build-essential, cmake, jq, zsh, tmux, kitty, python3, gh |
| cargo | eza, bat, delta, fd, rg, zoxide, bob-nvim |
| bob | nvim |
| git clone | fzf, oh-my-zsh, zsh-autosuggestions, zsh-syntax-highlighting, TPM |
| curl | rustup, starship, mise, uv, bun, flyctl, Claude Code |
| npm | Codex |
| uv tool | bellman, smg |
| GitHub release | lazygit, act |
| mise install | node 22, elixir 1.17, erlang 27 |
| keyd (Linux) | Mac-style Super→Ctrl modifier, installed to /etc/keyd/ |

## New machine

```bash
# 1. Install yadm
sudo apt install yadm        # or: brew install yadm

# 2. Clone and bootstrap
yadm clone git@github.com:femtomc/snacks.git
yadm bootstrap

# 3. Import GPG key and decrypt secrets
gpg --import /path/to/gpg-snacks.key
yadm decrypt

# 4. Authenticate
gh auth login
```

## Updating

```bash
yadm add -u && yadm commit   # stage tracked changes
yadm push                    # sync
```

A pre-commit hook runs automatically on each commit: shellcheck on scripts,
stylua on Lua, jq/tomllib on JSON/TOML, a secrets scan, and a check for
hardcoded home paths.

## Layout

```
~
├── .zshrc, .bashrc, .zshenv, .zprofile   shell
├── .tmux.conf                            tmux
├── .gitconfig, .condarc, .ssh/config     git, conda, ssh hosts
├── .config/
│   ├── cosmic/                           COSMIC desktop
│   │   ├── CosmicComp/                     autotile, xkb
│   │   ├── CosmicSettings.Shortcuts/       custom keybindings
│   │   ├── CosmicTheme.Dark/               gruvbox palette
│   │   ├── CosmicTk/                       fonts (Inter, TX-02)
│   │   └── CosmicPanel.{Panel,Dock}/       panel + dock layout
│   ├── keyd/default.conf                 Mac-style Super→Ctrl
│   ├── ghostty/config                    terminal (primary)
│   ├── kitty/kitty.conf                  terminal
│   ├── nvim/                             Neovim (LazyVim)
│   ├── zed/settings.json                 Zed
│   ├── Code/User/                        VS Code
│   ├── zellij/                           Zellij + layouts
│   ├── starship.toml                     prompt
│   ├── ranger/                           file manager
│   ├── btop/btop.conf                    system monitor
│   ├── glow/glow.yml                     markdown viewer
│   ├── git/ignore                        global gitignore
│   ├── mise/config.toml                  version manager pins
│   ├── mimeapps.list                     default applications
│   ├── wallpaper/platform.jpg            shared wallpaper
│   ├── skills/                           agent skills (canonical)
│   │   ├── bellman/SKILL.md
│   │   ├── writing/SKILL.md
│   │   └── ... (13 total)
│   └── yadm/
│       ├── bootstrap                     setup script
│       ├── encrypt                       files to encrypt
│       └── hooks/pre-commit              commit checks
├── .claude/
│   ├── CLAUDE.md                         agent instructions
│   ├── settings.json                     agent config
│   ├── statusline.sh                     status bar script
│   └── skills/ → ~/.config/skills/*      symlinks
├── .codex/
│   ├── AGENTS.md                         agent instructions
│   ├── config.toml                       agent config
│   └── skills/ → ~/.config/skills/*      symlinks
├── .local/share/
│   ├── yadm/archive                      encrypted secrets
│   └── applications/                     desktop entries
└── README.md
```
