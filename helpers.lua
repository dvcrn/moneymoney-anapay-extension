local M = {}

function M.datetime_to_timestamp(datetime)
    if type(datetime) == "number" then
        datetime = tostring(datetime)
    end

    local pattern = "(%d%d%d%d)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d)"
    local year, month, day, hour, minute, second = datetime:match(pattern)

    -- Convert to numbers
    year, month, day, hour, minute, second = tonumber(year), tonumber(month), tonumber(day), tonumber(hour),
        tonumber(minute), tonumber(second)

    -- Create a timestamp using os.time
    local timestamp = os.time({ year = year, month = month, day = day, hour = hour, min = minute, sec = second })

    return timestamp
end

return M
