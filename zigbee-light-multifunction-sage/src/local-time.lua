-- Local time for a hub whose clock runs on UTC, from a fixed offset plus optional
-- US daylight saving (second Sunday in March to first Sunday in November, 2:00 local).

local local_time = {}

-- Days since 1970-01-01 for a civil date (Howard Hinnant's algorithm). Pure arithmetic,
-- so it does not depend on the machine's time zone the way os.time(table) does.
local function days_from_civil(y, m, d)
  if m <= 2 then y = y - 1 end
  local era = (y >= 0 and y or y - 399) // 400
  local yoe = y - era * 400
  local doy = (153 * ((m + 9) % 12) + 2) // 5 + d - 1
  local doe = yoe * 365 + yoe // 4 - yoe // 100 + doy
  return era * 146097 + doe - 719468
end

-- Day of month of the nth Sunday.
local function nth_sunday(year, month, n)
  local weekday = (days_from_civil(year, month, 1) + 4) % 7 -- 0 = Sunday; 1970-01-01 was a Thursday
  return 1 + (7 - weekday) % 7 + 7 * (n - 1)
end

function local_time.offset_seconds(offset_hours, us_dst, utc_now)
  local offset = offset_hours * 3600
  if not us_dst then return offset end
  local year = os.date("!*t", utc_now).year
  local starts = days_from_civil(year, 3, nth_sunday(year, 3, 2)) * 86400 + 2 * 3600 - offset
  local ends = days_from_civil(year, 11, nth_sunday(year, 11, 1)) * 86400 + 2 * 3600 - (offset + 3600)
  if utc_now >= starts and utc_now < ends then return offset + 3600 end
  return offset
end

-- Setting keys must match ^\w+$, so -8 is stored as "m8" and +5 as "p5".
function local_time.parse_offset(key)
  local sign, hours = tostring(key):match("^([mp]?)(%d+)$")
  if not hours then return 0 end
  return sign == "m" and -tonumber(hours) or tonumber(hours)
end

-- The current local time as an epoch to pass to os.date without "!".
function local_time.for_device(device)
  local now = os.time()
  return now + local_time.offset_seconds(local_time.parse_offset(device.preferences.utcOffset),
    device.preferences.usDaylightSaving == true, now)
end

return local_time
