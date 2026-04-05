# snacks

Dotfiles and agent configuration, managed by [yadm](https://yadm.io). One
command to clone, one command to bootstrap a fresh machine.

```bash
yadm clone git@github.com:femtomc/snacks.git
yadm bootstrap
```

## What's here

**Shell** — zsh with oh-my-zsh, vi mode, and emacs insert-mode bindings.
Aliases swap in modern replacements: `eza` for ls, `bat` for cat, `fzf` for
fuzzy search, `zoxide` for cd. Starship prompt. Conda, mise, bun, go, CUDA,
and fly.io paths are configured with existence guards so nothing breaks on
machines that lack them.

**Terminal** — Ghostty (primary) and Kitty configs. Gruvbox-material theme,
TX-02 font, translucent background.

**Tmux** — Ctrl-A prefix, vi-mode copy, 50K scrollback, sixel passthrough,
tmux-resurrect for session persistence. TPM for plugin management.

**Editor** — Neovim via LazyVim. Gruvbox colorscheme, Lean 4 support, oil.nvim
file browser, img-clip for pasting images, typst preview.

**Git** — Delta for side-by-side diffs, `gh auth` credential helper, diff3
merge conflicts.

**Agent skills** — 13 shared skill files live in `~/.config/skills/` and are
symlinked into both `~/.claude/skills/` and `~/.codex/skills/`. One edit
propagates to both tools. Skills cover writing, commits, testing, Zig, Python,
Lean, LaTeX, TikZ, diagrams, flexibility, references, bellman, and smg.

**Agent configs** — `CLAUDE.md` and `settings.json` for Claude Code,
`AGENTS.md` and `config.toml` for Codex. Both reference the shared skill
symlinks.

**Secrets** — `.secrets` (API keys, tokens) is encrypted via `yadm encrypt`
with a GPG key and stored as `.local/share/yadm/archive`. Run `yadm decrypt`
after cloning on a new machine.

## Bootstrap

`yadm bootstrap` is idempotent — it skips anything already installed. It
installs:

| Method | Tools |
|--------|-------|
| apt | git, curl, wget, build-essential, cmake, jq, zsh, tmux, kitty, python3 |
| apt repo | gh (GitHub CLI) |
| cargo | eza, bat, delta, fd, rg, zoxide, bob-nvim |
| bob | nvim |
| git clone | fzf, oh-my-zsh, zsh-autosuggestions, zsh-syntax-highlighting, TPM |
| curl | rustup, starship, mise, uv, bun, flyctl, Claude Code |
| npm | Codex |
| uv tool | bellman, smg |
| GitHub release | lazygit, act |
| mise install | node 22 (→ npx), elixir 1.17, erlang 27 |

After bootstrap completes, restart the shell (`exec zsh`) or open a new
terminal.

## New machine checklist

```bash
# 1. Install yadm
sudo apt install yadm        # or: brew install yadm

# 2. Clone and bootstrap
yadm clone git@github.com:femtomc/snacks.git
yadm bootstrap

# 3. Import GPG key (for decrypting secrets)
gpg --import /path/to/gpg-snacks.key
yadm decrypt

# 4. Authenticate tools
gh auth login
# Set ANTHROPIC_API_KEY and OPENAI_API_KEY in ~/.secrets
```

## Updating

```bash
yadm add -u && yadm commit   # stage tracked changes
yadm push                    # sync to GitHub
```

On another machine:

```bash
yadm pull
```

## Layout

```
~
├── .zshrc, .bashrc, .zshenv, .zprofile   shell
├── .tmux.conf                            tmux
├── .gitconfig                            git + delta
├── .config/
│   ├── ghostty/config                    terminal
│   ├── kitty/kitty.conf                  terminal
│   ├── nvim/                             editor (LazyVim)
│   ├── starship.toml                     prompt
│   ├── ranger/                           file manager
│   ├── mise/config.toml                  version manager pins
│   ├── skills/                           agent skills (canonical)
│   │   ├── bellman/SKILL.md
│   │   ├── writing/SKILL.md
│   │   └── ...13 total
│   └── yadm/
│       ├── bootstrap                     setup script
│       └── encrypt                       files to encrypt
├── .claude/
│   ├── CLAUDE.md                         agent instructions
│   ├── settings.json                     agent config
│   ├── statusline.sh                     status bar script
│   └── skills/ → ~/.config/skills/*      symlinks
├── .codex/
│   ├── AGENTS.md                         agent instructions
│   ├── config.toml                       agent config
│   └── skills/ → ~/.config/skills/*      symlinks
└── .local/share/yadm/archive             encrypted secrets
```
