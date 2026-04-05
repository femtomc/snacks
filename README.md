# snacks

Dotfiles for Pop!_OS 24.04 (COSMIC) and macOS, managed by
[yadm](https://yadm.io).

```bash
yadm clone git@github.com:femtomc/snacks.git
yadm bootstrap
```

## Setup

`yadm bootstrap` installs everything and is idempotent. It detects Linux vs
macOS and uses apt or Homebrew accordingly. On a fresh machine, install yadm
first (`sudo apt install yadm` or `brew install yadm`).

After bootstrap, import the GPG key to decrypt secrets:

```bash
gpg --import /path/to/gpg-snacks.key
yadm decrypt
gh auth login
```

### What bootstrap installs

| Method | What |
|--------|------|
| apt / brew | system packages, gh |
| cargo | eza, bat, delta, fd, rg, zoxide, bob-nvim |
| bob | nvim |
| git clone | fzf, oh-my-zsh + plugins, TPM |
| curl | rustup, starship, mise, uv, bun, flyctl, elan (Lean 4), Claude Code |
| npm | Codex |
| uv tool | bellman, smg |
| GitHub release | lazygit, act |
| mise | node 22, elixir 1.17, erlang 27 |
| keyd (Linux) | installs Super→Ctrl modifier to /etc/keyd/ |

CLI tools install via cargo rather than apt because apt packages for these lag
months behind upstream and sometimes ship under different binary names.

## How things fit together

Gruvbox theme across terminal (Ghostty, Kitty), editor (Neovim, Zed),
multiplexer (tmux, Zellij), and COSMIC desktop. Vim keybindings in every
editor. Ctrl-A prefix in both tmux and Zellij.

keyd makes Super act as a pure Command modifier on Linux — Super+C sends
Ctrl+C, Super+S sends Ctrl+S, etc. Unmapped keys (Super+Arrow, Super+1-9) pass
through to COSMIC for tiling and workspaces. Launcher is Ctrl+Space.

Agent skills live in `~/.config/skills/` and are symlinked into both
`~/.claude/skills/` and `~/.codex/skills/`, so both tools read from the same
files.

## What's tracked

```
~
├── .zshrc, .bashrc, .zshenv, .zprofile   zsh, oh-my-zsh, vi mode, starship
├── .tmux.conf                            tmux
├── .gitconfig, .condarc, .ssh/config     git (delta), conda, ssh hosts
│
├── .config/
│   ├── cosmic/                           COSMIC desktop (Linux)
│   │   ├── CosmicComp/                     per-workspace autotile
│   │   ├── CosmicSettings.Shortcuts/       Ctrl+Alt fallbacks for keyd
│   │   ├── CosmicTheme.Dark/               gruvbox palette
│   │   ├── CosmicTk/                       Inter / TX-02 fonts
│   │   └── CosmicPanel.{Panel,Dock}/       panel + dock
│   ├── keyd/default.conf                 Super → Ctrl modifier (Linux)
│   │
│   ├── ghostty/config                    primary terminal
│   ├── kitty/kitty.conf                  secondary terminal
│   ├── zellij/                           multiplexer + layouts
│   │
│   ├── nvim/                             LazyVim (Lean 4, oil, typst)
│   ├── zed/settings.json                 Zed
│   │
│   ├── skills/ (13)                      agent skills (canonical)
│   ├── wallpaper/platform.jpg            background
│   ├── ranger/, btop/, glow/             file manager, monitor, markdown
│   ├── git/ignore, mise/config.toml      global gitignore, version pins
│   ├── mimeapps.list                     default applications
│   └── yadm/
│       ├── bootstrap                     setup script
│       ├── encrypt                       encrypted file list
│       └── hooks/pre-commit              commit checks
│
├── .claude/                              Claude Code config + skill symlinks
├── .codex/                               Codex config + skill symlinks
└── .local/share/yadm/archive             GPG-encrypted .secrets
```

## Updating

```bash
yadm add -u && yadm commit
yadm push
```

Pre-commit hook runs shellcheck, stylua, JSON/TOML validation, and a secrets
scan.
