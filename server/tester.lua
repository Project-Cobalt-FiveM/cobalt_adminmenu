local Cobalt <const> = exports.cobalt_core:GetCoreObject()
local config <const> = require 'config'

---@class TesterGrantRequest
---@field discordId string
---@field name string

---@class TesterGrantReply
---@field ok boolean
---@field online? boolean
---@field alreadyGranted? boolean
---@field error? 'bad_request'|'forbidden'

---@type table<string, true>
local LOOPBACK <const> = { ['127.0.0.1'] = true, ['::1'] = true, ['::ffff:127.0.0.1'] = true }

---@param address string
---@return string
local function hostOf(address)
    local bracketed <const> = address:match('^%[(.+)%]:%d+$')

    if bracketed then return bracketed end

    local _, colons <const> = address:gsub(':', '')

    return colons == 1 and address:match('^(.+):%d+$') or address
end

---@param body string
---@return TesterGrantRequest?
local function parse(body)
    local ok <const>, data <const> = pcall(json.decode, body)

    if not ok or type(data) ~= 'table' then return end

    local discordId <const> = data.discordId

    if type(discordId) ~= 'string' or not discordId:match('^%d+$') or #discordId > 20 then return end

    local name <const> = type(data.name) == 'string' and data.name:sub(1, 64) or ''

    return { discordId = discordId, name = name }
end

---@param discordId string
---@return integer?
local function onlinePlayer(discordId)
    local identifier <const> = 'discord:' .. discordId

    for _, playerId in ipairs(GetPlayers()) do
        if GetPlayerIdentifierByType(playerId, 'discord') == identifier then
            return tonumber(playerId) --[[@as integer]]
        end
    end
end

---@param request TesterGrantRequest
---@return TesterGrantReply
local function grant(request)
    local principal <const> = 'identifier.discord:' .. request.discordId
    local alreadyGranted <const> = IsPrincipalAceAllowed(principal, 'tester')
    local source <const> = onlinePlayer(request.discordId)

    if not alreadyGranted then
        ExecuteCommand(('add_principal %s group.tester'):format(principal))

        if source then
            Cobalt.Commands.Refresh(source)
            Cobalt.Functions.Notify(source, locale('tester.granted', config.OpenKey), 'success', 10000)
        end
    end

    local message <const> = ('Tester admin granted to %s (Discord %s)'):format(request.name, request.discordId)

    exports.cobalt_core:Log('admin.tester', message, {
        discordId = request.discordId,
        name = request.name,
        online = source ~= nil,
        alreadyGranted = alreadyGranted,
    })

    return { ok = true, online = source ~= nil, alreadyGranted = alreadyGranted }
end

---@param response table
---@param status integer
---@param reply TesterGrantReply
local function respond(response, status, reply)
    response.writeHead(status, { ['Content-Type'] = 'application/json' })
    response.send(json.encode(reply))
end

SetHttpHandler(function(request, response)
    if request.path ~= '/tester' then
        return respond(response, 404, { ok = false, error = 'bad_request' })
    end

    if not LOOPBACK[hostOf(request.address or '')] then
        return respond(response, 403, { ok = false, error = 'forbidden' })
    end

    if request.method ~= 'POST' then
        return respond(response, 405, { ok = false, error = 'bad_request' })
    end

    request.setDataHandler(function(body)
        local parsed <const> = parse(body)

        if not parsed then
            return respond(response, 400, { ok = false, error = 'bad_request' })
        end

        respond(response, 200, grant(parsed))
    end)
end)
