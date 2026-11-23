-- Circadian color temperature from civil dawn to civil dusk (sun 6º below the horizon).
-- Color follows a half sine between min and max across that window, coolest at solar noon.

local circadian_color = {}

-- Dawn and dusk in local standard-time hours for a latitude and day of year; nil in polar night.
-- shortcut: solar noon is fixed at 12:00 standard time, ignoring longitude within the time
-- zone and the equation of time (up to 16 min); add the equation of time if dusk looks off.
function circadian_color.civil_window(lat, yday)
  local decl = math.rad(-23.44) * math.cos(2 * math.pi / 365 * (yday + 10))
  local phi = math.rad(lat)
  local cos_h = (math.sin(math.rad(-6)) - math.sin(phi) * math.sin(decl)) / (math.cos(phi) * math.cos(decl))
  if cos_h >= 1 then
    return nil
  end
  if cos_h <= -1 then
    return 0, 24
  end
  local half = math.deg(math.acos(cos_h)) / 15
  return 12 - half, 12 + half
end

-- hour is fractional local standard time, e.g. 17.5 for 17:30.
function circadian_color.kelvin_at(min_k, max_k, lat, yday, hour)
  local dawn, dusk = circadian_color.civil_window(lat, yday)
  if not dawn or hour <= dawn or hour >= dusk or max_k <= min_k then
    return min_k
  end
  return math.floor(min_k + (max_k - min_k) * math.sin(math.pi * (hour - dawn) / (dusk - dawn)) + 0.5)
end

return circadian_color
