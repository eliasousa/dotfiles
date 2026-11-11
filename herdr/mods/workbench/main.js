// Workbench: the default spaces (one per machine, each starting in its base
// folder) and the shown space's dev container (up, Claude Code inside it, stop).
// A new worktree space of a repo with .devcontainer/ gets a "claude" tab at
// once: it brings the container up and runs Claude Code in it. When a worktree
// space goes and its checkout with it (Remove worktree), its dev container is
// taken down and removed, keeping the shared named volumes. As Conductor does.

import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { run, spaces, machines, focused, theme, exec, readTextFile, notify, appHome, home, nextCommand } from "herdr";

// The default spaces: where a new space's terminals start on each machine
// (null: this computer). Keys reach them as workbench.space1, workbench.space2, ...
const HOMES = [
  { machine: null, label: "This computer", folder: `${home()}/projects` },
  { machine: "omarchy", label: "omarchy", folder: "/home/eliasousa/code" },
];
const openHome = (h) => run("space.new", { machine: key(h.machine), folder: h.folder });

// Where the shipped worktree mod puts checkouts (under the machine's home).
const WORKTREES = "/.herdr/worktrees/";
const isWorktree = (folder) => Boolean(folder) && folder.replace(/\\/g, "/").includes(WORKTREES);

// Run in a tab's interactive shell, in the checkout: the dev container comes
// up (the first time: build, initialize, setup) and Claude Code runs inside it.
const UP = "devcontainer up --workspace-folder .";
const CLAUDE = ["sh", "-c", `${UP} && exec devcontainer exec --workspace-folder . claude`];
const UP_ONLY = ["sh", "-c", UP];

// $1: the checkout. Its containers carry the devcontainer CLI's label; a
// compose project goes down whole (named volumes stay), a lone container is removed.
const DOWN = `ids=$(docker ps -aq --filter "label=devcontainer.local_folder=$1")
[ -n "$ids" ] || { echo "no container"; exit 0; }
proj=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' $ids | grep . | sort -u | head -1)
[ -n "$proj" ] && docker compose -p "$proj" down --remove-orphans >/dev/null 2>&1
left=$(docker ps -aq --filter "label=devcontainer.local_folder=$1")
[ -z "$left" ] || docker rm -f $left >/dev/null || exit 1
echo "\${proj:+compose project $proj }removed"`;

// $1: a folder. Exit 0 once it is gone (within ~10 s), 1 if it stays.
const VANISHES = 'for i in 1 2 3 4 5 6 7 8 9 10; do [ -e "$1" ] || exit 0; sleep 1; done; exit 1';

const key = (machine) => machine ?? "";

// A line in ~/.config/herdr-app/data/workbench.log (what the watcher did and why).
const LOG = `${appHome()}/data/workbench.log`;
function trace(...parts) {
  const line = `${new Date().toISOString()} ${parts.map((p) => (typeof p === "string" ? p : JSON.stringify(p))).join(" ")}`;
  return exec("sh", ["-c", 'printf "%s\\n" "$1" >> "$2"', "sh", line, LOG]).catch(() => {});
}

async function sh(cmd, { cwd, on, timeout, args = [] } = {}) {
  try {
    const r = await exec("sh", ["-c", cmd, "sh", ...args], { ...(cwd ? { cwd } : {}), on, ...(timeout ? { timeout } : {}) });
    return { ok: r.code === 0, out: (r.stdout ?? "").trim(), err: (r.stderr ?? "").trim() };
  } catch (e) {
    return { ok: false, out: "", err: String(e) };
  }
}

export default class Workbench extends View {
  init(_props, cx) {
    cx.spawn(async () => trace("init", _props));
    this.seen = new Map(); // machine → Map(space id → { folder, machine }), seeded when its layout is first ready
    this.devc = new Map(); // "machine:folder" → has .devcontainer/devcontainer.json
    this.info = {}; // space id → { top, devc, state, port }
    this.at = null; // "space|cwd" last looked at
    this.looking = new Set();
    this.busy = new Set();
    cx.timer.every(15000, (cx) => this.refresh(cx));
    // Key commands: "space<n>" opens HOMES[n - 1].
    cx.spawn(async () => {
      for (;;) {
        const c = await nextCommand();
        const h = HOMES[Number(c.match(/^space(\d+)$/)?.[1]) - 1];
        if (h) openHome(h);
      }
    });
  }

