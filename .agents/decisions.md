# Decisions

Why the current setup is the way it is. Reverse any of these deliberately.

## Lint gates ratchet against a baseline

`make check` passes at or below `BASELINE` and `FP_BASELINE` rather than at zero.
The whole repo carried 352 luacheck warnings and 4 duplicate fingerprint ids when the
gate was set up. A gate that
starts red stays red and stops being read. The ratchet blocks new problems from
day one and the baselines come down as the backlog does.

A gate that cannot read its input fails. A validator crash, or a `DRIVERS` entry that
does not exist, would otherwise report zero problems and pass.

## The gates cover only the drivers being worked on

`DRIVERS` in the Makefile lists them, and the baselines are measured over that list.
Drivers outside it stay in the repo untouched. Deleting them would make every upstream
change to a deleted driver a modify/delete conflict, and bury real changes in PR diffs.

## luacheck runs with `std = "lua53"` and filters two classes

Verified empirically: under `lua53`, every undefined-global report in this repo is a
genuine question about the code rather than a missing framework symbol. Whitespace
codes are stylua's domain. Unused *arguments* are required by fixed Edge handler
signatures `(driver, device, cmd)`; unused *locals* stay reported.

Filtering took 5,847 warnings to 352.

`cache = false`. luacheck keeps its cache in `~/Library/Caches/Luacheck`, which agent
sandboxes do not allow writes to, so a cached run fails before checking anything.

## stylua runs one file at a time

`stylua --check .` rewrites 449 of 449 files. This is a fork that tracks
`Mariano-Github/Edge-Drivers-Beta`, and small diffs against upstream are what make
changes reviewable and merges land.

## Fingerprint validation is Python 3, stdlib only

Runs on macOS and Windows with no install step. PyYAML is not available without a
venv on an `EXTERNALLY-MANAGED` Python, and Ruby is mise-managed here and absent on
Windows.

The cost is a narrow hand parser. It fails loudly on any shape it does not
recognize, and it was verified at exact parity with a PyYAML-equivalent
implementation: 1,900 entries, 0 dangling references, 4 duplicate ids.

## Agent configuration lives in `.agents/`, invoked through `AGENTS.md`

Roughly half of future contributors use something other than Claude. Skills and
rules as plain documents are readable by any agent that is told to read them, so
`AGENTS.md` carries an explicit trigger table.

Per-tool directories (`.claude/`, `.gemini/`) stay out of the repo. Slash commands
and subagents have no shared path or format across tools, and these directories also
hold personal settings. The trigger table reaches every agent through one file, so a
skill is written once in `.agents/skills/` and needs no adapter.

## Dotfiles are force-added by path

The repo carries no `.gitignore`. Contributors whose global ignore hides dotfiles stage
each one explicitly, which keeps every tracked dotfile a deliberate choice.

## CLAUDE.md carries no unique portable content

`CLAUDE.md` holds only what is specific to Claude Code / Cowork, or what would cause
harm if another agent performed it. Everything else lives in `AGENTS.md`.

In this repo `CLAUDE.md` is a regular file containing `@AGENTS.md`, an import Claude
Code resolves at load time. A symlink checks out on Windows (`core.symlinks=false`) as
a one-line text file holding the target path, and some tools and archive formats drop
or flatten links. An import is plain text and survives every checkout, copy and tool.

Globally, `~/.claude/CLAUDE.md`
keeps skill discovery — the paths are Claude internals and the update step mutates git
working trees — and the required plugin-skill triggers, whose namespaces exist only in
Claude. The rest moved to `~/.claude/AGENTS.md`, loaded by the SessionStart hook.

## Files land when they have content

Empty scaffolding is the failure mode an AGENTS.md linter rewards and a reader
pays for. `.agents/reference/` and `.agents/skills/` fill in as material exists.

## AGENTS.md is written as positive declaratives

Instruction, then stop. The reasoning for a choice belongs in this file, where the
audience is a human deciding whether to reverse it.
