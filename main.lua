if WebBanking then
    WebBanking {
        version = 1.0,
        url = "https://ana.co.jp",
        description = "ANA Pay Wallet",
        services = { "ANA Pay Wallet" },
    }
end

-- Debug: Print Lua version
print("Lua version:", _VERSION)

local luarocks_prefix = "./.luarocks"
package.path = luarocks_prefix .. "/share/lua/5.4/?.lua;" .. luarocks_prefix ..
    "/share/lua/5.1/?/init.lua;" .. package.path
package.cpath = luarocks_prefix .. "/lib/lua/5.4/?.so;" .. package.cpath

-- Debug: Print updated package path
print("package.path:", package.path)
print("package.cpath:", package.cpath)

local function is_moneymoney()
    if WebBanking then
        return true
    end

    return false
end

local function datetime_to_timestamp(datetime)
    if type(datetime) == "number" then
        datetime = tostring(datetime)
    end

    local pattern = "(%d%d%d%d)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d)"
    local year, month, day, hour, minute, second = datetime:match(pattern)
    -- Convert to numbers
    year, month, day, hour, minute, second = tonumber(year), tonumber(month), tonumber(day), tonumber(hour),
        tonumber(minute), tonumber(second)

    -- Convert date and time to timestamp
    local time = os.time { year = year, month = month, day = day, hour = hour, min = minute, sec = second }
    return time
end

local function parse_json(json_string)
    if JSON then
        -- Use MoneyMoney's JSON object if available
        return JSON(json_string):dictionary()
    else
        -- Fallback to dkjson if JSON is not available
        local dkjson = require("dkjson")
        return dkjson.decode(json_string)
    end
end

local function stringify_json(lua_table, args)
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
local Storage = {}

if LocalStorage then
    -- We're in MoneyMoney context, use LocalStorage
    Storage = LocalStorage
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
    setmetatable(Storage, Storage)
end

-- Example usage
local function store_value(key, value)
    Storage[key] = value
end

local function get_value(key)
    return Storage[key]
end

local function make_request(url, method, headers, body)
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
        print("Response Status:", status)
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

local function login(anaWalletId, deviceId)
    local url = "https://teikei1.api.mkpst.com/ana/accounts/login"
    local headers = {
        ["host"] = "teikei1.api.mkpst.com",
        ["accept"] = "application/json",
        ["user-agent"] = "ANAMileage/4.31.0 (jp.co.ana.anamile; build:4; iOS 18.1.0) Alamofire/5.9.1",
        ["accept-language"] = "ja-JP;q=1.0, en-AU;q=0.9, de-JP;q=0.8",
        ["content-type"] = "application/json"
    }
    local body = {
        ["anaWalletId"] = anaWalletId,
        ["deviceId"] = deviceId
    }

    local status, responseHeaders, content = make_request(url, "POST", headers, stringify_json(body))

    local response = parse_json(content)
    local result = {
        emailAuthenticated = response.emailAuthenticated,
        loginAuthId = response.loginAuthId,
        accessToken = response.accessToken,
        tokenType = response.tokenType,
        expiresIn = response.expiresIn,
        refreshToken = response.refreshToken,
        scope = response.scope
    }

    return result
end

local function getAccounts(accessToken)
    local url = "https://teikei1.api.mkpst.com/accounts?balanceReferenceFlag=1&nfcStatusReferenceFlag=1"
    local headers = {
        ["host"] = "teikei1.api.mkpst.com",
        ["accept"] = "application/json",
        ["user-agent"] = "ANAMileage/4.31.0 (jp.co.ana.anamile; build:4; iOS 18.1.0) Alamofire/5.9.1",
        ["authorization"] = "Bearer " .. accessToken,
        ["accept-language"] = "ja-JP;q=1.0, en-AU;q=0.9, de-JP;q=0.8",
        ["content-type"] = "application/json"
    }

    local status, responseHeaders, content = make_request(url, "GET", headers)

    local response = parse_json(content)
    local result = {
        allianceId = response.allianceId,
        referenceNumber = response.referenceNumber,
        accountStatus = response.accountStatus,
        balance = response.balance,
        mainPaymentSourceId = response.mainPaymentSourceId,
        creditCardInfo = response.creditCardInfo,
        bankPayInfo = response.bankPayInfo,
        pointInfo = response.pointInfo,
        nfcRegisterStatus = response.nfcRegisterStatus,
        serviceRegisterStatus = response.serviceRegisterStatus,
        bankpayFirstAuthFlag = response.bankpayFirstAuthFlag
    }

    return result
end