  // Spaces that came or went since each machine's layout became ready.
  watch(cx) {
    const ready = machines().filter((m) => m.layout === "ready").map((m) => key(m.name));
    const all = spaces();
    for (const k of ready) {
      const mine = all.filter((s) => key(s.machine) === k);
      const seen = this.seen.get(k);
      if (!seen) {
        this.seen.set(k, new Map(mine.map((s) => [s.id, { folder: s.folder, machine: s.machine }])));
        const line = ["seed", k || "local", mine.map((s) => s.id)];
        cx.spawn(async () => trace(...line));
        continue;
      }
      const now = new Set(mine.map((s) => s.id));
      for (const [id, was] of [...seen]) {
        if (now.has(id)) continue;
        seen.delete(id);
        cx.spawn(async () => trace("gone", id, was));
        if (isWorktree(was.folder)) this.gone(was, cx);
      }
      for (const s of mine) {
        if (seen.has(s.id)) continue;
        seen.set(s.id, { folder: s.folder, machine: s.machine });
        const line = ["new", s.id, s.folder, s.machine];
        cx.spawn(async () => trace(...line));
        if (isWorktree(s.folder)) this.start(s, cx);
      }
    }
  }

  start(s, cx) {
    cx.spawn(async (cx) => {
      const devc = await this.hasDevcontainer(s.folder, s.machine);
      trace("start", s.id, s.folder, { devc });
      if (!devc) return;
      run("tab.new", { space: s.id, name: "claude", folder: s.folder, argv: CLAUDE });
      notify({ title: "Dev container", body: `${s.folder.split("/").pop()}: bringing it up, then Claude Code inside it.`, level: "info", timeout: 5000 });
      cx.notify();
    });
  }

  // A worktree space went away. If its checkout goes too (Remove worktree),
  // its dev container goes down and away; a space merely closed keeps it.
  gone(was, cx) {
    cx.spawn(async (cx) => {
      const vanished = await sh(VANISHES, { on: was.machine, timeout: 20000, args: [was.folder] });
      trace("vanished?", was.folder, vanished);
      if (!vanished.ok) return;
      const name = was.folder.split("/").pop();
      const r = await sh(DOWN, { on: was.machine, timeout: 180000, args: [was.folder] });
      trace("down", was.folder, r);
      notify({
        title: "Dev container",
        body: r.ok ? `${name}: ${r.out.split("\n").pop() || "removed"}.` : `${name}: couldn't remove its container. ${r.err}`,
        level: r.ok ? "success" : "warning",
        timeout: 6000,
      });
      cx.notify();
    });
  }

  async hasDevcontainer(folder, on) {
    const k = `${key(on)}:${folder}`;
    if (!this.devc.has(k)) this.devc.set(k, (await readTextFile(`${folder}/.devcontainer/devcontainer.json`, { on })) !== null);
    return this.devc.get(k);
  }

  // The shown space's checkout and its container.
  look(s, cwd, cx) {
    const k = `${s.id}|${cwd}`;
    if (this.looking.has(k)) return;
    this.looking.add(k);
    cx.spawn(async (cx) => {
      try {
        const top = await sh("git rev-parse --show-toplevel", { cwd, on: s.machine });
        const folder = top.ok ? top.out : cwd;
        const devc = await this.hasDevcontainer(folder, s.machine);
        this.info[s.id] = { top: folder, devc, state: null, port: null };
        cx.notify();
        if (devc) await this.state(s, cx);
      } finally {
        this.looking.delete(k);
      }
    });
  }

  async state(s, cx) {
    const i = this.info[s.id];
    if (!i?.devc) return;
    const r = await sh('docker ps -a --filter "label=devcontainer.local_folder=$1" --format "{{.State}}"', { cwd: i.top, on: s.machine, timeout: 10000, args: [i.top] });
    i.state = r.ok ? r.out.split("\n")[0] || "none" : "?";
    const env = await readTextFile(`${i.top}/.devcontainer/.env`, { on: s.machine });
    i.port = env?.match(/^APP_PORT=(\d+)/m)?.[1] ?? null;
    cx.notify();
  }

