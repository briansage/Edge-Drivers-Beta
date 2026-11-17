# Circadian Color Only Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Circadian in `zigbee-light-multifunction-sage` shifts color temperature by time of day while the light is on, and never changes brightness.

**Architecture:** The sun-curve math moves out of `dimmer.lua` into a pure module, `circadian-color.lua`, so plain `lua` can test it. Mariano's `circadian_handler` keeps its name and timer, but only sends color. Start and end hooks go into the existing on, off, report and color handlers. Profiles drop the three brightness settings and get new defaults.

**Tech Stack:** Lua 5.3 (SmartThings Edge), YAML device profiles, the SmartThings CLI, `make check` / `make deploy`.

**Spec:** `docs/superpowers/specs/2026-11-17-circadian-color-only-design.md`

## Global Constraints

- All paths are under `zigbee-light-multifunction-sage/`. No other driver changes.
- Profiles use CRLF line endings. Edit with `open(path, newline="")` or an equivalent, and check `git diff --stat` shows only the intended lines.
- `make check` passes after every task, at or below `BASELINE := 30` and `FP_BASELINE := 3`.
- Keep Mariano's names and structure. Change what the spec needs and nothing else.
- Brian's lamp (`b0ba98bd-4429-4af0-a514-c71337e54702`) is the only device on this driver, and the only one to send test commands to.
- Defaults: `colorTempMinim` 2700; `colorTempMaxim` 5500, or the profile's maximum where lower (4000 in both `*-2200-4000` profiles, 5000 in `level-colorTemp-2700-5000`); `limitColorTemp` true.

## Review Focus

- **Periodic on reports.** A bulb reports `on` every 5 minutes. A report while already on must not restart a session that a color change ended. Task 3 starts circadian only on an off→on transition.
- **Paddle turn-on.** A switch bound to the bulb's Zigbee group turns it on without the hub. The on report must start circadian. Task 3.
- **Time zone.** The hub clock is UTC (verified 2026-11-17), and the offset defaults to 0, so circadian hours are UTC until the offset is set. Brian is UTC−8. Until Task 5, set his lamp's `localTimeOffset` to −8. After Task 5, set `utcOffset` to −8 and `usDaylightSaving` on. Task 5's tests pin the hours either side of each daylight-saving switch.
- **Start hour after end hour** (e.g. 20 → 6). Today's math never treats that as inside the hours, so the light holds the minimum. Keep that and pin it in Task 1's test, so it doesn't crash.
- **Min at or above max.** The curve can't go below min, so the light holds min. Pin it in Task 1's test.

---

### Task 1: Pure sun-curve module with a test

**Files:**
- Create: `src/circadian-color.lua`
- Create: `src/test/test_circadian_color.lua`
- Modify: `Makefile` (add a `test` target)

**Interfaces:**
- Produces: `circadian_color.kelvin_at(min_k, max_k, start_hour, end_hour, hour, minute) -> integer`. `hour` is 0–23 local time and `minute` is 0–59. It returns `min_k` outside `start_hour <= hour < end_hour`.

- [ ] **Step 1: Write the failing test** `src/test/test_circadian_color.lua`. It's plain Lua that runs with `lua` from `src/`, with no SmartThings libraries.

```lua
package.path = "./?.lua;" .. package.path
local cc = require "circadian-color"
local k = cc.kelvin_at
assert(k(2700, 5500, 6, 18, 6, 0) == 2700, "sunrise")
assert(k(2700, 5500, 6, 18, 12, 0) == 5500, "noon")
assert(k(2700, 5500, 6, 18, 9, 0) == 4680, "mid-morning")
assert(k(2700, 5500, 6, 18, 17, 30) == 3062, "late afternoon interpolates")
assert(k(2700, 5500, 6, 18, 20, 0) == 2700, "after end holds min")
assert(k(2700, 5500, 6, 18, 0, 15) == 2700, "midnight holds min")
assert(k(2700, 5500, 20, 6, 22, 0) == 2700, "start after end holds min")
assert(k(5000, 3000, 6, 18, 12, 0) == 5000, "min above max holds min")
print("ok")
```

- [ ] **Step 2: Run it and confirm it fails.**
Run: `cd zigbee-light-multifunction-sage/src && lua test/test_circadian_color.lua`
Expected: `module 'circadian-color' not found`.

