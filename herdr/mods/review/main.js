// Review: opens a new tab where Claude Opus reviews the focused space's
// changes against the repo's default branch (origin/HEAD), read-only.
// Opened as a dialog (mod.open review, cmd-shift-r). Enter starts, Esc cancels.
// The review brief is prompt.md next to this file (Conductor's review
// guidelines, with {{branch}}, {{base}} and {{mergeBase}} filled in).

import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { run, props, closeOverlay, theme, focused, spaces, exec, readTextFile, appHome } from "herdr";

const ARGV = ["claude", "--model", "opus", "--effort", "high", "--disallowedTools", "Edit", "Write", "NotebookEdit"];

async function git(cwd, args, on, timeout) {
  try {
    const r = await exec("git", args, { cwd, on, ...(timeout ? { timeout } : {}) });
    return { ok: r.code === 0, out: (r.stdout ?? "").trim(), err: (r.stderr ?? "").trim() };
  } catch (e) {
    return { ok: false, out: "", err: String(e) };
  }
}

// The default branch: origin/HEAD, else origin/main, origin/master, main, master.
async function defaultBranch(root, on) {
  const head = await git(root, ["symbolic-ref", "--short", "refs/remotes/origin/HEAD"], on);
  if (head.ok && head.out) return head.out;
  for (const b of ["origin/main", "origin/master", "main", "master"]) {
    if ((await git(root, ["rev-parse", "--verify", "--quiet", b], on)).ok) return b;
  }
  return null;
}

// The brief: prompt.md with its placeholders filled; a short built-in one if the file is missing.
async function prompt(base, mergeBase, branch) {
  const template = await readTextFile(`${appHome()}/mods/review/prompt.md`);
  if (template) {
    const fill = { branch, base, mergeBase };
    return { source: "prompt.md", text: template.replace(/\{\{(branch|base|mergeBase)\}\}/g, (_m, k) => fill[k]) };
  }
  const text = [
    `Review the changes on branch \`${branch}\` against \`${base}\`.`,
    `The diff is \`git diff ${mergeBase}\` (committed and uncommitted work); \`git log --oneline ${mergeBase}..HEAD\` lists the commits.`,
    `Read the surrounding code as needed. Do not edit any file: this is a review only.`,
    `Look for bugs, regressions, security issues, missing error handling, and missing tests. Skip style nits.`,
    `Report each finding as \`path:line — severity (high/medium/low) — problem — suggested fix\`, most severe first. If nothing is wrong, say so.`,
  ].join(" ");
  return { source: "built-in (prompt.md missing)", text };
}

export default class Review extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    this.handle.focus();
    this.state = { loading: true };
    cx.spawn(async (cx) => {
      this.state = await this.inspect();
      cx.notify();
    });
  }

  async inspect() {
    const f = focused();
    const space = spaces().find((s) => s.id === f?.space);
    if (!space) return { error: "No space focused." };
    const on = space.machine ?? null;
    const cwd = f?.cwd || space.folder;
    if (!cwd) return { error: "This space has no folder." };
    const top = await git(cwd, ["rev-parse", "--show-toplevel"], on);
    if (!top.ok) return { error: `Not a git repository: ${cwd}` };
    const root = top.out;
    // Refresh the remote's default branch quietly; offline is fine.
    await git(root, ["fetch", "--quiet", "origin"], on, 15000);
    const base = await defaultBranch(root, on);
    if (!base) return { error: "Could not find the default branch (no origin/HEAD, main or master)." };
    const branch = (await git(root, ["branch", "--show-current"], on)).out || "HEAD";
    const mb = await git(root, ["merge-base", base, "HEAD"], on);
    if (!mb.ok) return { error: `No common history with ${base}.` };
    const commits = Number((await git(root, ["rev-list", "--count", `${mb.out}..HEAD`], on)).out) || 0;
    const stat = (await git(root, ["diff", "--shortstat", mb.out], on)).out;
    const untracked = (await git(root, ["ls-files", "--others", "--exclude-standard"], on)).out.split("\n").filter(Boolean).length;
    const brief = await prompt(base, mb.out, branch);
    return { space: space.id, root, base, branch, mergeBase: mb.out, commits, stat, untracked, task: brief.text, promptSource: brief.source };
  }

  start() {
    const s = this.state;
    if (!s || s.loading || s.error || this.empty(s)) return;
    closeOverlay(props().overlay);
    run("tab.new", { space: s.space, name: "review", folder: s.root, argv: ARGV, task: s.task });
  }

  empty(s) {
    return !s.stat && s.commits === 0 && s.untracked === 0;
  }

  render(cx) {
    const t = theme();
    const s = this.state;
    const close = () => closeOverlay(props().overlay);
    const button = (id, label, bg, fg, border, onClick) =>
      h_flex().id(id).h(32).px(14).items_center().rounded(8).border_1().border_color(border).bg(bg).text_color(fg).cursor_pointer().hover((st) => st.opacity(0.88)).on_click(onClick).child(label);
    const row = (k, v) => h_flex().gap(8).child(div().w(90).text_color(t.dim).child(k)).child(div().flex_1().truncate().text_color(t.foreground).child(v));

    let body;
    if (s.loading) body = div().text_color(t.muted).child("Checking the branch…");
    else if (s.error) body = div().text_color(t.blocked).child(s.error);
    else
      body = v_flex()
        .gap(6)
        .child(row("Branch", s.branch))
        .child(row("Base", s.base))
        .child(row("Commits", String(s.commits)))
        .child(row("Changes", [s.stat || "no tracked changes", s.untracked ? `${s.untracked} untracked` : ""].filter(Boolean).join(", ")))
        .child(row("Brief", s.promptSource))
        .when(this.empty(s), (el) => el.child(div().text_color(t.muted).child("Nothing to review.")));

    const ready = !s.loading && !s.error && !this.empty(s);
    return v_flex()
      .id("review")
      .track_focus(this.handle)
      .on_key_down((e, cx) => {
        if (e.key === "enter") this.start();
        else if (e.key === "escape") close();
        else return;
        cx.stop_propagation();
      })
      .size_full()
      .min_h(0)
      .p(18)
      .gap(12)
      .rounded(8)
      .bg(t.popover)
      .text_size(13)
      .child(h_flex().items_center().child(div().flex_1().text_size(15).font_semibold().text_color(t.foreground).child("Review with Claude Opus")).child(div().text_size(11).text_color(t.dim).child("Esc")))
      .child(div().flex_1().min_h(0).child(body))
      .child(
        h_flex()
          .justify_end()
          .gap(8)
          .text_size(12)
          .child(button("no", "Cancel", t.raised, t.foreground, t.input, close))
          .when(ready, (el) => el.child(button("yes", "Start review", t.solid, t.solid_foreground, t.solid, () => this.start()))),
      );
  }
}
