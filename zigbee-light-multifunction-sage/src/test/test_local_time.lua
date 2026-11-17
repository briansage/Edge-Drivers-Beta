-- Plain Lua check of UTC offset and US daylight saving. Run from src/: lua test/test_local_time.lua
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
local p = lt.parse_offset
assert(p("m8") == -8, "m prefix is negative")
assert(p("p5") == 5, "p prefix is positive")
assert(p("0") == 0, "zero")
assert(p(nil) == 0, "unset setting")
assert(p("junk") == 0, "unknown key")
print("ok")