- [ ] **Step 3: Implement `kelvin_at` in `src/circadian-color.lua`.** This moves the existing math from `circadian_handler` (`dimmer.lua:1508-1760`) without changing it:

```lua
-- hour 0 is treated as 24, as in the original
local function sun_angle(h, start_hour, mid)
  local a = (h - start_hour) / (mid - start_hour)
  if a > 1 then return (2 - a) * 90 end
  return a * 90
end
-- inside hours: mid = (start+end)/2
-- k(h) = min + (max - min) * sin(rad(sun_angle(h)))
-- result = floor(round(k(hour) + (k(hour+1) - k(hour)) * minute / 60)), clamped to >= min
```

Return `min_k` when the hour is outside the period. Use a local `round` (`math.floor(x + 0.5)`), since `st.utils` isn't available to the test.

- [ ] **Step 4: Run the test and confirm it passes.**
Run: `cd zigbee-light-multifunction-sage/src && lua test/test_circadian_color.lua`
Expected: `ok`

- [ ] **Step 5: Add `make test` to the Makefile.** For each driver in `DRIVERS`, run every `src/test/test_*.lua` with `lua` from that driver's `src/` directory, and fail if any exits non-zero. Add it to `.PHONY` and to `help`. Don't add it to `check`, because the other drivers' integration tests need `lua_libs`.
Run: `make test`. Expected: `ok`.

- [ ] **Step 6: `make check`, then commit.**

```bash
git add zigbee-light-multifunction-sage/src/circadian-color.lua zigbee-light-multifunction-sage/src/test/test_circadian_color.lua Makefile
git commit -m "Move the circadian sun curve into a testable module"
```

### Task 2: Color-only circadian handler

**Files:**
- Modify: `src/dimmer.lua:1508-1760` (`driver_handler.circadian_handler`)
- Modify: `src/dimmer.lua` (add `driver_handler.circadian_end_session` next to it)

**Interfaces:**
- Consumes: `circadian_color.kelvin_at` (Task 1).
- Produces: `driver_handler.circadian_handler(self, device)`, the same name as today, and `driver_handler.circadian_end_session(driver, device)`. The latter cancels the `"timer_circadian"` field's timer, clears the field, and sets `circadian_Running[device]` and its field to `"stopped"`. It leaves `circadian[device]` and the capability unchanged.

- [ ] **Step 1: Rewrite `circadian_handler` to send color only.**
  - Compute the local time with `os.date("%H")` and `os.date("%M")` at `os.time() + localTimeOffset * 3600`.
  - Get the kelvin from `kelvin_at(colorTempMinim, colorTempMaxim, circadianTimeStart or 6, circadianTimeEnd or 18, hour, minute)`.
  - Set `LAST_KELVIN_SET .. "main"`.
  - Send `MoveToColorTemperature(device, round(1e6 / kelvin), tempTransTime * 10)` to component `main`.
  - Keep the 2 s delayed `ColorTemperatureMireds` read.
  - Set `circadian_Running` to `"running"`.
  - If `"timer_circadian"` is nil, schedule `call_on_schedule(300, …)` that repeats the same compute-and-send, and store it in that field.
  - Send no Level command and no On command, don't touch `last_Level`, and don't branch on `circadianNightSetting`. Outside hours, `kelvin_at` already returns min.

- [ ] **Step 2: Add `circadian_end_session`** as specified in Interfaces.

- [ ] **Step 3: `make check`.** Expected: PASS, with warnings at or below 30.

- [ ] **Step 4: Deploy and verify on the lamp.**
  - Run `make deploy DRIVER=zigbee-light-multifunction-sage`.
  - Set the lamp's `localTimeOffset` to −8 in the app, or ask Brian to.
  - Turn the circadian control on, then send `smartthings devices:commands b0ba98bd-4429-4af0-a514-c71337e54702 switch:off`, then `switch:on`.
  - After 5 s, `devices:status` should show `colorTemperature` equal to `kelvin_at` for the current local time, within 50K, and `level` unchanged from before `off`.

- [ ] **Step 5: Commit** `dimmer.lua` with the message "Make circadian change color only".

### Task 3: Start and end hooks

**Files:**
- Modify: `src/dimmer.lua:1948` and `:1986` (`on_handler`)
- Modify: `src/dimmer.lua:2296` (`on_off_attr_handler`)
- Modify: `src/dimmer.lua:1262-1265` (`level_Steps_handler`), `:678-683` (`color_Changing_handler`)
- Modify: `src/init.lua:109` (`set_color_Temperature_handler`)
- Modify: `src/mirror-groups.lua:97` (`color_control_handler`), `:182` (`set_color_handler`)

