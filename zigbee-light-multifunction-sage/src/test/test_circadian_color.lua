-- Plain Lua check of the circadian sun curve. Run from src/: lua test/test_circadian_color.lua
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
