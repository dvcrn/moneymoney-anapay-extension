--[[
    ANA Pay Wallet Integration for MoneyMoney

    This script provides integration for ANA Pay Wallet into MoneyMoney,
    allowing users to fetch their account balance and transactions.

    Author: David Mohl
    Version: 1.0
    License: MIT (commercial excluded)
]]

-- Set the following to true to have a bit more output
local DEBUG = false

-- luarocks setup
local luarocks_prefix = "./lua_modules"
package.path = luarocks_prefix .. "/share/lua/5.4/?.lua;" .. luarocks_prefix ..
    "/share/lua/5.1/?/init.lua;" .. package.path
package.cpath = luarocks_prefix .. "/lib/lua/5.4/?.so;" .. package.cpath

-- Script start
local helpers = require("helpers")
helpers.debug = DEBUG

helpers.print_env()

local mm = require("mm")
local anapay = require("anapay")


function SupportsBank(protocol, bankCode)
    helpers.debug_print("SupportsBank " .. protocol .. " " .. bankCode)
    return protocol == ProtocolWebBanking and bankCode == "ANA Pay Wallet"
end

function InitializeSession(protocol, bankCode, username, reserved, password)
    -- Login.
    helpers.debug_print("InitializeSession args:")
    helpers.debug_print("protocol:", protocol)
    helpers.debug_print("bankCode:", bankCode)
    helpers.debug_print("username:", username)
    helpers.debug_print("reserved:", reserved)
    helpers.debug_print("password:", password)

    local result = anapay.login(username, password)
    helpers.debug_print(mm.stringify_json(result, { indent = true }))

    mm.store_value("accessToken", result.accessToken)
end

function ListAccounts(knownAccounts)
    local accessToken = mm.get_value("accessToken")
    local accounts = anapay.getAccounts(accessToken)

    helpers.print("discovered account: ", accounts.referenceNumber, accounts.balance)

    local account = {
        name = "ANA Pay",
        accountNumber = accounts.referenceNumber,
        currency = "JPY",
        balance = accounts.balance,
        type = AccountTypeCreditCard
    }

    mm.store_value("account", account)
    return { account }
end

function RefreshAccount(account, since)
    helpers.debug_print("refresh account")
    helpers.debug_print(mm.stringify_json(account))
    helpers.debug_print("since " .. since) -- format: 8/11/2024

    local accessToken = mm.get_value("accessToken")
    local account = mm.get_value("account")

    local accounts = anapay.getAccounts(accessToken)
    account = {
        name = "ANA Pay",
        accountNumber = accounts.referenceNumber,
        currency = "JPY",
        balance = accounts.balance,
        type = AccountTypeCreditCard
    }

    helpers.print("refreshing account", accounts.referenceNumber, "balance=", accounts.balance)

    helpers.debug_print("Account")
    helpers.debug_print(mm.stringify_json(account, { indent = true }))


    local transactions = {}
    local page = 1
    local hasMore = true
    while hasMore do
        local result = anapay.getTransactions(accessToken, page)
        if #result == 0 then
            hasMore = false
        else
            for _, transaction in ipairs(result) do
                if helpers.datetime_to_timestamp(transaction.saleDatetime) < since then
                    hasMore = false
                    break
                end
                table.insert(transactions, transaction)
            end
            page = page + 1
        end
    end

    helpers.print("received # transactions: " .. #transactions)

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
            bookingDate = helpers.datetime_to_timestamp(transaction.saleDatetime),
            valueDate = helpers.datetime_to_timestamp(transaction.saleDatetime),

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
    helpers.debug_print("EndSession")
end

if not mm.is_moneymoney() then
    InitializeSession(nil, nil, "foo", nil, "bar")
end
