# Herdr

My Herdr (herdr.dev) setup: what `~/.config/herdr-app` holds that is mine. Everything else there the app rewrites on every start.

| Path | What |
| --- | --- |
| `mods/workbench/` | Bottom strip: default spaces per machine (`This computer` → `~/projects`, `omarchy` → `~/code`), the shown space's dev container (Claude inside it, Up, Stop), and the worktree watcher: a new worktree space of a repo with `.devcontainer/` gets a `claude` tab (`devcontainer up` + Claude Code in the container); Remove worktree takes the container down. Audit trail in `data/workbench.log`. |
| `mods/review/` | `cmd-shift-r`: review the shown space's branch against the default branch in a new tab (Claude Opus, read-only). The brief is `prompt.md` (Conductor's review guidelines). |
| `layouts/my-main.json` | Herdr's `main` layout plus the `workbench` block above the status bar. Shipped layouts take no structural change, hence the clone. |
| `keys.json` | `cmd-n` / `cmd-shift-n` → `workbench.space1` / `space2`; `cmd-shift-r` → review. |
| `settings.json` | Zoom, fonts. |

## New Mac

1. Install Herdr, open it once.
2. `~/.dotfiles/herdr/install.sh`
3. Quit and reopen Herdr. `herdr-app do layout.switch '{"name":"my-main"}'`.
4. `hc machine add omarchy` (machines are not in these files).
5. The remote folder of the `omarchy` entry is hardcoded in `mods/workbench/main.js` (`HOMES`); the local one follows `$HOME`.

## After editing in place

`~/.dotfiles/herdr/save.sh`, then commit. Saving a mod file does not always reach the open window: quit and reopen Herdr, and `herdr-app check ~/.config/herdr-app/mods/<name>` first.

Dev containers need Docker Desktop on the Mac. On omarchy the user is in the `docker` group and `SSH_AUTH_SOCK_HOST` comes from `omarchy-dotfiles`.
