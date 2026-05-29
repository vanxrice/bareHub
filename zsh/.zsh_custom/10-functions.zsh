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
  
  if [[ ! -d "$target_dir" ]]; then
    echo "Error: '$target_dir' is not a directory."
    return 1
  fi

  # Prevent 'no matches found' errors in Zsh if the directory is empty
  local -a items
  if [[ -n "$ZSH_VERSION" ]]; then
    items=( "$target_dir"/*(N) )
  else
    items=( "$target_dir"/* )
  fi

  # If glob returned literal pattern (Bash empty directory fallback)
  if [[ ${#items[@]} -eq 1 && ! -e "${items[1]}" ]]; then
    echo "Directory is empty."
    return 0
  fi

  for item in "${items[@]}"; do
    [[ -e "$item" ]] || continue

    local item_name="${item##*/}"

    # Skip directories that are already formatted as YYYY-MM-DD
    if [[ -d "$item" && "$item_name" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
      continue
    fi

    # Skip all other directories to avoid sweeping custom folders.
    if [[ -d "$item" ]]; then
      continue
    fi

    local birth_time=0
    local date_dir=""

    # 1. Attempt to get birth/creation time
    if [[ "$OSTYPE" == "darwin"* ]]; then
      birth_time=$(stat -f "%B" "$item" 2>/dev/null || echo 0)
    else
      local raw_birth
      raw_birth=$(stat -c "%w" "$item" 2>/dev/null || echo "-")
      if [[ "$raw_birth" != "-" && "$raw_birth" != "0" ]]; then
        birth_time=$(date -d "$raw_birth" +"%s" 2>/dev/null || echo 0)
      fi
    fi

    # 2. Fallback to modification time if birth time is 0 or unavailable
    if [[ -z "$birth_time" || "$birth_time" -eq 0 ]]; then
      if [[ "$OSTYPE" == "darwin"* ]]; then
        birth_time=$(stat -f "%m" "$item" 2>/dev/null || echo 0)
      else
        birth_time=$(stat -c "%Y" "$item" 2>/dev/null || echo 0)
      fi
    fi

    # 3. Format the date
    if [[ "$birth_time" -gt 0 ]]; then
      if [[ "$OSTYPE" == "darwin"* ]]; then
        date_dir=$(date -r "$birth_time" +"%Y-%m-%d" 2>/dev/null)
      else
        date_dir=$(date -d "@$birth_time" +"%Y-%m-%d" 2>/dev/null)
      fi
    fi

    # Ultimate fallback to current date if everything else fails
    if [[ -z "$date_dir" ]]; then
      date_dir=$(date +"%Y-%m-%d")
    fi

    local target_path="$target_dir/$date_dir/$item_name"
    
    # Move item if no duplicate exists
    if [[ -e "$target_path" ]]; then
      echo "Duplicate exists, skipping: $target_path"
    else
      mkdir -p "$target_dir/$date_dir"
      mv "$item" "$target_dir/$date_dir/"
    fi
  done
  
  echo "Organization complete."
}

