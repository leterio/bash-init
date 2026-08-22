# init-scripts

Bash helpers for interactive terminals. The scripts load on WSL, native
Linux, Docker, and macOS. Stages that need a missing tool or host skip
quietly so the rest of init can continue.

## Install

From anywhere:

```shell
/path/to/init-scripts/install.sh
```

Options and environment overrides:

| Flag | Env | Default | Role |
| --- | --- | --- | --- |
| `-i` | `INSTALL_DIR` | `~/.local/bin` | Where `bin/` and `init.sh/` are installed |
| `-d` | `DEV_DIR` | `~/Development` | Development root (`DEV`) |
| `-p` | `PROJECTS_DIR` | `<dev>/Projects` | Projects root (`PROJECTS`) |

The installer:

1. Creates the install, dev, and projects directories.
2. Copies `bin/` into the install directory (including `modules/`).
3. Copies `init.sh/` into `<install_dir>/init.sh`.
4. Writes a managed INIT block into `~/.bashrc` (replaced on re-install).

Example:

```shell
./install.sh
# or
INSTALL_DIR=~/.local/bin DEV_DIR=~/Development ./install.sh
# or
./install.sh -i ~/.local/bin -d ~/Development -p ~/Development/Projects
```

Then open a new terminal, or run `source ~/.bashrc` / `reinit`.

## What gets configured in ~/.bashrc

```shell
export DEV="…"
export PROJECTS="…"
export BASH_INIT="…/init.sh"   # under the install directory
export PATH="<install_dir>:$PATH"
source "$BASH_INIT/init.sh"
```

## Layout (repository)

| Path | Role |
| --- | --- |
| `install.sh` | User installer |
| `init.sh/` | Orchestrator (`init.sh`) and numbered stage scripts |
| `bin/` | `use-module` and libraries under `bin/modules/` |

After install, `use-module` loads libraries from `modules/` next to itself
(so it works under any `-i` destination).

### bin/modules

Sourced libraries (`colors.sh`, `logs.sh`, `checkport.sh`). Load them
with:

```shell
source use-module colors
source use-module logs checkport
```

`use-module` records each filename (without `.sh`) in `LOADED_MODULES`
(shell-local; not exported) and skips modules that are already listed.
`init.sh` clears `LOADED_MODULES` on each run so `reinit` redefines
functions. Call `source use-module` again from another module to declare
a dependency; do not gate on colors or log functions yourself.

### init.sh

Orchestrator and stage scripts. When `BASH_INIT` points at this
directory, `source "$BASH_INIT/init.sh"` loads every `*_init_*.sh` in
lexicographic order from `$BASH_INIT/` itself.

## init.sh stages

- 00-09: Environment
  - `00_init_environment.sh` — host helpers (`is_wsl`, `is_macos`,
    `is_linux`, `is_docker`, `has_command`)
  - `01_init_base_modules.sh` — loads `colors`, `logs`, and `checkport`
- 10-19: Commands and integrations
  - `10_init_commands.sh` — `ls`/`ll`, `reinit`, `dev`, `proj`, `wd`,
    and `apt_upgrade` when `apt` is available
  - `10_init_windows_integration.sh` — WSL only (`explorer`, `code`,
    `cdw`)
  - `19_init_git.sh` — requires `git` (`gst`, `gfall`, `gsw`, …). Sets
    `PS1_GIT` via `ps1_with_git` / `ps1_with_git_on_root`
  - `19_init_docker.sh` — requires `docker` (`docker_prune`)
- 20-29: Network
  - No bundled scripts
- 90-99: Finalization
  - `90_init_ps1.sh` — builds `PS1` from `PS1_FRAGMENTS`, replaces
    `{{PS1_*}}` placeholders, and unsets those variables

Windows-only helpers (`git_use_win`, `wgit`, `lgit`) load only on WSL.
Elsewhere, `git` stays the host binary.

## Command names

Public functions use `snake_case` (`git_pull_all`, `log_error`). Short
interactive aliases stay in place:

| Alias | Function |
| --- | --- |
| `gst` | `git status -uall` |
| `gclog` | `git_log` |
| `gclogb` | `git_log_branch` |
| `gfall` | `git_pull_all` |
| `gfallr` | `git_pull_all_recursive` |
| `gsw` | `git_switch_all` |
| `ll` | long `ls` |
| `reinit` | `source ~/.bashrc` |
| `dev` | `cd "$DEV"` |
| `proj` | `cd` under `$PROJECTS` |
| `wd` | `cd` under `$DEV/wd` |

## AI-Assisted Development Disclaimer

This project is developed with the assistance of AI tools and agents. AI may be used to write, refactor, optimize, review, and improve parts of the codebase.

The use of AI in this project is free and encouraged, but should always be approached consciously and responsibly. AI-generated contributions should be reviewed, understood, and validated by humans before being considered reliable.

AI assistance does not replace human judgment, code review, testing, security considerations, or responsibility for the resulting code. Contributors are encouraged to use AI as a tool to support development — not as a substitute for understanding the code or its implications.
