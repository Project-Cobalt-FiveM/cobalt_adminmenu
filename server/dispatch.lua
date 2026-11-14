local Cobalt <const> = exports.cobalt_core:GetCoreObject()
local actions <const> = require 'shared.actions'
local access <const> = require 'server.access'
local logs <const> = require 'server.logs'

---@type table<string, AdminHandler>
local handlers <const> = {}

for _, group in ipairs({ require 'server.actions.players', (require 'server.actions.global') }) do
    for name, handler in pairs(group) do
        handlers[name] = handler
    end
end

local dispatch <const> = {}

---@param source integer
---@param action AdminAction
---@param args table
local function log(source, action, args)
    logs.write(source, {
        action = action.name,
        message = locale('logs.action_used', GetPlayerName(source), action.label),
        details = args,
        target = action.scope == 'player' and tonumber(args.target) or nil,
    })
end

---@param source integer
---@param name string
---@param args? table
---@return boolean ok
---@return string? message
function dispatch.run(source, name, args)
    local action <const> = actions.byName[name]

    if not action then
        return false, locale('common.unknown_action')
    end

    if not access.allows(source, action.rank) then
        return false, locale('common.rank_required', action.label, action.rank)
    end

    args = type(args) == 'table' and args or {}

    local handler <const> = handlers[name]
    local ok, message = true, nil

    if handler then
        ok, message = handler(source, args)
    end

    if ok and action.side == 'client' then
        TriggerClientEvent('cobalt_adminmenu:client:apply', source, name, args)
    end

    if ok then
        log(source, action, args)
    end

    if message then
        Cobalt.Functions.Notify(source, message, ok and 'success' or 'error')
    end

    return ok == true, message
end

return dispatch
