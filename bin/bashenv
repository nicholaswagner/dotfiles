#!/usr/bin/env bash

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <path_to_env_file> [command_to_run]"
    exit 1
fi

ENV_FILE=$1
shift

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: File '$ENV_FILE' not found."
    exit 1
fi

# Function to strip comments while respecting quotes
process_env() {
    while IFS= read -r line || [[ -n "$line" ]]; do
        # 1. Skip empty lines or lines that are just whitespace
        [[ -z "${line// }" ]] && continue

        # 2. Use perl to strip comments.
        # This regex looks for a '#' only if it is NOT followed by an even number of quotes.
        # (i.e., it's outside of a quoted pair)
        clean_line=$(echo "$line" | perl -pe 's/(?<!(["'"'"']))\s*#.*//g')

        # 3. Remove trailing whitespace left after stripping comment
        clean_line="${clean_line%"${clean_line##*[![:space:]]}"}"

        # Output if line is not empty
        if [[ -n "$clean_line" ]]; then
            echo "$clean_line"
        fi
    done < "$ENV_FILE"
}

CLEAN_ENV=$(process_env)

if [ "$#" -eq 0 ]; then
    echo "$CLEAN_ENV"
else
    (
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            export "${line?}"
        done <<< "$CLEAN_ENV"
        exec "$@"
    )
fi