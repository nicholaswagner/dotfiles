#!/usr/bin/env bash

# Define the style mapping using an associative array
declare -A ANSI_STYLES=(
    [reset]="0"
    [bold]="1"
    [dim]="2"
    [italic]="3"
    [underline]="4"
    [blink]="5"
    [reverse]="7"
    # foreground
    [red]="31"
    [green]="32"
    [yellow]="33"
    [blue]="34"
    [magenta]="35"
    [cyan]="36"
    [white]="37"
    # background
    [bg:black]="40"
    [bg:red]="41"
    [bg:green]="42"
    [bg:yellow]="43"
    [bg:blue]="44"
    [bg:magenta]="45"
    [bg:cyan]="46"
    [bg:white]="47"
)

function supports_color() {
    [[ -t 1 && -z "${NO_COLOR:-}" ]]
}

function style_codes() {
    local codes=""
    for arg in "$@"; do
        if [[ $arg == \#* ]]; then
            codes+="38;2;$(hex_to_decimal "$arg" | awk '{print $1";"$2";"$3}');"
        elif [[ $arg == bg:\#* ]]; then
            codes+="48;2;$(hex_to_decimal "${arg#bg:}" | awk '{print $1";"$2";"$3}');"
        elif [[ -n "${ANSI_STYLES[$arg]:-}" ]]; then
            codes+="${ANSI_STYLES[$arg]};"
        fi
    done
    printf '%s' "${codes%;}"
}

# Converts #RRGGBB to decimal R, G, B components
function hex_to_decimal() {
    local hex=${1#\#}
    printf '%s\n' "$((16#${hex:0:2})) $((16#${hex:2:2})) $((16#${hex:4:2}))"
}

# Standard formatting function (from previous step)
function txt() {
    local text="$1"; shift
    local codes
    codes="$(style_codes "$@")"

    if [[ -z "$codes" ]] || ! supports_color; then
        printf '%b\n' "$text"
    else
        printf '\033[%sm%b\033[0m\n' "$codes" "$text\e[0m"
    fi
}

# --- The Gradient Function ---
# Usage: gradient \"Text to color" "#StartHex" "#EndHex" [optional_styles...]
function gradient_txt() {
    local text="$1"
    local start_hex="$2"
    local end_hex="$3"
    shift 3
    local extra_styles=("$@")

    # Convert hex to decimal components
    read -r r1 g1 b1 <<< "$(hex_to_decimal "$start_hex")"
    read -r r2 g2 b2 <<< "$(hex_to_decimal "$end_hex")"

    local len=${#text}
    local result=""

    # Build a prefix from extra styles so they survive the per-char reset
    local style_prefix=""
    for style in "${extra_styles[@]}"; do
        if [[ $style == bg:\#* ]]; then
            style_prefix+="48;2;$(hex_to_decimal "${style#bg:}" | awk '{print $1";"$2";"$3}');"
        elif [[ -n "${ANSI_STYLES[$style]}" ]]; then
            style_prefix+="${ANSI_STYLES[$style]};"
        fi
    done

    # If text is 1 char long, avoid division by zero
    local steps=$(( len > 1 ? len - 1 : 1 ))

    local ratio r g b r_int g_int b_int
    for (( i=0; i<len; i++ )); do
        ratio=$(echo "scale=4; $i / $steps" | bc -l)

        r=$(echo "$r1 + ($r2 - $r1) * $ratio" | bc -l)
        g=$(echo "$g1 + ($g2 - $g1) * $ratio" | bc -l)
        b=$(echo "$b1 + ($b2 - $b1) * $ratio" | bc -l)

        r_int=$(printf "%.0f" "$r")
        g_int=$(printf "%.0f" "$g")
        b_int=$(printf "%.0f" "$b")

        result+="\e[${style_prefix}38;2;$r_int;$g_int;${b_int}m${text:$i:1}\e[0m"
    done

    echo -e "$result"
}

# --- EXAMPLES ---

# clear
# # 1. Simple Cyan to Magenta gradient
# gradient_txt "Electric Cyberpunk" "#00FFFF" "#FF00FF" "bold" "underline"
# echo ""

# # 2. Sunset gradient_txt (Orange -> Red -> Purple)
# gradient_txt "Golden Sunset" "#FFD700" "#FF4500" "italic"
# echo ""

# # 3. Ocean/Deep Sea (Blue -> Green)
# gradient_txt "Deep Sea Depths" "#0000FF" "#00FF00" "underline"
# echo ""

# # 4. Fire/Heat (Red -> Yellow)
# gradient_txt "🔥 Inferno 🔥" "#FF0000" "#FFFF00" "bold" "blink"
# echo ""

# # 5. Standard monochrome test to ensure nothing is broken
# txt "Standard Green Text" "green"
# txt "Bold Standard Green Text" "green" "bold"
# echo ""

# # 6. Named background color
# txt "  Black text on white background  " "#000000" "bg:#ffffff"
# txt "  Bold black text on white background  " "#000000" "bg:#ffffff" "bold"
# echo ""

# # 7. Hex foreground + hex background
# txt "Hot pink on dark teal" "#FF69B4" "bg:#003333" "bold"
# echo ""

# # 8. Gradient with a hex background
# gradient_txt "Gradient on dark bg" "#00FFFF" "#FF00FF" "bold" "bg:#1a1a2e"
