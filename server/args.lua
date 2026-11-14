local config <const> = require 'config'

---@type table<string, true>
local ACCOUNTS <const> = {}

for _, account in ipairs(config.Accounts) do
    ACCOUNTS[account] = true
end

local args <const> = {}

---@param value unknown
---@return string
function args.trim(value)
    if type(value) ~= 'string' then return '' end

    return (value:gsub('^%s+', ''):gsub('%s+$', ''))
end

---@param input table
---@return string? account
---@return integer? amount
function args.money(input)
    local amount <const> = math.tointeger(tonumber(input.amount))

    if not ACCOUNTS[input.account] or not amount or amount < 1 then return end

    return input.account, amount
end

return args