  refresh(cx) {
    const f = focused();
    const s = f && spaces().find((x) => x.id === f.space);
    if (s && this.info[s.id]?.devc) cx.spawn(async (cx) => this.state(s, cx));
  }

  tab(s, name, argv) {
    const i = this.info[s.id];
    run("tab.new", { space: s.id, name, folder: i.top, argv });
  }

  stop(s, cx) {
    const i = this.info[s.id];
    if (!i || this.busy.has(s.id)) return;
    this.busy.add(s.id);
    cx.spawn(async (cx) => {
      const r = await sh('ids=$(docker ps -q --filter "label=devcontainer.local_folder=$1"); [ -n "$ids" ] && docker stop $ids', { cwd: i.top, on: s.machine, timeout: 60000, args: [i.top] });
      notify({ title: "Dev container", body: r.ok ? `${i.top.split("/").pop()}: stopped.` : r.err || "Nothing running here.", level: r.ok ? "success" : "warning", timeout: 4000 });
      this.busy.delete(s.id);
      await this.state(s, cx);
    });
  }

  render(cx) {
    const t = theme();
    try {
      this.watch(cx);
    } catch (e) {
      const msg = `${e}`;
      cx.spawn(async () => trace("watch error", msg));
    }
    const f = focused();
    const s = f ? spaces().find((x) => x.id === f.space) : null;
    const cwd = f?.cwd || s?.folder || null;
    if (s && cwd && this.at !== `${s.id}|${cwd}`) {
      this.at = `${s.id}|${cwd}`;
      this.look(s, cwd, cx);
    }
    const i = s ? this.info[s.id] : null;
    const ready = new Map(machines().map((m) => [key(m.name), m.layout === "ready"]));

    const button = (id, label, icon, tip, on, enabled = true) =>
      h_flex()
        .id(id)
        .flex_none()
        .h(22)
        .px(8)
        .gap(5)
        .items_center()
        .rounded(5)
        .text_color(enabled ? t.muted : t.dim)
        .tooltip(tip)
        .when(enabled, (el) => el.cursor_pointer().hover((st) => st.bg(t.hover).text_color(t.foreground)).on_click((_e, cx) => on(cx)))
        .when(Boolean(icon), (el) => el.child(svg(icon).size(12).flex_none()))
        .child(div().child(label));

    const homes = HOMES.map((h) =>
      button(`home-${key(h.machine) || "local"}`, h.label, "mods/workspace-chrome/folder.svg", `New space on ${h.label} in ${h.folder}`, () => openHome(h), ready.get(key(h.machine)) === true),
    );

    const dot = (color) => div().size(6).rounded(3).flex_none().bg(color);
    const stateColor = i?.state === "running" ? t.ansi2 : i?.state === "?" ? t.blocked : t.dim;
    const container = !i?.devc
      ? []
      : [
          h_flex().flex_none().gap(6).items_center().px(6).text_color(t.dim).child(svg("mods/workspace-chrome/server.svg").size(12).flex_none()).child(div().truncate().child(`${i.top.split("/").pop()} · dev container`)).child(dot(stateColor)).child(div().child(i.state ?? "…")).when(Boolean(i.port), (el) => el.child(div().child(`:${i.port}`))),
          button("devc-claude", "Claude", "icons/claude.svg", "A tab: bring the dev container up and run Claude Code inside it", () => this.tab(s, "claude", CLAUDE)),
          button("devc-up", "Up", null, "A tab: bring the dev container up (build, initialize and set up the first time)", () => this.tab(s, "devcontainer", UP_ONLY)),
          button("devc-stop", "Stop", null, "Stop this checkout's running dev container (Remove worktree takes it down for good)", (cx) => this.stop(s, cx), !this.busy.has(s.id)),
        ];

    return h_flex()
      .id("root")
      .size_full()
      .px(8)
      .gap(4)
      .items_center()
      .bg(t.chrome)
      .text_size(12)
      .children(homes)
      .child(div().flex_1())
      .children(container);
  }
}
