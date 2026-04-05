# snacks

Three problems this repo solves: getting Mac muscle memory on a Linux desktop,
keeping one set of agent skills in sync across Claude Code and Codex, and
bootstrapping a full development environment on a fresh machine with two
commands.

```bash
yadm clone git@github.com:femtomc/snacks.git
yadm bootstrap
```

Managed by [yadm](https://yadm.io). Works on Pop!_OS 24.04 (COSMIC) and macOS.

## Design

Everything is gruvbox, everywhere. Terminal, editor, desktop, multiplexer — the
same palette so context switches don't cost a visual adjustment. Every editor
runs vim keybindings. Every multiplexer uses Ctrl-A as prefix.

On Linux, [keyd](https://github.com/rvaiya/keyd) remaps Super into a pure
Command modifier: Super+C sends Ctrl+C, Super+S sends Ctrl+S, and so on for 17
common shortcuts. Keys not in the remap (Super+Arrow, Super+1-9) pass through
to COSMIC for tiling and workspaces. No tap-vs-hold detection, no input lag —
Super acts exactly like Command on a Mac. Launcher moves to Ctrl+Space.

Agent skills (writing style, commit discipline, testing strategy, language
idioms for Zig/Python/Lean, LaTeX/TikZ, architecture tools) live in one
canonical directory (`~/.config/skills/`) and are symlinked into both
`~/.claude/skills/` and `~/.codex/skills/`. Edit a skill once, both agents see
it.

## What's tracked

```
~
├── .zshrc, .bashrc, .zshenv, .zprofile   zsh + oh-my-zsh, vi mode, starship
├── .tmux.conf                            Ctrl-A, vi-copy, 50K scroll, sixel
├── .gitconfig, .condarc, .ssh/config     delta diffs, conda, ssh hosts
│
├── .config/
│   ├── cosmic/                           COSMIC desktop (Linux)
│   │   ├── CosmicComp/                     per-workspace autotile
│   │   ├── CosmicSettings.Shortcuts/       Ctrl+Alt fallbacks for keyd
│   │   ├── CosmicTheme.Dark/               gruvbox palette + spacing
│   │   ├── CosmicTk/                       Inter / TX-02 fonts
│   │   └── CosmicPanel.{Panel,Dock}/       panel + dock layout
│   ├── keyd/default.conf                 Super → Ctrl modifier (Linux)
│   │
│   ├── ghostty/config                    primary terminal (gruvbox-material)
│   ├── kitty/kitty.conf                  secondary terminal (gruvbox)
│   ├── zellij/                           multiplexer + zjstatus + dev layout
│   │
│   ├── nvim/                             LazyVim (Lean 4, oil, typst)
│   ├── zed/settings.json                 vim mode, PragmataPro, ruff
│   │
│   ├── skills/ (13 total)                canonical agent skills
│   ├── wallpaper/platform.jpg            shared background
│   ├── ranger/, btop/, glow/             file manager, monitor, markdown
│   ├── git/ignore, mise/config.toml      global gitignore, version pins
│   ├── mimeapps.list                     default applications
│   └── yadm/
│       ├── bootstrap                     setup script
│       ├── encrypt                       encrypted file list
│       └── hooks/pre-commit              shellcheck, stylua, secrets scan
│
├── .claude/                              Claude Code config + skill symlinks
├── .codex/                               Codex config + skill symlinks
└── .local/share/yadm/archive             GPG-encrypted .secrets
```

## Bootstrap

A fresh machine needs yadm installed (`sudo apt install yadm` or `brew install
yadm`), then two commands. The bootstrap script detects Linux vs macOS and
installs accordingly — apt on Linux, Homebrew on macOS. Each tool is skipped if
already present.

CLI replacements (eza, bat, delta, fd, rg, zoxide) install via cargo rather
than apt because cargo tracks upstream releases — apt packages for these tools
lag months behind and sometimes ship under different binary names.

| Method | What |
|--------|------|
| apt / brew | system packages, gh |
| cargo | eza, bat, delta, fd, rg, zoxide, bob-nvim |
| bob | nvim (version-managed) |
| git clone | fzf, oh-my-zsh + plugins, TPM |
| curl | rustup, starship, mise, uv, bun, flyctl, elan (Lean 4), Claude Code |
| npm | Codex |
| uv tool | bellman (work-graph orchestrator), smg (architecture graph) |
| GitHub release | lazygit, act |
| mise | node 22, elixir 1.17, erlang 27 |
| keyd | Super→Ctrl modifier (Linux, installed to /etc/keyd/) |

## New machine

```bash
sudo apt install yadm                        # or: brew install yadm
yadm clone git@github.com:femtomc/snacks.git
yadm bootstrap
gpg --import /path/to/gpg-snacks.key        # then: yadm decrypt
gh auth login
```

## Updating

```bash
yadm add -u && yadm commit
yadm push
```

A pre-commit hook checks every commit: shellcheck on shell scripts, stylua on
Lua, syntax validation on JSON and TOML, a scan for leaked secrets and private
keys, and a check for hardcoded home directory paths.
