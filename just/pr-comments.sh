#!/usr/bin/env bash
set -euo pipefail

# # pr-comments
#
# Fetches and displays GitHub PR review comments with code
# context. Automatically detects PR number from current branch.
# Shows unresolved comments by default; can show all, only
# resolved, or main PR thread comments only.
#
# ## Usage
#
# pr-comments.sh [unresolved|resolved|all|pr] [pr-number]
#
# ## Args
#
# filter    = "unresolved" (default), "resolved", "all",
#             or "pr" (main thread only)
# pr-number = PR number (optional, auto-detects from
#             current branch by default)

# Check dependencies
if ! command -v gh &> /dev/null; then
  echo >&2 "error: 'gh' unavailable"
  echo >&2 ""
  echo >&2 "Install gh: https://cli.github.com/"
  echo >&2 ""
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo >&2 "error: 'jq' unavailable"
  echo >&2 ""
  echo >&2 "Install jq: https://jqlang.github.io/jq/download/"
  echo >&2 ""
  exit 1
fi

# Parse arguments
filter="${1:-unresolved}"
pr_number="${2:-}"

# Validate filter argument
valid_filters="unresolved resolved all pr"
if [[ ! " $valid_filters " == *" $filter "* ]]; then
  echo >&2 "error: invalid filter '$filter'"
  echo >&2 "usage: $0 [unresolved|resolved|all|pr] [pr-number]"
  exit 1
fi

# Auto-detect PR number if not provided
if [[ -z $pr_number ]]; then
  current_branch="$(git rev-parse --abbrev-ref HEAD)"
  pr_number="$(
    gh pr list \
      --head "$current_branch" \
      --json number \
      --jq '.[0].number' 2> /dev/null \
    || echo ""
  )"

  if [[ -z $pr_number ]]; then
    echo >&2 "error: Could not auto-detect PR number"
    echo >&2 "usage: $0 [unresolved|resolved|all] <pr-number>"
    exit 1
  fi
fi

# Get repository info
repo="$(gh repo view --json nameWithOwner \
  --jq '.nameWithOwner')"
owner="$(echo "$repo" | cut -d/ -f1)"
repo_name="$(echo "$repo" | cut -d/ -f2)"

echo "Fetching comments for PR #$pr_number in $repo..."
echo ""

# Constants
SEPARATOR="──────────────────────────────────────\
──────────────────────────────────────────"
NON_BOT_FILTER='[.[] | select(.user.type != "Bot")]'

# Create temp directory
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

review_comments_file="$tmpdir/review_comments.json"
issue_comments_file="$tmpdir/issue_comments.json"
review_threads_file="$tmpdir/review_threads.json"
pr_diff_file="$tmpdir/pr.diff"
enhanced_diff_map="$tmpdir/enhanced_diff_map.json"

# Fetch issue comments (main PR thread)
gh api \
  "/repos/$owner/$repo_name/issues/$pr_number/comments" \
  --paginate > "$issue_comments_file"

# Handle "pr" filter - show main thread comments only
if [[ $filter == "pr" ]]; then
  non_bot_comments="$(
    jq "$NON_BOT_FILTER" "$issue_comments_file"
  )"
  comment_count="$(echo "$non_bot_comments" | jq 'length')"

  if [[ $comment_count -eq 0 ]]; then
    echo "No comments on main PR thread."
    exit 0
  fi

  echo "$non_bot_comments" | jq -r \
    --arg sep "$SEPARATOR" '
    .[] |
    $sep + "\n" +
    "💬 \(.user.login) - " +
    "\(.created_at | sub("T"; " ") | sub("Z"; "")):\n" +
    .body + "\n\n" +
    "🔗 \(.html_url)\n"
  '

  echo ""
  echo "$SEPARATOR"
  echo ""
  echo "Total: $comment_count comment(s) on main PR thread"
  exit 0
fi

# Fetch review comments and PR diff
gh api \
  "/repos/$owner/$repo_name/pulls/$pr_number/comments" \
  --paginate > "$review_comments_file"
gh api \
  "/repos/$owner/$repo_name/pulls/$pr_number" \
  -H "Accept: application/vnd.github.v3.diff" \
  > "$pr_diff_file"

