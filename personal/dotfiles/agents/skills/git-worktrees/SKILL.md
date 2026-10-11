---
name: git-worktrees
description: How to pick or create a git worktree before starting work in one of Patrick's repos. Load before making changes on a new branch, when asked to make a new worktree, or when the current worktree is already busy with something else.
---

# Git worktrees

I usually have several agents working in the same repo at once, each in its own worktree (e.g. `~/code/berry`, `~/code/2-berry`, `~/code/3-berry`). This is how to grab one without stepping on another agent, without eating disk, and without starting from a stale main.

Claim a worktree _first_ and do the slow stuff (installs, dedupe) after. Another agent may be doing exactly the same thing at the same time.

## Step 1: Which remote and branch is "main"?

Forks have an `upstream` remote, and that's the one to branch from. Otherwise use `origin`.

```bash
REMOTE=$(git remote | grep -qx upstream && echo upstream || echo origin)
DEFAULT=$(git ls-remote --symref "$REMOTE" HEAD | awk '/^ref:/ {sub("refs/heads/", "", $2); print $2}')
git fetch "$REMOTE" "$DEFAULT"
```

Branch names look like `patrickshaw/<kebab-case-topic>`.

## Step 2: Is there an idle main worktree to reuse?

```bash
git worktree list --porcelain
```

A worktree is idle if:

- Its branch is the default branch or a suffixed copy of it (`main`, `master`, `main-2`, `master-3`...). Never reuse a worktree that's on a feature branch or detached - someone's probably mid-task in it.
- It's not marked `locked` or `prunable`.
- `git -C <path> status --porcelain` is empty. A dirty main is either me or another agent mid-task, so leave it alone. Never stash, reset or clean it to make it usable.

If there's one, claim it straight away by switching to your new branch, based on the freshly fetched main:

```bash
cd <path>
git switch --no-track -c <branch> "$REMOTE/$DEFAULT"
git branch --show-current  # should print <branch>
```

`--no-track` is deliberate - tracking `upstream/master` means a stray `git push` would try to push to master.

If `git branch --show-current` doesn't print your branch, another agent claimed it at the same moment. Pick a different idle worktree or go to Step 3.

Then skip to Step 4.

## Step 3: No idle worktree? Make one

New worktrees are siblings of the existing ones, named `<n>-<repo>`, where `<n>` is one more than the highest number already used (an unnumbered one counts as 1). For example, `berry` and `2-berry` means the next is `3-berry`.

```bash
git worktree add --no-track -b <branch> <new-path> "$REMOTE/$DEFAULT"
```

Install dependencies now if the repo needs them, _before_ deduping. Otherwise `node_modules` and package caches get missed and those are usually the bulk of it.

Then dedupe the new worktree against an existing one. Pick one that's had its dependencies installed - the primary worktree is usually a good bet:

```bash
fclones group <new-path> <existing-path> --hidden -I --exclude '**/.git/**' \
  | fclones dedupe --path '<new-path>/**'
```

- `-I` (`--isolate`) only counts files duplicated _across_ the two trees, rather than within one.
- `--path` limits which files get replaced to the new worktree, so the existing one is never touched.
- `dedupe` uses copy-on-write clones (APFS/btrfs/xfs), so either side can still be edited independently afterwards. Never use `fclones link` - hardlinks mean editing a file in one worktree silently edits it in the other.
- If `dedupe` complains the filesystem doesn't support reflinks, skip it and mention it rather than working around it.

Check `git status` is still clean in both trees afterwards and mention how much space was reclaimed (`df` before and after is fine).

## Step 4: Confirm you're on the latest main before starting

```bash
git fetch "$REMOTE" "$DEFAULT"
git merge-base --is-ancestor "$REMOTE/$DEFAULT" HEAD && echo up-to-date
```

If you were asked to carry on with an existing branch rather than start a new one, rebase it onto `$REMOTE/$DEFAULT` instead. Check with me first if it's already been pushed, since that rewrites history.

Tell me which worktree and branch you ended up on before getting into the actual work.
