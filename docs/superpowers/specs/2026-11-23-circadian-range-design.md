# Circadian range selector

Driver: `zigbee-light-multifunction-sage`. Size: a small change.

## Intent

An audit of the 33 Zigbee colour lights showed every one is rated to 2700–6500K on white
LEDs (Third Reality 28, innr 4, LEDVANCE strip 1), but the per-bulb Min/Max settings
vary (2500–6500, 2700–6500, 2700–5500), so lights in the same room sit at different
colours. Brian wants circadian to run 2700–5000K everywhere: 2700 stays on the white
LEDs of every brand, and he dislikes 6500 at midday. He wants it as a quick choice on
the device screen, directly under the Circadian Lighting control, so one scene can set
the whole house.

## Approaches

- **Main-screen selector (chosen).** A new custom capability shown as a list under
  Circadian Lighting. Scenes and routines can set it on every light at once. Needs a
  capability registered in the `watchangel42614` namespace.
- **Preset setting in Settings.** Smaller, no new capability, but routines can't set
  preferences, so it means 33 trips into settings.

Within the selector, a list beat a switch: it names the range in use and takes another
preset later as one more option.

## Behavior

- New capability `watchangel42614.circadianRange`: attribute `circadianRange`, command
  `setCircadianRange`. Two values, shown as **2700–5000K** and **Use settings
  (Min/Max)**.
- Presentation: a `list` in the detail view labelled "Circadian Range", plus automation
  action and condition entries so scenes and routines can set and test it.
- **2700–5000K:** the circadian curve runs between 2700 and 5000. **Use settings:** it
  runs between `colorTempMinim` and `colorTempMaxim`, as today.
- Changing the range while the light is on and circadian is running re-sends the colour
  right away, as changing Circadian Location does.
- The choice survives hub and driver restarts.
- The Min/Max settings keep limiting colour commands from the app either way.
- Mirror-group devices forward the choice to their members, the way they forward the
  Circadian Lighting control.

## Profiles

Added directly after `legendabsolute60149.circadian` in every profile that has both
circadian and `colorTemperature`. Profiles without colour temperature don't get it.

## Calls left to the builder (mine, flag if wrong)

- **Default is 2700–5000K.** A light that has never been set uses 2700–5000K, so the
  whole house switches on deploy with no scene needed.
- The value keys are `k2700_5000` and `settings`; only the labels show in the app.

## Non-goals

- No other presets yet.
- No change to the Min/Max settings or their defaults.
- No scene is created; Brian can make one, or ask.

## Delivery

Branch `briansage/circadian-range` from `main`, a PR for review. Registering the
capability and its presentation in the account happens before deploy, as part of this
change. README gets a dated entry.
