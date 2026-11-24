# Circadian Paused Toggle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Circadian Lighting toggle show Inactive while a colour change has paused
circadian, then Active again once the light turns off.

**Architecture:**
- The pause state already exists as `circadian_session == "ended"`.
- `circadian[device]` stays "Active" while paused; only the emitted
  `legendabsolute60149.circadian` attribute changes.
- One pure predicate in `circadian-session.lua` names the pause. `dimmer.lua` uses it at
  the pause, off, tap and restart points.

**Tech Stack:** Lua 5.3, SmartThings Edge, plain-`lua` tests run by `make test`.

**Spec:** `docs/superpowers/specs/2026-11-24-circadian-paused-toggle-design.md`

## Global Constraints

- Run `make check` after every edit. The lint baseline is 25 warnings and the fingerprint
  baseline is 3.
- Tests may `require` only the driver's own modules.
- Keep diffs against upstream small and scoped to this change.

## Review Focus

- **A routine sends "turn on" to a light that's already on and running:** the toggle must
  not flash Inactive (on_handler path).
- **A second colour change while already paused:** emit nothing new.
- **A colour change when circadian is Inactive:** emit nothing, and never flip back on off.
- **A wall switch on a Zigbee group turns the light off:** the off report path must flip a
  paused toggle back to Active, the same as an app off.
- **Tapping Active while paused with the light off:** the next turn-on must still start
  circadian, which needs the session moved to "armed".

---

### Task 1: Pause predicate

**Files:**
- Modify: `zigbee-light-multifunction-sage/src/circadian-session.lua`
- Test: `zigbee-light-multifunction-sage/src/test/test_circadian_session.lua`

**Interfaces:**
- Produces: `circadian_session.paused(state) -> boolean`, true only for "ended".

- [ ] **Step 1: Add assertions before `print("ok")`**

```lua
-- a color change paused circadian: the toggle shows Inactive until the light turns off
assert(s.paused(s.on_color_set()) == true, "a color change pauses")
assert(s.paused("running") == false and s.paused("armed") == false
  and s.paused("idle") == false and s.paused(nil) == false, "only a color change pauses")
```

- [ ] **Step 2:** Run `make test`. Expected: it fails with "attempt to call a nil value
  (field 'paused')".
- [ ] **Step 3:** Implement `circadian_session.paused(state)` as a one-line function.
- [ ] **Step 4:** Run `make test`. Expected: every test prints `ok`.

### Task 2: Wire the toggle into dimmer.lua

**Files:**
- Modify: `zigbee-light-multifunction-sage/src/dimmer.lua`. The touch points are:
  - `do_init`, at "restart Circadian status".
  - `circadian_Light_handler`.
  - `circadian_end_session`.
  - The on_handler block "circadian is color only".
  - `off_handler`.
  - The on/off report handler's `value.value == false` branch.
  - The comment above the end_session call in the effects handler, near line 690.
- Modify: `zigbee-light-multifunction-sage/README.md`. Add a bullet to the 2026-11-24 entry.

**Interfaces:**
- Consumes: `circadian_session.paused(state)` from Task 1.

- [ ] **Step 1: Add a local helper above `off_handler`**

  `circadian_arm(device)` replaces both `set_field("circadian_session", on_off())` calls in
  the two off paths. Before arming, it emits `circadian_Light.circadian("Active")`, but only
  when `paused(session)` and `circadian[device] == "Active"`.
  - `circadian_arm` is local, so declare it above `off_handler`.
  - The report handler appears later in the file, so it sees the local without a forward
    declaration.

- [ ] **Step 2: Emit Inactive in `circadian_end_session`**

  Emit `circadian_Light.circadian("Inactive")` when `circadian[device] == "Active"` and the
  latest attribute is "Active".

  Split the timer cancel and the `Running = "stopped"` lines into a local
  `circadian_stop_timer(device)`.
  - `circadian_end_session` calls it.
  - The on_handler block calls `circadian_stop_timer(device)` in place of
    `circadian_end_session`, so a turn-on never emits Inactive.

  Update both comments that say the control stays Active.

- [ ] **Step 3: Let Active through while paused in `circadian_Light_handler`**

  Change the early return to
  `if command.args.value == device:get_field("circadian[device]") and not (command.args.value == "Active" and circadian_session.paused(device:get_field("circadian_session"))) then return end`.

  At the top of the Active branch, when paused, set the session to
  `circadian_session.on_off()`, so the next turn-on starts circadian even with the light off.

- [ ] **Step 4: Keep the pause across a restart in `do_init`**

  In the `else` branch, before `set_field("circadian[device]", cap_status)`, treat
  `cap_status == "Inactive"` as "Active" when `paused(session)`. Add this one-line comment:

  ```lua
  -- shortcut: an effect that turns circadian off during a pause, then a restart before the light turns off, brings circadian back; track deliberate offs if that shows up
  ```

- [ ] **Step 5: Add the README bullet**

  Add a **Circadian toggle shows a pause** bullet to the 2026-11-24 entry:
  - A colour change flips it to Inactive.
  - Turning the light off flips it back to Active.
  - Tapping Active resumes circadian now.

- [ ] **Step 6:** Run `make check` and `make test`. Expected: lint is PASS at 25 or fewer
  warnings, fingerprints is PASS at 3 problems, and all tests print `ok`.

- [ ] **Step 7:** Commit Tasks 1 and 2 together: "Show a colour-change pause on the
  Circadian Lighting toggle".

### Task 3: Deploy and check on the hub

- [ ] **Step 1: Deploy**

  Run
  `make deploy DRIVER=zigbee-light-multifunction-sage CHANNEL=be9c9882-28ce-4282-9ea2-8209d573d762 HUB=999f1f47-ddeb-4c85-ae19-ddf5867e5fb3`
  outside the sandbox. Expected: the driver installs on the hub.

- [ ] **Step 2: Check the pause on Tripod lamp**

  Pick an online light that is on and running circadian; Tripod lamp is the example.
  1. Send `colorTemperature:setColorTemperature(4000)`. Expected: the circadian attribute
     becomes "Inactive".
  2. Send `setCircadian("Active")`. Expected: the circadian attribute becomes "Active" and
     `colorTemperature` returns to the curve value within 5 seconds.

- [ ] **Step 3: Check the light the user is in**

  Repeat the colour set, then send `switch:off`. Expected: the circadian attribute becomes
  "Active". Then turn the light back on.
  - Only turn off a light the user isn't sitting under.
  - Restore its previous on/off state afterwards.
