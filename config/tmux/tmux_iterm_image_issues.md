# Terminal Graphics Debugging: iTerm2 + Tmux Passthrough

## The Problem
When sending iTerm2 Inline Image Protocol (1337) sequences through a `tmux` session via a script, the image fails to render on the first try, renders partially, or is immediately cleared by the shell prompt. Standard text commands like `ls -lah` appeared to "prime" the terminal, allowing subsequent attempts to work.

## The Solution: "The Hardware Handshake"
The terminal emulator, tmux, and the shell prompt exist in a race condition. The solution is to force a hardware-level synchronization using a Device Status Report (cursor query) to ensure the image is fully rendered before the script exits.

### The Golden Script (`gen_img`)
```bash
#!/usr/bin/env bash

# CONFIG
IMG_HEIGHT=10
IMG_WIDTH=20

# 1. THE HARDWARE PRIME
# A silent 'ls' ensures the TTY is in an active, initialized state.
ls -lah > /dev/null

# 2. PREP DATA
# Generate payload, double-escape for tmux passthrough, and strip newlines.
# Ensure 'chafa' is installed (brew install chafa)
/opt/homebrew/bin/chafa --size ${IMG_WIDTH}x${IMG_HEIGHT} --format iterm "$1" > /tmp/raw_img.bin
perl -pe 's/\e/\e\e/g; s/\n//g' /tmp/raw_img.bin > /tmp/wrapped_img.bin

# 3. THE HANDSHAKE SEND
# Disable echo so the terminal's 'receipt' is invisible to the user.
stty -echo
{
  printf "\033Ptmux;"
  cat /tmp/wrapped_img.bin
  printf "\033\\"
  # The Barrier: 'Report Cursor Position' query
  printf "\033[6n"
} > /dev/tty

# 4. CONSUME THE RECEIPT
# The script blocks here until the terminal confirms it has processed 
# all preceding bytes (the image).
read -s -d "R" TEMP_VAR
stty echo

# 5. DYNAMIC ANCHOR
# Push the prompt down so it doesn't overlap the rendered image.
for i in $(seq 1 $((IMG_HEIGHT + 1))); do printf "\n"; done

---

Technical Root Cause Analysis
1. The Gatekeeper (Tmux)
Tmux restricts DCS (Device Control String) passthrough for security. It often ignores these sequences unless the TTY has seen "Standard" interactive output. This is why ls -lah (which prints text) "woke up" the terminal while printf from a script did not.

2. The Buffer (The Pipe)
The data transfer rate of a script is faster than the terminal's rendering engine. Without a "wait" command, the script finishes and closes the stream while the terminal is still halfway through the image scanlines, leading to truncation.

3. The Janitor (The Shell)
Modern shell prompts (Zsh/Fish) often run a cleanup sequence or a "clear-to-end-of-screen" command when a process finishes. This wipes the image from the frame buffer immediately after it appears.


---


GitHub Issue Report (Draft)
Title: iTerm2 Graphics (1337) sequences truncated/cleared when run via script in tmux

Summary: When sending iTerm2 Inline Image Protocol sequences (1337) within a tmux session via a shell script, the image fails to render or is immediately cleared upon script exit. This occurs unless a "hardware handshake" (e.g., querying cursor position \033[6n and waiting for a response) is used to force the terminal to synchronize before the process terminates.

Environment:

iTerm2 Version: [User to Fill]

OS: macOS [User to Fill]

Tmux Version: [User to Fill]

Terminal $TERM: screen-256color or tmux-256color

Observed Behavior:
The terminal emulator seems to require "standard" TTY activity to "prime" the graphics layer. Without a blocking read (like waiting for a Device Status Report \033[6n), the DCS passthrough sequence is treated as lower priority than the shell's return-to-prompt sequence, leading to truncation.

Current Workaround:
Implement a blocking handshake:

Send DCS image sequence.

Send \033[6n.

Use read to wait for the terminal's response before exiting.