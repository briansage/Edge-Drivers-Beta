-- luacheck configuration for SmartThings Edge drivers
--
-- The Edge runtime is sandboxed Lua 5.3. Every SmartThings module (st.capabilities,
-- st.zigbee, st.zwave, ...) is pulled in with require() and is provided by the hub at
-- runtime -- none of it is vendored here and none of it is global, so the stock lua53
-- standard library is the correct baseline. Verified: with std="lua53" the only
-- undefined-global reports in this repo are genuine defects, not framework noise.

std = "lua53"
cache = false

-- Formatting is stylua's job, not luacheck's. Leaving these on buries the ~160
-- substantive findings under ~3,300 whitespace reports.
max_line_length = false

ignore = {
  "611", -- line contains only whitespace
  "612", -- line contains trailing whitespace
  "614", -- trailing whitespace in a comment
}

-- Edge handler signatures are fixed by the framework: zwave/zigbee handlers are always
-- called as (driver, device, cmd) and capability handlers as (driver, device, command).
-- A handler that only needs `device` still has to declare the rest, so an unused
-- argument here is required by the API, not a mistake. Unused *locals* (211) stay on --
-- those are real.
unused_args = false

exclude_files = {
  ".git",
}

-- Driver test files run inside the SmartThings integration_test container, which injects
-- its own harness. They are not run by this lint pass and use a different environment.
files["**/src/test/*.lua"] = {
  std = "+busted",
}

-- UNRESOLVED -- do not uncomment until verified.
--
-- eaton-5-scene-keypad/init.lua calls bit32.replace and bit32.extract with no require.
-- bit32 is a Lua 5.2 library that was REMOVED in 5.3, so under a stock 5.3 std it reads
-- as undefined. Two possibilities, and luacheck cannot distinguish them:
--
--   1. The Edge sandbox injects a bit32 compat shim as a global. Then this is a false
--      positive -- uncomment the line below and the warning goes away.
--   2. It does not. Then that subdriver throws "attempt to index a nil value (global
--      'bit32')" the first time an Eaton 5-scene keypad reports indicator state, and
--      the code below must be rewritten with 5.3 native operators (& | ~ << >>).
--
-- Settle it with one `smartthings edge:drivers:logcat` against a real keypad, or by
-- checking the Edge global environment reference. Leaving the warning visible on
-- purpose so it does not get forgotten.
--
-- globals = { "bit32" }
