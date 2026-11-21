#!/usr/bin/env bash
set -euo pipefail

# # spotlight-setup
#
# Keeps dev trees out of the Spotlight index. They hold millions of files
# nobody searches for, and agent builds rewrite them all day, which grew the
# index to 27 GB. Items indexed per folder when this list was made:
#
#   ~/dev                                2.2M  scraped data, clones
#   ~/lexe                               430k  agent worktrees' build output
#   /Library/Developer/CommandLineTools  166k  SDK headers
#   ~/Library/pnpm                       122k  pnpm's package store
#   ~/github                             114k  clones
#   ~/<hostname>                           3k  machine config repo
#   ~/workspaces, ~/worktrees                  agent checkouts
#
# Spotlight keeps this list (System Settings › Spotlight › Search Privacy) in
# an undocumented, root-owned plist, so this needs sudo and a terminal with
# Full Disk Access. The list below replaces the whole list there. A change
# erases the index, and Spotlight takes hours to rebuild it.

excluded=(
  "$HOME/dev"
  "$HOME/lexe"
  "$HOME/github"
  # The machine config repo that `hms` loads (see home/default.nix)
  "$HOME/${HM_HOST:-$(hostname -s)}"
  "$HOME/workspaces"
  "$HOME/worktrees"
  "$HOME/Library/pnpm"
  /Library/Developer/CommandLineTools
)

volume=/System/Volumes/Data
plist=$volume/.Spotlight-V100/VolumeConfiguration.plist
buddy=/usr/libexec/PlistBuddy

[[ $(uname -s) == Darwin ]] || { echo >&2 "error: macOS only"; exit 1; }

# Print the current exclusions, one per line. PlistBuddy prints an array as
# "Array {", then each entry indented by 4 spaces, then "}".
current() {
  sudo "$buddy" -c 'Print :Exclusions' "$plist" 2>/dev/null \
    | sed -n 's/^    //p' || true
}

sudo "$buddy" -c Print "$plist" >/dev/null || {
  echo >&2 "error: can't read $plist; give the terminal Full Disk Access"
  exit 1
}

want=$(printf '%s\n' "${excluded[@]}")

# Print `label` and the current list; fail unless it matches `excluded`
show() {
  local got
  got=$(current)
  echo "$1:"
  echo "${got:-(none)}" | sed 's/^/  /'
  [[ $(sort <<< "$got") == $(sort <<< "$want") ]]
}

if show "Current exclusions"; then
  echo "Already set."
  exit 0
fi

# Write the list. The Delete fails when there is no list yet.
sudo "$buddy" -c 'Delete :Exclusions' "$plist" 2>/dev/null || true
cmds=(-c 'Add :Exclusions array')
for path in "${excluded[@]}"; do
  cmds+=(-c "Add :Exclusions: string $path")
done
sudo "$buddy" "${cmds[@]}" "$plist"
show "Written" || { echo >&2 "error: the plist did not take the list"; exit 1; }

# Spotlight's server reads the list at launch, so restart it; launchd
# relaunches it
sudo killall mds
sleep 5
show "After restarting Spotlight" || {
  echo >&2 "error: Spotlight dropped the list; add the folders in"
  echo >&2 "System Settings › Spotlight › Search Privacy instead"
  exit 1
}

sudo mdutil -E "$volume"
echo "Done. Spotlight is rebuilding its index, which takes a few hours."
