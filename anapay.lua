local M = {}
local mm = require("mm")
local helpers = require("helpers")

function M.login(anaWalletId, deviceId)
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

    local status, responseHeaders, content = mm.make_request(url, "POST", headers, mm.stringify_json(body))

    local response = mm.parse_json(content)
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

function M.getAccounts(accessToken)
    local url = "https://teikei1.api.mkpst.com/accounts?balanceReferenceFlag=1&nfcStatusReferenceFlag=1"
    local headers = {
        ["host"] = "teikei1.api.mkpst.com",
        ["accept"] = "application/json",
        ["user-agent"] = "ANAMileage/4.31.0 (jp.co.ana.anamile; build:4; iOS 18.1.0) Alamofire/5.9.1",
        ["authorization"] = "Bearer " .. accessToken,
        ["accept-language"] = "ja-JP;q=1.0, en-AU;q=0.9, de-JP;q=0.8",
        ["content-type"] = "application/json"
    }

    local status, responseHeaders, content = mm.make_request(url, "GET", headers)

    local response = mm.parse_json(content)
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

function M.getTransactions(accessToken, pageNumber, pageSize)
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

    local status, responseHeaders, content = mm.make_request(url, "GET", headers)

    local response = mm.parse_json(content)
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

return M