# Fetch review threads via GraphQL for resolution status
gh api graphql --paginate -f query="
query {
  repository(owner: \"$owner\", name: \"$repo_name\") {
    pullRequest(number: $pr_number) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          isCollapsed
          isOutdated
          comments(first: 100) {
            nodes {
              id
              databaseId
              body
              author {
                login
              }
            }
          }
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
}" > "$review_threads_file"

# Build comment_id -> thread_info map
thread_map="$(jq '
  .data.repository.pullRequest.reviewThreads.nodes[]
    as $thread |
  $thread.comments.nodes[] |
  {
    id: .databaseId,
    isResolved: $thread.isResolved,
    isOutdated: $thread.isOutdated
  }
' "$review_threads_file" | jq -s 'INDEX(.id)')"

# Build path:line -> enhanced diff context map from the
# full PR diff. Falls back to the API's diff_hunk if the
# hunk is too large or line is missing.
jq -r '
  .[] | select(.path != null) |
  "\(.path):\(.line // .original_line)"
' "$review_comments_file" \
| sort -u \
| while read -r key; do
  file_path="${key%:*}"
  line_num="${key#*:}"

  if [[ $line_num == "null" ]]; then
    continue
  fi

  set +e
  enhanced_context="$(awk \
    -v file="$file_path" -v target_line="$line_num" '
    BEGIN {
      in_file=0; in_hunk=0; found_hunk=0; max_lines=30
    }
    /^diff --git/ {
      if (found_hunk) exit
      in_file=0
      in_hunk=0
    }
    $0 ~ "^diff --git a/" file " b/" file {
      in_file=1; next
    }
    in_file && /^@@/ {
      if (in_hunk) {
        if (found_hunk) exit
        in_hunk=0
      }

      hunk_line = $0
      sub(/.*@@ -/, "", hunk_line)
      sub(/[, ].*/, "", hunk_line)
      old_start = hunk_line + 0

      if ($0 ~ /@@ -[0-9]+,/) {
        hunk_line = $0
        sub(/.*@@ -[0-9]+,/, "", hunk_line)
        sub(/ .*/, "", hunk_line)
        old_count = hunk_line + 0
      } else {
        old_count = 1
      }

      if (target_line >= old_start &&
          target_line <= old_start + old_count) {
        in_hunk=1
        found_hunk=1
        hunk_line_count=0
        print $0
        next
      }
    }
    in_hunk {
      hunk_line_count++
      if (hunk_line_count > max_lines) { exit 1 }
      print $0
    }
  ' "$pr_diff_file")"
  exit_code=$?
  set -e

  if [[ $exit_code -eq 0 && -n $enhanced_context ]]; then
    echo "$key" >> "$enhanced_diff_map.keys"
    echo "$enhanced_context" | jq -Rs . \
      >> "$enhanced_diff_map.values"
  fi
done

# Combine keys and values into a JSON map
if [[ -f "$enhanced_diff_map.keys" ]]; then
  paste "$enhanced_diff_map.keys" "$enhanced_diff_map.values" \
  | jq -R -s '
    split("\n") |
    map(
      select(length > 0) | split("\t") |
      {key: .[0], value: .[1] | fromjson}
    ) | from_entries
  ' > "$enhanced_diff_map"
  rm -f "$enhanced_diff_map.keys" "$enhanced_diff_map.values"
else
  echo "{}" > "$enhanced_diff_map"
fi

# Determine filter value for jq
case "$filter" in
  resolved) filter_resolved="true" ;;
  unresolved) filter_resolved="false" ;;
  all) filter_resolved="null" ;;
esac

# Build and filter threads
threads_json="$(jq \
  --argjson filter_resolved "$filter_resolved" \
  --argjson thread_map "$thread_map" \
  --argjson enhanced_diff "$(cat "$enhanced_diff_map")" '
