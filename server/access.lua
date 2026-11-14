local Cobalt <const> = exports.cobalt_core:GetCoreObject()
local catalog <const> = require 'shared.actions'

---@type AdminRank[]
local RANKS <const> = { 'owner', 'admin', 'staff' }

local access <const> = {}

---@param source integer
---@return AdminRank?
function access.rank(source)
    for _, rank in ipairs(RANKS) do
        if Cobalt.Functions.HasPermission(source, rank) then
            return rank
        end
    end
end

---@param source integer
---@param required AdminRank
---@return boolean
function access.allows(source, required)
    return catalog.rankAllows(access.rank(source), required)
end

---@return integer[]
function access.staff()
    local staff <const> = {}

    for _, playerId in ipairs(GetPlayers()) do
        local source <const> = tonumber(playerId) --[[@as integer]]

        if access.rank(source) then
            staff[#staff + 1] = source
        end
    end

    return staff
end

return access
