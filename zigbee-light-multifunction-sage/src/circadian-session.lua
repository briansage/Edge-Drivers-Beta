-- When circadian may start, kept as a persisted device field so it survives driver restarts.
-- "armed"   the light is off; the next turn-on may start circadian
-- "running" circadian is driving the color
-- "ended"   a color change took over; nothing restarts circadian until the light is off again
-- "idle"    the light came on without circadian (inactive, or a color effect owns the color)

local circadian_session = {}

function circadian_session.on_off() return "armed" end
function circadian_session.on_start() return "running" end
-- a color set pauses circadian only while it is Active; otherwise the state is unchanged
function circadian_session.on_color_set(state, active) return active and "ended" or state end

-- The bulb reported on. Returns the new state and whether to start circadian.
function circadian_session.on_report_on(state, can_run)
  if state ~= "armed" then return state, false end
  if can_run then return "running", true end
  return "idle", false
end

-- Driver restart or a circadian hours change while the light is on. nil covers devices from
-- before this field existed, which resume as they did before.
-- a color change paused circadian until the light next turns off
function circadian_session.paused(state) return state == "ended" end

-- a color effect held circadian: paused it, or owned the color when the light came back on
function circadian_session.held_by_effect(state) return state == "ended" or state == "idle" end

function circadian_session.may_resume(state)
  return state == "running" or state == nil
end

return circadian_session
