# Herdr

My Herdr (herdr.dev) setup: what `~/.config/herdr-app` holds that is mine. Everything else there the app rewrites on every start.

| Path | What |
| --- | --- |
| `mods/workbench/` | Bottom strip: default spaces per machine (`This computer` → `~/projects`, `omarchy` → `~/code`), the shown space's dev container (Claude inside it, Up, Stop), and the worktree watcher: a new worktree space of a repo with `.devcontainer/` gets a `claude` tab (`devcontainer up` + Claude Code in the container); Remove worktree takes the container down and deletes the branch when `git branch -d` allows it (merged or pushed). Audit trail in `data/workbench.log`. |
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

## What a tab's command runs with

A tab's `argv` gets the Herdr core's own environment, not a shell's. On omarchy that is `PATH=/usr/local/bin:/usr/bin:/bin`, without `~/.local/bin` (the `devcontainer` CLI) and without what `.zshrc` exports. So the workbench commands:

- run through the login shell (`inShell` in `mods/workbench/main.js`), and leave the tab on a shell when a step fails, so the error stays in view;
- set `BUILDX_BAKE_ENTITLEMENTS_FS=0` for `devcontainer up`: Docker Compose 5 always builds through bake, which refuses the Dockerfile the devcontainer CLI generates in `/tmp` (`additional privileges requested: pass "--allow=fs.read=..."`);
- copy the main checkout's `.devcontainer/.env` (minus the per-checkout keys) into a worktree that has none yet. The file is gitignored, and without `SSH_AUTH_SOCK_HOST` in it compose cannot bind the SSH agent socket on Linux.

Git hooks run on the host too: Herdr's `git worktree add` fires guga's Overcommit `post-checkout` under omarchy's system Ruby (`/usr/bin/ruby`), and a failing hook makes Herdr show the error instead of opening the space. The gems for it are user-installed there. After `Gemfile.lock` changes, on omarchy:

```sh
cd ~/code/guga && GEM_HOME=$HOME/.local/share/gem/ruby/3.4.0 BUNDLE_FROZEN=true ~/.local/share/gem/ruby/3.4.0/bin/bundle install
```
