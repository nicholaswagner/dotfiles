#!/usr/bin/env bash

# Xcode command line tools ----------------------------------
xcode_gen() {
  if [ ! -f "project.yml" ]; then
    echo "❌ No project.yml found in current directory"
    return 1
  fi
  xcodegen generate
}

xcode_build() {
  local proj
  local scheme
  local build_dir
  proj=$(find . -maxdepth 1 -name "*.xcodeproj" | head -1)
  if [ -z "$proj" ]; then
    echo "❌ No .xcodeproj found in current directory"
    return 1
  fi
  scheme=$(basename "$proj" .xcodeproj)
  build_dir="$(pwd)/.build"
  xcodebuild -project "$proj" \
             -scheme "$scheme" \
             -destination "platform=iOS,name=$IPHONE_NAME" \
             -configuration Debug \
             -derivedDataPath "$build_dir" \
             build
}

xcode_run() {
  local proj
  local scheme
  local build_dir
  local app
  local device_id
  local bundle_id
  proj=$(find . -maxdepth 1 -name "*.xcodeproj" | head -1)
  if [ -z "$proj" ]; then
    echo "❌ No .xcodeproj found in current directory"
    return 1
  fi
  scheme=$(basename "$proj" .xcodeproj)
  build_dir="$(pwd)/.build"

  echo "🔨 Building $scheme..."
  xcodebuild -project "$proj" \
             -scheme "$scheme" \
             -destination "platform=iOS,name=$IPHONE_NAME" \
             -configuration Debug \
             -derivedDataPath "$build_dir" \
             build || return 1

  app=$(find "$build_dir" -name "*.app" ! -path "*.xctest*" | head -1)
  if [ -z "$app" ]; then
    echo "❌ Could not find built .app"
    return 1
  fi

  device_id=$(xcrun devicectl list devices | grep "$IPHONE_NAME" \
    | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}')
  if [ -z "$device_id" ]; then
    echo "❌ Device '$IPHONE_NAME' not found or not connected"
    return 1
  fi

  bundle_id=$(defaults read "$app/Info.plist" CFBundleIdentifier)

  echo "📲 Installing on $IPHONE_NAME..."
  xcrun devicectl device install app --device "$device_id" "$app" || return 1

  echo "🚀 Launching $bundle_id..."
  xcrun devicectl device process launch --device "$device_id" "$bundle_id"
}


# .git/safe ----------------------------------
# Gitsafe strategy for executing scripts located in repo/bin directories https://thoughtbot.com/blog/git-safe
add_git_safe_path() {
  local dir
  local candidate
  dir="$PWD"

  while [ "$dir" != "/" ]; do
    candidate="$dir/.git/safe/../../bin"

    if [ -d "$candidate" ]; then
      case ":$PATH:" in
        *":$candidate:"*) ;;
        *) export PATH="$candidate:$PATH" ;;
      esac
      return
    fi

    dir=$(dirname "$dir")
  done
}

# LM Studio Aliases -------------------------------------

# Loads a model based on the profile name (fast, balanced, quality) defined in the LM_CONFIG JSON file
# defaults to "fast" profile if no argument is provided
lms_load() {
  local profile
  local id
  local ctx
  local ttl
  profile="${1:-fast}"
  id=$(jq -r '.[0] | keys[0]' "$LM_CONFIG")
  ctx=$(jq -r ".[0][keys[0]].${profile}.context_length" "$LM_CONFIG")
  ttl=$(( profile == "quality" ? 3600 : profile == "balanced" ? 1800 : 900 ))
  lms load "$id" --gpu max -c "$ctx" --identifier "lm-${profile}" --ttl "$ttl" -y
}


