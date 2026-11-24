-- Plain Lua check of the circadian dawn-to-dusk curve. Run from src/: lua test/test_circadian_color.lua
package.path = "./?.lua;" .. package.path
local cc = require("circadian-color")
local w, k = cc.civil_window, cc.kelvin_at

local function near(x, want, label)
  assert(math.abs(x - want) < 0.02, label .. ": got " .. tostring(x))
end

local dawn, dusk = w(0, 79)
near(dawn, 5.600, "equinox dawn")
near(dusk, 18.400, "equinox dusk")
dawn, dusk = w(40, 172)
near(dawn, 3.945, "June dawn at 40N")
near(dusk, 20.055, "June dusk at 40N")
dawn, dusk = w(40, 355)
near(dawn, 6.828, "December dawn at 40N")
near(dusk, 17.172, "December dusk at 40N")
assert(w(-75, 172) == nil, "polar night")
dawn, dusk = w(-75, 355)
assert(dawn == 0 and dusk == 24, "continuous twilight")

assert(k(2700, 5500, 40, 172, 12) == 5500, "noon peak")
assert(k(2700, 5500, 40, 172, 9) == 5034, "June morning")
assert(k(2700, 5500, 40, 355, 9) == 4416, "December morning is warmer")
assert(k(2700, 5500, 40, 172, 18) == 3792, "June evening")
assert(k(2700, 5500, 40, 355, 18) == 2700, "after December dusk holds min")
assert(k(2700, 5500, -35, 355, 18) == 3673, "southern summer evening")
assert(k(2700, 5500, -75, 172, 12) == 2700, "polar night holds min")
assert(k(2700, 5500, -75, 355, 6) == 4680, "continuous twilight spans the day")
assert(k(2700, 5500, 40, 172, 0) == 2700, "midnight holds min")
assert(k(5000, 3000, 40, 172, 12) == 5000, "min above max holds min")
local lo, hi = cc.range("settings", 2500, 6500)
assert(lo == 2500 and hi == 6500, "settings uses min/max")
lo, hi = cc.range("k2700_5000", 2500, 6500)
assert(lo == 2700 and hi == 5000, "preset range")
lo, hi = cc.range(nil, 2500, 6500)
assert(lo == 2700 and hi == 5000, "unset defaults to preset")
print("ok")
