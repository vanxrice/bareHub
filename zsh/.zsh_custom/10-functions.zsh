# --- Helper Functions ---

# Sourced automatically. General utilities.

# randopen: Opens a random selection of files with a specific extension
# Usage: randopen [count] [extension]
# Example: randopen 3 jpg
randopen() {
  local count=${1:-1}
  local ext=${2:-mp4}

  find . -maxdepth 1 -type f -iname "*.$ext" | awk 'BEGIN{srand()} {print rand() "\t" $0}' | sort -n | cut -f2- | head -n "$count" | xargs -I "{}" open "{}"
}

# eachdir: Executes a given command inside every subdirectory in the current folder
# Usage: eachdir <command> [args...]
# Example: eachdir git pull
eachdir() {
  if [[ -z "$1" ]]; then
    echo "Usage: eachdir <command> [args...]"
    echo "Example: eachdir fixext -e png -p '^[0-9]+$' -d"
    return 1
  fi

  for dir in *(/); do
    echo "\n====> Processing: $dir"
    "$@" "$dir"
  done
}

# organize_by_date: Moves files in the target directory into YYYY-MM-DD subfolders based on creation date
# Usage: organize_by_date [target_dir]
# Example: organize_by_date ~/Downloads
organize_by_date() {
  local target_dir="${1:-.}"
  
  for item in "$target_dir"/*; do
    [[ -e "$item" ]] || continue

    local item_name="${item##*/}"

    # Skip directories that are already formatted as YYYY-MM-DD
    if [[ -d "$item" && "$item_name" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
      continue
    fi

    local date_dir
    # macOS/BSD stat for birth time
    date_dir=$(date -r $(stat -f "%B" "$item") +"%Y-%m-%d" 2>/dev/null)

    if [[ -n "$date_dir" ]]; then
      local target_path="$target_dir/$date_dir/$item_name"
      
      # Check for duplicates before moving
      if [[ -e "$target_path" ]]; then
        echo "Duplicate exists, skipping: $target_path"
      else
        mkdir -p "$target_dir/$date_dir"
        mv "$item" "$target_dir/$date_dir/"
      fi
    fi
  done
  
  echo "Organization complete."
}

