# Agent Instructions

Fork of `Mariano-Github/Edge-Drivers-Beta`. A collection of SmartThings Edge driver
packages in Lua.

## Agent configuration

`.agents/` holds everything any agent can use. `AGENTS.md` is the index; read the file
a trigger names before doing that work.

| Trigger | Read |
|---|---|
| Adding or changing a fingerprint, or choosing a device profile | `.agents/rules/fingerprints.md` |
| Changing the lint gates, formatting, or agent layout | `.agents/decisions.md` |

`.agents/skills/` holds procedures invoked by a trigger in the table above.
`.agents/reference/` holds material consulted on demand.

Keep this table current. Adding a file under `.agents/` means adding its trigger here,
in the same change.

## Verification

Run `make check` after every edit. It passes when counts stay at or below the
baselines in the Makefile and there are no syntax errors.

```
make check         # the gate: lint + fingerprints
make lint-signal   # undefined globals, shadowing, dead branches
make lint-summary  # counts by warning code
make fingerprints  # fingerprints.yml against profiles
```

Both gates ratchet against a baseline in the Makefile. Lower `BASELINE` and
`FP_BASELINE` whenever a count drops, to lock the gain in.

Driver tests under `src/test/` run in the SmartThings integration_test container.
`make check` is the local gate.

Configuration lives in `.luacheckrc`. The Edge runtime is sandboxed Lua 5.3 and every
`st.*` module arrives via `require` at runtime, so `std = "lua53"` is the baseline.
Whitespace codes and unused arguments are filtered; framework handler signatures are
fixed at `(driver, device, cmd)`.

## Formatting

Format one file at a time, as part of work you are already doing in it:

```
make fmt-check FILE=path/to/file.lua
stylua path/to/file.lua
```

Settings in `stylua.toml` match the repo's existing style: 2-space indent, 120 columns,
double quotes.

## Tooling

| Tool | Version | Purpose |
|---|---|---|
| `luacheck` | 1.2.0 | static analysis, wired to `make lint` |
| `stylua` | 2.5.2 | single-file formatting |
| `smartthings` | 2.1.2 | packaging, channels, hub install, logs |

Installed via Homebrew. The SmartThings CLI comes from the official
`smartthingscommunity/smartthings` tap.

## SmartThings CLI

Authentication is implicit: the first command needing it opens a browser.

Use non-interactive flags. Every command needed for deployment accepts them:

```
smartthings edge:channels:create --input channel.json
smartthings edge:drivers:package <dir> --channel <id> --hub <id>
```

`smartthings edge:drivers:logcat` streams from the hub and belongs in a real terminal.

An unrecognized subcommand surfaces as a `TypeError: ... 'isAxiosError' in undefined`
stack trace. Read it as "no such command" and check `smartthings --help`.

## Account facts

- Capability namespace: `watchangel42614`, owner type `organization`.
- Custom capabilities under `legendabsolute60149.*` are readable across accounts and
  resolve from this fork's profiles as written. Forking one into `watchangel42614.*`
  is required only to change its definition.
- Deployment targets a channel owned by this account, with the hub enrolled in it.

## Git

Remotes: `origin` is the fork, `upstream` is `Mariano-Github/Edge-Drivers-Beta`. Keep
diffs against upstream small and scoped to the change at hand.

Global `~/.gitignore` may ignore dotfiles. Stage each dotfile that belongs in version
control by its exact path: `git add -f .luacheckrc`. Once tracked, it stays tracked.

## Known and Accepted Open items — *edit this list as open items are addressed*

- `eaton-5-scene-keypad/init.lua` calls `bit32.replace` and `bit32.extract`. Confirm the
  Edge runtime provides `bit32` via `logcat` against real hardware, then either add it to
  `globals` in `.luacheckrc` or rewrite with Lua 5.3 operators (`& | ~ << >>`).
- `aeotec-nano-shutter/init.lua:60` declares `basic_report_handler` at global scope. Add
  `local`, and reference it through the subdriver's handler table.
- `zwave-smoke-alarm/src/init.lua:70` passes `self` to `update_preferences`. Pass `driver`,
  matching the call at line 91.
