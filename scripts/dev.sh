#!/usr/bin/env python3
"""
dev — watch files and re-run a command on change.

Usage:
  dev [-e EXTS] [-w PATH ...] [--env PATH] -- <command> [args...]

Examples:
  dev -e py,lua -- python foo.py
  dev -w src/main.py -w config.toml -- ./run.sh
  dev -e ts,tsx --env .env.local -- bun run build

Runs `bunx nodemon` under the hood. When --env is given, the command is
invoked through `bashenv` so dotenv vars are exported into its environment.
"""

import argparse
import os
import shlex
import sys


def split_on_double_dash(argv):
    try:
        i = argv.index("--")
    except ValueError:
        return argv, []
    return argv[:i], argv[i + 1:]


def main():
    left, cmd = split_on_double_dash(sys.argv[1:])

    parser = argparse.ArgumentParser(
        prog="dev",
        description="Watch files and re-run a command on change.",
        usage="dev [-e EXTS] [-w PATH ...] [--env PATH] -- <command> [args...]",
    )
    parser.add_argument("-e", "--ext", help="comma-separated extensions to watch in .")
    parser.add_argument("-w", "--watch", action="append", default=[],
                        help="specific file or directory to watch (repeatable)")
    parser.add_argument("--env", dest="env_file",
                        help="dotenv file to export into the command's environment")
    args = parser.parse_args(left)

    if not args.ext and not args.watch:
        parser.error("at least one of -e/--ext or -w/--watch is required")

    if not cmd:
        parser.error("a command after `--` is required")

    if args.env_file and not os.path.isfile(args.env_file):
        print(f"dev: env file not found: {args.env_file}", file=sys.stderr)
        sys.exit(1)

    exec_parts = cmd
    if args.env_file:
        exec_parts = ["bashenv", args.env_file, *cmd]
    exec_string = shlex.join(exec_parts)

    nodemon = ["bunx", "nodemon", "--quiet"]
    for path in args.watch:
        nodemon += ["--watch", path]
    if args.ext:
        nodemon += ["--ext", args.ext]
        if not args.watch:
            nodemon += ["--watch", "."]
    if args.env_file:
        nodemon += ["--watch", args.env_file]
    nodemon += ["--exec", exec_string]

    os.execvp(nodemon[0], nodemon)


if __name__ == "__main__":
    main()
