-- Circadian color temperature by local time of day.
-- The sun angle runs 0º at the period start, 90º at its middle and back to 0º at its end;
-- color follows sin(angle) between min and max, interpolated across the hour.

local circadian_color = {}

local function round(x)
  return math.floor(x + 0.5)
end

local function sun_angle(h, start_hour, mid)
  local a = (h - start_hour) / (mid - start_hour)
  if a > 1 then return (2 - a) * 90 end
  return a * 90
end

function circadian_color.kelvin_at(min_k, max_k, start_hour, end_hour, hour, minute)
  if hour == 0 then hour = 24 end
  if hour < start_hour or hour >= end_hour then return min_k end

  local mid = (start_hour + end_hour) / 2
  local function k(h)
    return min_k + (max_k - min_k) * math.sin(math.rad(sun_angle(h, start_hour, mid)))
  end
  local kelvin = math.floor(round(k(hour) + (k(hour + 1) - k(hour)) * minute / 60))
  if kelvin < min_k then kelvin = min_k end
  return kelvin
end

return circadian_color
