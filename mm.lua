if WebBanking then
    WebBanking {
        version = 1.0,
        url = "https://ana.co.jp",
        description = "ANA Pay Wallet",
        services = { "ANA Pay Wallet" },
    }
end

local M = {}

function M.is_moneymoney()
    if WebBanking then
        return true
    end

    return false
end

function M.parse_json(json_string)
    if JSON then
        -- Use MoneyMoney's JSON object if available
        return JSON(json_string):dictionary()
    else
        -- Fallback to dkjson if JSON is not available
        local dkjson = require("dkjson")
        return dkjson.decode(json_string)
    end
end

function M.stringify_json(lua_table, args)
    if args == nil then args = {} end
    if JSON then
        -- Use MoneyMoney's JSON object if available
        return JSON():set(lua_table):json()
    else
        -- Fallback to dkjson if JSON is not available
        local dkjson = require("dkjson")
        return dkjson.encode(lua_table, args)
    end
end

-- Create a storage object that uses LocalStorage if available, otherwise a regular table
M.Storage = {}

if LocalStorage then
    -- We're in MoneyMoney context, use LocalStorage
    M.Storage = LocalStorage
else
    -- We're not in MoneyMoney, create a table-based storage
    local storageTable = {}
    Storage = {
        -- Getter
        __index = function(_, key)
            return storageTable[key]
        end,
        -- Setter
        __newindex = function(_, key, value)
            storageTable[key] = value
        end
    }
    setmetatable(M.Storage, Storage)
end

-- Example usage
function M.store_value(key, value)
    M.Storage[key] = value
end

function M.get_value(key)
    return M.Storage[key]
end

function M.make_request(url, method, headers, body)
    -- Print all arguments
    print("URL:", url)
    print("Method:", method)
    print("Headers:")
    for k, v in pairs(headers) do
        print("  " .. k .. ": " .. v)
    end

    if Connection then
        -- Use MoneyMoney's Connection object if available
        local connection = Connection()
        local request_method = method:upper()

        -- Make the request
        local content, charset, mimeType, filename, responseHeaders
        if request_method == "GET" then
            content, charset, mimeType, filename, responseHeaders = connection:request(method, url, nil,
                headers["Content-Type"], headers)
        elseif request_method == "POST" then
            content, charset, mimeType, filename, responseHeaders = connection:request(method, url, body,
                headers["Content-Type"], headers)
        else
            error("Unsupported HTTP method: " .. method)
        end

        -- Print all response values
        print("Response Headers:")
        for k, v in pairs(responseHeaders) do
            print("  " .. k .. ": " .. v)
        end
        print("Response Charset:", charset)
        print("Response MIME Type:", mimeType)
        print("Response Filename:", filename)


        -- Extract status code from response headers
        local status = responseHeaders["Status"] or "200"

        return status, responseHeaders, content
    else
        -- Fallback to http_request if Connection is not available
        local http_request = require("http.request")

        local req = http_request.new_from_uri(url)
        req.headers:upsert(":method", method)

        if headers then
            for k, v in pairs(headers) do
                req.headers:upsert(k, v)
            end
        end

        if body then
            req:set_body(body)
        end

        local headers, stream = req:go()
        local body = assert(stream:get_body_as_string())
        local status = headers:get(":status")

        return status, headers, body
    end
end

return M