local function getTransactions(accessToken, pageNumber, pageSize)
    pageNumber = pageNumber or 1
    pageSize = pageSize or 999

    local url = "https://teikei1.api.mkpst.com/salesDetails?pageSize=" ..
        pageSize .. "&pageNumber=" .. pageNumber .. "&historyType=&settlementType="
    local headers = {
        ["host"] = "teikei1.api.mkpst.com",
        ["accept"] = "application/json",
        ["user-agent"] = "ANAMileage/4.31.0 (jp.co.ana.anamile; build:4; iOS 18.1.0) Alamofire/5.9.1",
        ["authorization"] = "Bearer " .. accessToken,
        ["accept-language"] = "ja-JP;q=1.0, en-AU;q=0.9, de-JP;q=0.8",
        ["content-type"] = "application/json"
    }

    local status, responseHeaders, content = make_request(url, "GET", headers)

    local response = parse_json(content)
    local result = {}
    for _, transaction in ipairs(response.history) do
        table.insert(result, {
            saleDatetime = transaction.saleDatetime,
            settlementType = transaction.settlementType,
            dealType = transaction.dealType,
            delKbn = transaction.delKbn,
            descriptionType = transaction.descriptionType,
            shopName = transaction.shopName,
            amount = transaction.amount,
            walletSettlementNo = transaction.walletSettlementNo,
            walletSettlementSubNo = transaction.walletSettlementSubNo,
            pointConversionAmount = transaction.pointConversionAmount
        })
    end

    return result
end


-- Ininal API request

function SupportsBank(protocol, bankCode)
    print("SupportsBank " .. protocol .. " " .. bankCode)
    return protocol == ProtocolWebBanking and bankCode == "ANA Pay Wallet"
end

function InitializeSession(protocol, bankCode, username, reserved, password)
    -- Login.
    print("InitializeSession args:")
    print("protocol:", protocol)
    print("bankCode:", bankCode)
    print("username:", username)
    print("reserved:", reserved)
    print("password:", password)

    result = login(username, password)
    print(stringify_json(result, { indent = true }))

    store_value("accessToken", result.accessToken)
end

function ListAccounts(knownAccounts)
    print("list account")
    print("knownAccounts:") -- Return array of accounts.
    print(stringify_json(knownAccounts))

    local accessToken = get_value("accessToken")
    local accounts = getAccounts(accessToken)

    local account = {
        name = "ANA Pay",
        accountNumber = accounts.referenceNumber,
        currency = "JPY",
        balance = accounts.balance,
        type = AccountTypeCreditCard
    }

    store_value("account", account)
    return { account }
end

function RefreshAccount(account, since)
    print("refresh account")
    print(stringify_json(account))
    print("since " .. since) -- format: 8/11/2024

    local accessToken = get_value("accessToken")
    local account = get_value("account")

    --if account == nil then
    --    print("No account")
    local accounts = getAccounts(accessToken)
    account = {
        name = "ANA Pay",
        accountNumber = accounts.referenceNumber,
        currency = "JPY",
        balance = accounts.balance,
        type = AccountTypeCreditCard
    }
    --end

    print("Account")
    print(stringify_json(account, { indent = true }))


    local transactions = {}
    local page = 1
    local hasMore = true
    while hasMore do
        local result = getTransactions(accessToken, page)
        if #result == 0 then
            hasMore = false
        else
            for _, transaction in ipairs(result) do
                if datetime_to_timestamp(transaction.saleDatetime) < since then
                    hasMore = false
                    break
                end
                table.insert(transactions, transaction)
            end
            page = page + 1
        end
    end
    print("Balance: " .. account.balance)
    print("Transactions:")
    print("Number of transactions: " .. #transactions)



    local parsedTransactions = {}
    for _, transaction in ipairs(transactions) do
        local amount = -transaction.amount
        -- delKbn
        -- dealType 05 delKbn 01 = addition (charge)
        -- dealType 06 delKbn 01 = addition (Cashback)
        if transaction.dealType == "05" or transaction.dealType == "06" or transaction.delKbn == "02" or transaction.delKbn == "07" or transaction.delKbn == "08" then
            amount = transaction.amount
        end


        local bookingText = transaction.descriptionType
        if transaction.dealType == "05" then
            bookingText = "チャージ"
        elseif transaction.dealType == "06" then
            bookingText = "キャッシュバック"
        elseif transaction.descriptionType == "3001" then
            bookingText = "クレジットカード"
        elseif transaction.descriptionType == "3006" then
            bookingText = "Apple Pay"
        elseif transaction.descriptionType == "3007" then
            bookingText = "キャッシュバック"
        elseif transaction.descriptionType == "3009" then
            bookingText = "オートチャージ"
        elseif transaction.descriptionType == "1017" then
            bookingText = "バーチャルプリペイドカード"
        elseif transaction.descriptionType == "1018" then
            bookingText = "VISAタッチ払い"
        elseif transaction.descriptionType == "1019" then
            bookingText = "iDタッチ払い"
        else
            bookingText = "Unknown Type"
        end

        local name = transaction.shopName or bookingText

        local parsedTransaction = {
            name = name or "",
            amount = amount,
            currency = account.currency,
            bookingDate = datetime_to_timestamp(transaction.saleDatetime),
            valueDate = datetime_to_timestamp(transaction.saleDatetime),

            bookingText = bookingText or "", -- transaction type

            --purpose = transaction.dealType or "",
            transactionCode = transaction.walletSettlementNo or 0,
            purposeCode = transaction.descriptionType or "",
            booked = true
        }
        table.insert(parsedTransactions, parsedTransaction)
    end

    return { balance = account.balance, transactions = parsedTransactions }
end

function EndSession()
    print("EndSession")
end

if not is_moneymoney() then
    InitializeSession()
end
