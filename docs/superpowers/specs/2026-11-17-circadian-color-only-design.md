# Circadian color only

Driver: `zigbee-light-multifunction-sage`. Size: a small change.

## Intent

Brian likes the driver's time-of-day color shifts but not the brightness changes
that come with them. Circadian should shift color temperature only, and leave
brightness to switches, routines and the app.

## Behavior

Circadian runs only while the device's circadian control (`legendabsolute60149.circadian`)
is Active.

- **Starts when the light turns on.** That includes an on command from the hub and a
  bulb reporting on after a switch bound to its Zigbee group turned it on. The light
  goes to the current time-of-day color, then follows the sun curve every 5 minutes.
- **Color moves use the bulb's `tempTransTime` fade**, instead of the 0 transition used
  today.
- **Inside the circadian hours** (`circadianTimeStart`–`circadianTimeEnd`), color follows
  the existing sine curve between `colorTempMinim` and `colorTempMaxim`.
- **Outside the circadian hours**, the light holds `colorTempMinim`.
- **Never touches brightness.** No level command is sent, and `last_Level` is left alone.
- **Ends when the light turns off,** whether by command or by a bulb report.
- **Ends when the color is set** by setColorTemperature, setColor, color-temperature or
  hue steps, or a color effect. Ending stops the timer for the current on-period only;
  the circadian control stays Active, and the next turn-on starts circadian again.
- **Level changes no longer end circadian.** Level steps end it today only because
  level was coupled to color.

## Settings (all 14 profiles with circadian)

- Remove `circadLevelMin`, `circadLevelMax` and `circadianNightSetting`, which would no
  longer do anything.
- `colorTempMinim` defaults to 2700.
- `colorTempMaxim` defaults to 5500, or to the profile's maximum where that is lower
  (4000 in the two 2200–4000 profiles, 5000 in `level-colorTemp-2700-5000`).
- `limitColorTemp` defaults to true, so color commands are clamped to the min/max.
- `circadianTimeStart` stays 6 and `circadianTimeEnd` defaults to 20 (was 18).

## Local time

The hub clock runs on UTC: on 2026-11-17, `os.date("%H")` and `os.date("!%H")` both gave
07:26:50 at 07:26:50Z. The driver has to turn UTC into local time itself.

- Replace the `localTimeOffset` setting (integer, −12 to 12) with `utcOffset`, a selector
  from −23 to +23 hours, default 0, whose labels are just the numbers.
- Add `usDaylightSaving` (on/off, default off), titled "Automatically adjust for daylight
  saving time (US)". Places without daylight saving, such as Arizona and Hawaii, leave
  it off. When it's on, add one hour from 2:00
  local time on the second Sunday in March to 2:00 local time on the first Sunday in
  November.
- Circadian, random on/off and the signal-metrics timestamp all use this.
- Existing bulbs lose their old manual offset. Brian's lamp is the only bulb on this
  driver, and its offset is 0.

## Approaches

- **A. Change Mariano's circadian code in place (chosen).** Remove the level math and
  sends from `circadian_handler`, and add the start and end hooks to the existing
  handlers. It is the smallest diff, and keeps his structure so his fixes still merge.
- **B. A new color-only module beside his.** Cleaner and testable on its own, but it
  still hooks the same handlers and duplicates the sun curve.

## Left to the builder

- Where exactly to hook the on-report start, so a run already started by an on
  command is not started twice.
- How a routine's turn-on followed by a color set settles. The circadian color is sent
  first, then the routine's color ends circadian. Verify on Brian's lamp with logcat.

## Non-goals

- A separate circadian brightness feature.
- Changing the circadian control into a new capability.
- Changes to Mariano's other features (progressive on/off, random, effects) beyond
  making their color changes end circadian.