# Display Banner ----------------------------------
display_banner() {
  clear
  local file="${DOTFILES}/assets/me.ans"
  local bg=$'\e[48;2;192;202;245m'  # matches first row of me.ans
  local reset=$'\e[0m'

  while IFS= read -r line; do
    # Strip ANSI codes to measure visible length
    local visible=$(printf "%s" "$line" | sed 's/\x1b\[[0-9;:]*[a-zA-Z]//g; s/\x1b][^\x07]*\x07//g; s/\x1b.//g')
    local pad=$(( COLUMNS - ${#visible} ))
    (( pad < 0 )) && pad=0
    printf "%s%s%${pad}s%s\n" "$line" "$bg" "" "$reset"
  done < "$file"
}

# ffmpeg color remapping ----------------------------------
# build_remap_filter "OLD:NEW" "OLD:NEW" ...
# Outputs a vf filter string: format=rgb24,geq=...,format=rgb24
build_remap_filter() {
  local r_expr="r(X,Y)" g_expr="g(X,Y)" b_expr="b(X,Y)"

  for pair in "$@"; do
    local old_hex="${pair%%:*}"
    local new_hex="${pair##*:}"
    old_hex="${old_hex#\#}"; new_hex="${new_hex#\#}"

    local or=$((16#${old_hex:0:2})) og=$((16#${old_hex:2:2})) ob=$((16#${old_hex:4:2}))
    local nr=$((16#${new_hex:0:2})) ng=$((16#${new_hex:2:2})) nb=$((16#${new_hex:4:2}))

    local match="eq(r(X,Y),${or})*eq(g(X,Y),${og})*eq(b(X,Y),${ob})"
    r_expr="if(${match},${nr},${r_expr})"
    g_expr="if(${match},${ng},${g_expr})"
    b_expr="if(${match},${nb},${b_expr})"
  done

  echo "format=rgb24,geq=r='${r_expr}':g='${g_expr}':b='${b_expr}',format=rgb24"
}

# Usage: remap_colors input.mkv output.mkv "OLD_HEX:NEW_HEX" ...
remap_colors() {
  local input="$1"
  local output="$2"
  shift 2

  local filter
  filter="$(build_remap_filter "$@")"

  ffmpeg -i "$input" -vf "$filter" -c:v ffv1 -pix_fmt rgb24 "$output"
}

# Set terminal window title ----------------------------------
window-title() { echo -ne "\033]0;${1}\007"; }


# Notify terminal of working directory (OSC 7) ----------------------------------
_osc7_cwd() {
  printf '\033]7;file://%s%s\007' "$HOST" "${PWD// /%20}"
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _osc7_cwd
_osc7_cwd


# ANSII color audit --------------------------------
ansi_audit() {
    if [ -z "$1" ]; then
        echo "Usage: ansi_audit <filename>"
        return 1
    fi

    echo "--- Auditing Colors in: $1 ---"

    # Use perl to find unique 256-color IDs and loop through them to print previews
    echo "Unique 256-color IDs used in the file:"
    perl -ne 'while(/\e\[[0-9;]*[38|48];5;(\d+)m/g){print "$1\n"}' "$1" | sort -u | while read -r id; do
        printf "ID %3d: \e[48;5;%sm  \e[0m  " "$id" "$id"
    done

    echo -e "\n\nUnique RGB 24-bit colors used in the file:"
    perl -ne 'while(/\[([\d;]+)m/g){print "$1\n"} END{}' "$1" | sort -u

    echo -e "\n-----------------------------"
}

# Get a page's HTML and convert to markdown using html-to-markdown CLI tool
# Usage: get-page-markdown <URL> --full --extras --with-images
get-page-markdown() {

  if [ -z "$1" ]; then
    echo "Usage: get-page-markdown <URL>"
    return 1
  fi

  # if --full is passed, include all content; otherwise, use aggressive preset to strip boilerplate
  local preset="aggressive"
  if [[ "$*" == *"--full"* ]]; then
    preset="none"
  fi

  # if --extras is passed, include the --with-metadata and --extract-document options to preserve more content and metadata
  local -a extras=()
  if [[ "$*" == *"--extras"* ]]; then
    extras+=(--with-metadata --extract-document)
  fi

  # strip images by default; pass --with-images to include them
  if [[ "$*" != *"--with-images"* ]]; then
    extras+=(--strip-tags "img,video,audio,iframe,picture,svg,object,embed")
  fi

  html2md \
    --url "$1" \
    --preprocess \
    --preset "$preset" \
    "${extras[@]}" \
    | tee >(pbcopy) \
    | cat -n

}


# Workflows ------------------------------------
# when you have a script that runs and you just want an easy way to 
# iterate on it over and over again until you're satisfied.
function do-it-live(){
  local command="$1"
  local extensions
  
  shift
  
  if [ $# -gt 0 ]; then
    # Use IFS to join all remaining arguments with a comma
    extensions=$(IFS=,; echo "$*")
    nodemon -e "$extensions" --exec "$command"
  else
  nodemon --exec "$command"
  fi
}

# Storytime ------------------------------------
# have Siri read your ClaudeCode session logs to you (and save the recordings)
# //note:  jq -r --unbuffered '.message | select(.role == "assistant") | .content[] | select(.type == "text") | .text' | while read -r line; do echo "$line"; say "$line" 0 "$line".wav; done
function cc-storytime(){
  local input_path="$1"
  local abs_input=$(realpath "$input_path")
  local base_name=$(basename "$abs_input")
  
  local output_dir="$PWD/.claudio"
  local log_prefix="${base_name:0:8}"
  local log_file="${output_dir}/${log_prefix}.log"
  
  local i=0 
  
  mkdir -p "$output_dir"
  touch "$log_file"
  echo "[ info ] Logging to: $log_file"

  # -n +1 for starting at line 1 and go forward from there
  # -n 1 shows the very last line of the log and goes forward from there aka "hot" log

  stdbuf -oL tail -n 1 -f "$abs_input" | stdbuf -oL jq -r --unbuffered '
    .message | select(.role == "assistant") | .content[] | select(.type == "text") | .text
  ' | while read -r line; do
    # Skip if line is empty or only whitespace
    if [[ -n "${line// /}" ]]; then
        ((i++))
        local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
        local out_file="${output_dir}/${timestamp}_${i}.aiff"

        # Log to file
        printf "\n[%s] %s\n%s\n" "$timestamp" "$out_file" "$line" >> "$log_file"

        # Output to terminal
        echo "---"
        echo "$line"

        # Audio
        say -- "$line"
        say -o "$out_file" -- "$line"
    fi
  done
}