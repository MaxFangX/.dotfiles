---
name: skill-sync
description: >-
  Sync agent skills between dotfiles (ai/skills/) and their peer repos:
  lexe's .agents/skills/ (both ways) and the Paseo fork's skills/ (from
  only). Use when asked to sync, diff, upstream, or vendor skills, or after
  editing a shared skill in either repo.
---

# Skill sync

`just skills-diff <peer>` and `just skills-sync <peer> from|to [skill...]`,
run from ~/.dotfiles, do the copying.

## What is shared

Everything synced between dotfiles and lexe is on this list, which `SHARED`
in `just/skill-sync.sh` repeats:

- skills: codex-review, jj, jj-rebase, lexe-way, orchestrate, q, tighten,
  tighten-code, tighten-comments
- `just/workspace/`, by hand (below)

Nothing else is synced in either direction, by the script or by hand. A
skill joins the list only when I say so, not when it is created.
`sharedSkillNames` in `home/mods/core.nix` deploys every dotfiles skill and
is not this list.

## Peers

- **lexe** (`~/lexe/org/lexe/.agents/skills`): synced both ways.
- **paseo** (`~/dev/paseo/skills`, my Paseo fork): synced `from` only, so
  the next sync wipes any dotfiles-side edit. Put agent-facing additions in
  `paseo-orchestrate`, and docs for fork features in a fork commit.
  dotfiles pins `maxfangx-v*` tags, so add that commit on top rather than
  amending a tagged one.

## Rules

- Sync commits use the same message in both repos,
  `skills: <skill>: <summary>`, which marks the last sync point.
- `sync` overwrites the destination, so merge changes made on both sides
  by hand first.
- Content from an in-flight lexe branch lands with that branch, and a copy
  on lexe master would become redundant commits when the branch rebases.
  So vendor such content into dotfiles only. To check for it:

  ```sh
  jj log -r 'trunk()..(bookmarks() | working_copies())' \
    .agents/skills/<name>
  ```

- Skills deploy through home-manager, so run `hms` after changing
  `ai/skills/`.

## Also mirrored: just/workspace/

The script doesn't cover `just/workspace/`, whose copies differ by design:
lexe's is shfmt'd and documented in its README, and dotfiles' runs globally
via `just -g`. Port fixes to both by hand, in each side's style. `just -g`
runs the copy home-manager deployed, so run `hms` before testing it.