**Interfaces:**
- Consumes: `dimmer.circadian_handler`, `dimmer.circadian_end_session` (Task 2). `init.lua` and `mirror-groups.lua` already require `dimmer`.

- [ ] **Step 1: Make turn-on normal, then start circadian.**
  - In `on_handler:1948`, remove `circadian[device] == "Inactive"` from the condition, so the normal turn-on (last level, forced level, `onTransTime`) runs whether circadian is on or not.
  - Turn the `elseif circadian[device] == "Active"` branch at `:1986` into a separate `if` after that chain. It should cancel any existing circadian timer, then call `circadian_handler`.
  - Progressive on and circadian already deactivate each other, so they're never both Active.
- [ ] **Step 2: Start on a bulb-reported turn-on.** In `on_off_attr_handler`, when `value.value == true`, capture the switch's latest state *before* the existing `emit_event_for_endpoint`. If it was `"off"`, `circadian[device] == "Active"`, and `"timer_circadian"` is nil, call `circadian_handler` after the emit. Leave the off branch as it is; it already ends the session.
- [ ] **Step 3: End the session on color changes.** Call `dimmer.circadian_end_session(driver, device)` at the top of:
  - `set_color_Temperature_handler` (`init.lua:109`)
  - `mirror_groups.color_control_handler` (`mirror-groups.lua:97`)
  - `mirror_groups.set_color_handler` (`mirror-groups.lua:182`)

  In `color_Changing_handler` (`dimmer.lua:678-683`), replace the block that deactivates circadian with that call. The colour-temperature and hue step handlers already stop the session; leave them.
- [ ] **Step 4: Stop brightness steps ending circadian.** Delete the `circadian_Running` stop block at `level_Steps_handler` (`dimmer.lua:1262-1265`).
- [ ] **Step 5: `make check`.** Expected: PASS.
- [ ] **Step 6: Deploy and verify on the lamp,** with the circadian control on.
  - Send `switch:on`, then `colorTemperature:setColorTemperature 4500`. After 5 minutes, `colorTemperature` should still be 4500.
  - Send `switch:off`, then `switch:on`. After 5 s, the color should be back on the curve.
  - Send `switchLevel:setLevel 40`. After 5 minutes, the level should still be 40 and the color should still follow the curve.
  - Ask Brian to run Good Morning, and watch `smartthings edge:drivers:logcat f422303e-42dd-478d-a348-c701d8f0a196 --hub 999f1f47-ddeb-4c85-ae19-ddf5867e5fb3` in a terminal. Brightness should end at 33% and color at 4500K.
- [ ] **Step 7: Commit** with the message "Start circadian on turn-on and end it on color changes".

### Task 4: Profiles

**Files:**
- Modify: the 11 profiles under `profiles/` that contain `circadLevelMin`

- [ ] **Step 1: Edit the profiles.**
  - Remove the `circadLevelMin`, `circadLevelMax` and `circadianNightSetting` blocks.
  - Set the defaults from Global Constraints.
  - Set the `hdrCircadian` description to `"Color follows the time of day. Min and max also limit color commands"`.
- [ ] **Step 2: Verify the edit.**
  - Run `grep -c 'circadLevel\|circadianNightSetting' zigbee-light-multifunction-sage/profiles/*.yml`. Expected: 0 for every file.
  - Check that `git diff --stat` touches only those 11 files.
  - Run `make check`. Expected: PASS.
- [ ] **Step 3: Deploy, then read the lamp's preferences.** The three settings should be gone. `colorTempMaxim` should be 5500 and `limitColorTemp` true, if those were never changed on the lamp.
- [ ] **Step 4: Commit** with the message "Drop circadian brightness settings and set color defaults".

### Task 5: UTC offset selector with US daylight saving

**Files:**
- Create: `src/local-time.lua`
- Create: `src/test/test_local_time.lua`
- Modify: `src/dimmer.lua`, everywhere it reads `localTimeOffset`. Today that's `:1115`, `:1139`, `:2360` and the circadian time lines from Task 2.
- Modify: the 14 profiles that contain `localTimeOffset`

