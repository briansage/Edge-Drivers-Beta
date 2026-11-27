-- Plain Lua check of when circadian may start. Run from src/: lua test/test_circadian_session.lua
package.path = "./?.lua;" .. package.path
local s = require "circadian-session"

-- paddle turn-on: off report, then on report starts circadian
local state, start = s.on_report_on(s.on_off(), true)
assert(start == true and state == "running", "paddle turn-on starts circadian")

-- color set while off: the color handler turns the light on; its on report must not start circadian
state, start = s.on_report_on(s.on_color_set("armed", true), true)
assert(start == false and state == "ended", "color set while off is not overridden")

-- routine on + color: on_handler starts, color ends, the late on report must not restart
assert(s.on_start() == "running", "on_handler starts circadian")
state, start = s.on_report_on(s.on_color_set("armed", true), true)
assert(start == false and state == "ended", "routine on + color keeps the color")

-- periodic on report while running does not restart
state, start = s.on_report_on("running", true)
assert(start == false and state == "running", "periodic report while running")

-- turned on while circadian can't run (inactive or an effect owns the color): later reports stay idle
state, start = s.on_report_on(s.on_off(), false)
assert(start == false and state == "idle", "on without circadian")
state, start = s.on_report_on(state, true)
assert(start == false and state == "idle", "periodic report after idle")

-- driver restart or hours change: resume only a run that was going
assert(s.may_resume("running") == true, "resume a running session")
assert(s.may_resume(nil) == true, "devices from before this field resume as before")
assert(s.may_resume("ended") == false, "a color change survives a restart")
assert(s.may_resume("armed") == false, "an off light does not resume")

-- a color change paused circadian: the toggle shows Inactive until the light turns off
assert(s.paused(s.on_color_set("armed", true)) == true, "a color change pauses")
-- circadian off: a color set does not pause it, so a restart never turns circadian on
assert(s.on_color_set("armed", false) == "armed" and s.on_color_set("running", false) == "running", "no pause when circadian is off")
assert(s.paused("running") == false and s.paused("armed") == false
  and s.paused("idle") == false and s.paused(nil) == false, "only a color change pauses")

-- a restart ends an effect: hand back to circadian if the effect held it, including a light turned off and on mid-effect
assert(s.held_by_effect(s.on_color_set("armed", true)) == true, "an effect that paused circadian")
assert(s.held_by_effect(s.on_report_on(s.on_off(), false)) == true, "light turned off and on during the effect")
assert(s.held_by_effect("running") == false and s.held_by_effect("armed") == false
  and s.held_by_effect(nil) == false, "nothing else gets the handoff")
print("ok")