[
  .[] |
  select(.path != null) |
  {
    id: .id,
    in_reply_to_id: .in_reply_to_id,
    body: .body,
    path: .path,
    line: .line,
    diff_hunk: (
      (.line // .original_line) as $target_line |
      $enhanced_diff[
        (.path + ":" + ($target_line | tostring))
      ] //
      (.diff_hunk | split("\n") |
        if length > 30 then
          (if $target_line then
            [
              (.[0:1][0] // ""),
              "... (context around line " +
                ($target_line | tostring) + ")"
            ] +
            (.[
              ($target_line - 10 |
                if . < 1 then 1 else . end
              ):($target_line + 20)
            ] // .[0:30])
          else
            .[0:30] +
            ["... (truncated, " +
              (length | tostring) + " lines)"]
          end) | join("\n")
        else
          join("\n")
        end
      )
    ),
    user: .user.login,
    created_at: .created_at,
    html_url: .html_url,
    pull_request_review_id: .pull_request_review_id
  } |
  . + {
    isResolved: (
      $thread_map[(.id | tostring)] |
      .isResolved // false
    ),
    isOutdated: (
      $thread_map[(.id | tostring)] |
      .isOutdated // false
    )
  }
] |
group_by(
  if .in_reply_to_id == null then .id
  else .in_reply_to_id end
) |
map({
  root_id: (.[0].in_reply_to_id // .[0].id),
  root_comment: (
    if .[0].in_reply_to_id == null then .[0]
    else null end
  ),
  replies: (
    if .[0].in_reply_to_id != null then .
    else .[1:] end
  ),
  isResolved: .[0].isResolved,
  isOutdated: .[0].isOutdated
}) |
if $filter_resolved == null then .
elif $filter_resolved == true then
  map(select(.isResolved == true))
else
  map(select(.isResolved == false))
end |
sort_by([
  .root_comment.path // "",
  .root_comment.line // 0
])
' "$review_comments_file")"

thread_count="$(echo "$threads_json" | jq 'length')"

if [[ $thread_count -eq 0 ]]; then
  case "$filter" in
    resolved) echo "No resolved review threads found." ;;
    unresolved)
      echo "No unresolved review threads found! 🎉" ;;
    all) echo "No review threads found." ;;
  esac

  issue_count="$(
    jq "$NON_BOT_FILTER | length" "$issue_comments_file"
  )"
  if [[ $issue_count -gt 0 ]]; then
    echo ""
    echo "Note: Main PR thread has" \
      "$issue_count non-bot comment(s)"
    echo "      (use 'just pr-comments pr' to see them)"
  fi
  exit 0
fi

# Display threads
echo "$threads_json" | jq -r --arg sep "$SEPARATOR" '
.[] |
select(.root_comment != null) |

$sep + "\n" +
"📁 \(.root_comment.path):\(.root_comment.line)" +
(if .isResolved then " ✅ RESOLVED"
 else " ⚠️  UNRESOLVED" end) +
(if .isOutdated then " (outdated)" else "" end) +
" [comment_id=\(.root_comment.id)]" + "\n" +
$sep + "\n\n" +
.root_comment.diff_hunk + "\n\n" +
"💬 \(.root_comment.user) - " +
"\(.root_comment.created_at |
  sub("T"; " ") | sub("Z"; "")):\n" +
.root_comment.body + "\n" +
(if (.replies | length) > 0 then
  "\n" +
  (.replies | map(
    "   ↳ \(.user) - " +
    "\(.created_at | sub("T"; " ") | sub("Z"; "")):\n" +
    "   " + (.body | gsub("\n"; "\n   "))
  ) | join("\n\n")) + "\n"
else "" end) +
"\n" +
"🔗 \(.root_comment.html_url)\n"
'

echo ""
echo "$SEPARATOR"
echo ""

# Summary
case "$filter" in
  resolved)
    echo "Total: $thread_count resolved thread(s)" ;;
  unresolved)
    echo "Total: $thread_count unresolved thread(s)" ;;
  all)
    echo "Total: $thread_count thread(s)" ;;
esac

# Show reply instructions
if [[ $thread_count -gt 0 ]]; then
  echo ""
  echo "To reply to a thread, use the comment_id from" \
    "the thread header:"
  echo "  gh api -X POST" \
    "/repos/$owner/$repo_name/pulls/$pr_number" \
    "/comments/COMMENT_ID/replies -f body=\"YOUR_REPLY\""
fi

# Show main thread comments note
issue_count="$(
  jq "$NON_BOT_FILTER | length" "$issue_comments_file"
)"
if [[ $issue_count -gt 0 ]]; then
  if [[ $filter == "all" ]]; then
    echo ""
    echo "Main PR Thread ($issue_count comment(s))"
    echo ""

    jq -r --arg sep "$SEPARATOR" \
      "$NON_BOT_FILTER"' | .[] |
      $sep + "\n" +
      "💬 \(.user.login) - " +
      "\(.created_at |
        sub("T"; " ") | sub("Z"; "")):\n" +
      .body + "\n\n" +
      "🔗 \(.html_url)\n"
    ' "$issue_comments_file"

    echo "$SEPARATOR"
  else
    echo ""
    echo "Note: Main PR thread has" \
      "$issue_count non-bot comment(s)"
    echo "      (use 'just pr-comments pr' to see them)"
  fi
fi
