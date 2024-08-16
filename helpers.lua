local M = {}

M.debug = false

function M.print(message, ...)
    local formatted_message = "[anapay] " .. tostring(message)
    print(formatted_message, ...)
end

function M.debug_print(message, ...)
    if M.debug then
        M.print(message, ...)
    end
end

function M.print_env()
    -- Debug: Print Lua version
    M.debug_print("Lua version:", _VERSION)

    -- Debug: Print updated package path
    M.debug_print("package.path:", package.path)
    M.debug_print("package.cpath:", package.cpath)
end

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
