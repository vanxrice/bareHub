# --- Helper Functions ---

# Sourced automatically. General utilities.

randopen() {
  local count=${1:-1}
  local ext=${2:-mp4}

  find . -maxdepth 1 -type f -iname "*.$ext" | awk 'BEGIN{srand()} {print rand() "\t" $0}' | sort -n | cut -f2- | head -n "$count" | xargs -I "{}" open "{}"
}

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

knew() {
  local n="${1:-5}"
  local pat="${2:-*.{png,jpg,jpeg,gif,webp,svg}}"
  # If user passed plain ext like "png", convert to glob
  if [[ "$pat" != *"*"* && "$pat" != *"{"* && "$pat" != *","* ]]; then
    pat="*.${pat}"
  fi

  # Use brace expansion if available, otherwise fallback
  local -a candidates=()
  if [[ "$pat" == *"{"*"}"* ]]; then
    eval "candidates=( $pat )"
  else
    for f in $pat; do
      [ -f "$f" ] && candidates+=("$f")
    done
    if [ ${#candidates[@]} -eq 0 ] && [[ "$pat" == "*."* || "$pat" == "*"{* ]]; then
      for ext in png jpg jpeg gif webp svg; do
        for f in *."$ext"; do
          [ -f "$f" ] && candidates+=("$f")
        done
      done
    fi
  fi

  if [ ${#candidates[@]} -eq 0 ]; then
    echo "knew: no matches for pattern '$pat' in $(pwd)"; return 1
  fi

  # Get mtimes (macOS stat) and sort newest first
  IFS=$'\n' sorted=( $(for f in "${candidates[@]}"; do
    mtime=$(stat -f %m -- "$f" 2>/dev/null || stat -c %Y -- "$f" 2>/dev/null)
    printf '%s\t%s\n' "$mtime" "$f"
  done | sort -rn -k1,1 | awk -F'\t' '{print $2}' | head -n "$n") )
  unset IFS

  if [ ${#sorted[@]} -eq 0 ]; then
    echo "knew: no files after sorting"; return 1
  fi

  printf 'knew: showing %d file(s):\n' "${#sorted[@]}"
  for x in "${sorted[@]}"; do printf '%s\n' "$x"; done

  if command -v kitty &>/dev/null; then
    kitty +kitten icat --transfer-mode=stream --clear "${sorted[@]}"
  else
    # Fallback to standard open command on non-Kitty systems
    open "${sorted[@]}"
  fi
}
