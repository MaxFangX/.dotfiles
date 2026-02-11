#!/usr/bin/env just --justfile

# Fetch and display PR review comments (filter: unresolved|resolved|all|pr)
pr-comments *args:
    ./just/pr-comments.sh {{ args }}

# Format this justfile
just-fmt:
    just --fmt --unstable

# Remove trailing spaces from all files
remove-trailing-spaces *ARGS:
    #!/usr/bin/env bash
    set -euo pipefail

    check_mode=false
    if [[ "{{ARGS}}" == *"--check"* ]]; then
        check_mode=true
    fi

    # Find all text files, excluding git directory and binary files
    files=$(find . -type f -not -path "./.git/*" -not -path "./target/*" -not -path "./node_modules/*" -not -path "./.cargo/*" | while read -r file; do
        # Check if it's a text file (not binary)
        if file "$file" | grep -q "text\|ASCII\|script"; then
            echo "$file"
        fi
    done)

    if $check_mode; then
        # Check mode: find files with trailing spaces
        files_with_trailing_spaces=""
        for file in $files; do
            if grep -q '[[:space:]]$' "$file" 2>/dev/null; then
                files_with_trailing_spaces="$files_with_trailing_spaces$file\n"
            fi
        done

        if [ -n "$files_with_trailing_spaces" ]; then
            echo "Files with trailing spaces:"
            echo -e "$files_with_trailing_spaces"
            echo ""
            echo "Run 'just remove-trailing-spaces' to fix these files."
            exit 1
        else
            echo "No trailing spaces found."
            exit 0
        fi
    else
        # Fix mode: remove trailing spaces
        fixed_count=0
        for file in $files; do
            if grep -q '[[:space:]]$' "$file" 2>/dev/null; then
                echo "Fixing: $file"
                sed -i '' 's/[[:space:]]*$//' "$file"
                ((fixed_count++))
            fi
        done

        if [ $fixed_count -eq 0 ]; then
            echo "No trailing spaces found to remove."
        else
            echo ""
            echo "Removed trailing spaces from $fixed_count file(s)."
        fi
    fi