**Interfaces:**
- Produces:
  - `local_time.offset_seconds(offset_hours, us_dst, utc_now) -> integer`. It returns `offset_hours * 3600`, plus 3600 inside the US daylight-saving window when `us_dst` is true.
  - `local_time.for_device(device) -> integer`. It returns `os.time()` plus `offset_seconds(tonumber(device.preferences.utcOffset) or 0, device.preferences.usDaylightSaving == true, os.time())`. It's the local "epoch" to pass to `os.date` without `!`, because the hub clock is UTC.

- [ ] **Step 1: Write the failing test** `src/test/test_local_time.lua`. It's plain Lua, run from `src/` like Task 1's test.

```lua
package.path = "./?.lua;" .. package.path
local lt = require "local-time"
local o = lt.offset_seconds
local H = 3600
assert(o(-8, false, 1794900410) == -8 * H, "no DST in November")
assert(o(-8, true, 1772963999) == -8 * H, "2026-03-08 09:59:59Z, before spring forward")
assert(o(-8, true, 1772964000) == -7 * H, "2026-03-08 10:00:00Z, PDT starts")
assert(o(-8, true, 1793523599) == -7 * H, "2026-11-01 08:59:59Z, still PDT")
assert(o(-8, true, 1793523600) == -8 * H, "2026-11-01 09:00:00Z, PST again")
assert(o(-8, true, 1805018400) == -7 * H, "2027-03-14 10:00:00Z, next spring")
assert(o(-5, true, 1772964000 - 3 * H) == -4 * H, "Eastern switches 3 hours earlier in UTC")
assert(o(5, false, 1772964000) == 5 * H, "positive offsets work")
assert(o(0, false, 0) == 0, "default offset")
print("ok")
```

- [ ] **Step 2: Run it and confirm it fails.**
Run: `cd zigbee-light-multifunction-sage/src && lua test/test_local_time.lua`
Expected: `module 'local-time' not found`.

- [ ] **Step 3: Implement `src/local-time.lua`.**
  - Get the year from `os.date("!*t", utc_now).year`.
  - Build UTC epochs with a pure days-from-civil calculation (Howard Hinnant's `days_from_civil`), not `os.time(table)`. `os.time(table)` uses the machine's own time zone, and the test runs on a Mac.
  - Day 0 (1970-01-01) is a Thursday, so the weekday with 0 = Sunday is `(days + 4) % 7`.
  - The window starts at the second Sunday in March at 02:00 standard time (UTC = 02:00 − offset), and ends at the first Sunday in November at 02:00 daylight time (UTC = 01:00 − offset).
  - `for_device` reads the settings exactly as in Interfaces.

- [ ] **Step 4: Run the test and confirm it passes.**
Run: `make test`. Expected: `ok` from both test files.

- [ ] **Step 5: Use it everywhere.** Replace each `os.time() + device.preferences.localTimeOffset * 3600` with `local_time.for_device(device)`. In the random-timer lines, keep the `+ random_timer[device]`.
  The circadian minutes line used `os.time() + localTimeOffset` without `* 3600`. That's a typo in the original, harmless only because offsets are whole hours. It also becomes `for_device(device)`.
  Afterwards, `grep -n localTimeOffset zigbee-light-multifunction-sage/src` must print nothing.

- [ ] **Step 6: Swap the setting in all 14 profiles.** Replace the `localTimeOffset` block, keeping its place under BASICS, with:
  - `utcOffset`: `preferenceType: enumeration`, title `"UTC Offset (hours)"`, description `"Hours from UTC to your standard time, e.g. -8 for US Pacific"`, options `"-23"` through `"23"` labelled the same (`"0"` for zero), default `"0"`.
  - `usDaylightSaving`: `preferenceType: boolean`, title `"Automatically adjust for daylight saving time (US)"`, description `"Adds an hour from the second Sunday in March to the first Sunday in November. Leave off where clocks don't change, such as Arizona and Hawaii"`, default `false`.

  Keep CRLF line endings. `grep -c localTimeOffset` must print 0 for every profile.

- [ ] **Step 7: `make check`, then deploy and verify on the lamp.**
  - Set `utcOffset` to −8 and `usDaylightSaving` on.
  - Send `switch:off`, then `switch:on`.
  - `colorTemperature` should equal `kelvin_at` for Brian's current local time.
  - Turn random on/off on, then off again. Its next-change time should show local time.

- [ ] **Step 8: Commit** with the message "Replace the manual time offset with a UTC offset and US daylight saving".
