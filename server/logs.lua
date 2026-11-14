local Cobalt <const> = exports.cobalt_core:GetCoreObject()
local config <const> = require 'config'
local db <const> = require 'server.db'

---@class AdminLogEntry
---@field action string
---@field message string
---@field details table
---@field target? integer

local useDatabase <const> = config.LogBackend == 'database'

if useDatabase then
    lib.print.warn(locale('logs.database_backend'))
elseif config.LogBackend ~= 'fivemesh' then
    lib.print.warn(locale('logs.unknown_backend', tostring(config.LogBackend)))
end

local logs <const> = {}

---@param source integer
---@param entry AdminLogEntry
function logs.write(source, entry)
    if not useDatabase then
        exports.cobalt_core:LogPlayer(
            source,
            'admin.' .. entry.action,
            entry.message,
            entry.details,
            'security',
            entry.target
        )

        return
    end

    local targetLicense <const> = entry.target and Cobalt.Functions.GetIdentifier(entry.target, 'license') or nil

    db.insertLog(
        Cobalt.Functions.GetIdentifier(source, 'license'),
        GetPlayerName(source),
        entry.action,
        targetLicense,
        entry.details
    )
end

return logs
