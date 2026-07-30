# speek

Peek at the last N lines of every GNU `screen` session without attaching to
any of them. Like `tail`, not `tail -f` — a quick snapshot of what each
session is doing right now.

## Installation

```
git clone git@github.com:sullo/speek.git
cd speek
./install.sh
```

This symlinks `speek.sh` to `~/.local/bin/speek` (override with
`PREFIX=/usr/local/bin ./install.sh`) so you can just run `speek` from
anywhere. If `~/.local/bin` isn't on your `PATH` yet, the installer will
tell you the line to add to your `~/.zshrc` / `~/.bashrc`.

Re-run `./install.sh` after a `git pull` — it just re-links, it's a no-op
if nothing changed.

## Usage

```
speek [lines]
```

- `lines` — how many trailing lines to show per session (default: `20`)

```
$ speek 10
===== 86133.ttys006.ranger3 =====
~ this is screen one
zsh: command not found: this
~

===== 86202.ttys006.ranger3 =====
~ this is screen two
```

## How it works

For each session listed by `screen -ls`, it runs:

```
screen -S <session> -X hardcopy -h <tmpfile>
```

which dumps that session's scrollback buffer to a file without attaching or
disturbing it, then trims the blank-line padding `hardcopy` adds and tails
the result. Temp files live under a `mktemp -d` directory that's removed on
exit.

## Notes / limitations

- Sessions that are dead or need multiuser permissions are skipped with a
  note instead of erroring out.
- How far back `hardcopy` can see is limited by that session's scrollback
  buffer size (`scrollback` / `defscrollback` in your `.screenrc`) — if it's
  small, old output may already be gone.
- Requires `screen` to be installed. Only tested against GNU Screen on
  macOS with the system's bash 3.2 (no `mapfile`/bash-4 features used, so
  it should run as-is on most Linux boxes too).

## License

MIT — see [LICENSE](LICENSE).
