# Circadian toggle shows when a colour change has paused it

## Why

Setting a colour (by hand, a scene or an effect) pauses circadian until the light next
turns on, but the Circadian Lighting toggle stays Active, so the app can't tell a paused
light from a running one. The toggle should show whether circadian is actually running.

## Approaches

- **A. The toggle follows the pause (picked).** No new control. The toggle now means
  "running now", not "this light uses circadian".
- B. A separate status row under Circadian Range ("Following the sun" or "Paused until
  next turn-on"). Rejected: it adds a row to a screen the user just decluttered.

## Behaviour

- **A colour change pauses circadian:** the toggle flips to Inactive. Nothing changes when
  circadian was already off or already paused.
- **The light turns off:** a paused toggle flips back to Active, because the next turn-on
  resumes circadian. This covers an off from the app and from a wall switch on the bulb's
  Zigbee group.
- **Tapping Active while paused:** circadian resumes now. Today that tap does nothing.
- **A deliberate Inactive** (the toggle, a scene, a routine, or an effect that turns
  circadian off) stays off and never flips back.
- **Turning on a light that's already on:** the toggle stays Active. A turn-on restarts the
  timer without flashing the toggle to Inactive.
- **Driver restart while paused:** the light stays paused and flips back at the next off.
- **Catch, accepted:** to turn circadian off for good on a paused light, tap it on, then off.

## Builder notes

- The pause state already exists: `circadian_session == "ended"`. The internal
  `circadian[device]` field stays "Active" while paused; only the displayed attribute
  changes.
- **`circadian_end_session`** emits Inactive.
- **`on_handler`** stops cancelling the timer through `circadian_end_session`; it cancels it
  directly instead.
- **Both off paths** (`off_handler` and the on/off report) emit Active before arming, but
  only when the session was "ended" and `circadian[device]` is "Active".
- **`circadian_Light_handler`:** the early return lets Active through when the session is
  "ended".
- **`do_init`:** treats a stored Inactive as Active when the session is "ended".
  - Shortcut: an effect that deliberately turns circadian off during a pause, followed by a
    driver restart before the light turns off, would bring circadian back.
  - That's rare enough to leave.
- Update the README and the two code comments that say the control stays Active.
