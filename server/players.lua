local Cobalt <const> = exports.cobalt_core:GetCoreObject()
local access <const> = require 'server.access'
local db <const> = require 'server.db'

---@class PlayerRow
---@field id integer
---@field name string
---@field citizenid string
---@field job string
---@field grade string
---@field onDuty boolean
---@field down boolean
---@field downSince? integer
---@field staff boolean
---@field distance integer

---@class PlayerDetail : PlayerRow
---@field cash number
---@field bank number
---@field phone? string
---@field gang? string
---@field gangGrade? string
---@field warnings { count: integer, last?: integer }
---@field onlineSeconds integer
---@field bucket integer
---@field frozen boolean
---@field identifiers { license?: string, discord?: string, steam?: string }
---@field vehicles AdminOption[]

local players <const> = {}

---@type table<integer, integer>
local joinedAt <const> = {}

---@class PlayerIdentity
---@field name string
---@field citizenid string
---@field job table

---@type table<integer, PlayerIdentity>
local identities <const> = {}

---@type table<integer, integer>
players.frozen = {}

---@type table<integer, boolean>
players.muted = {}

---@param source integer
---@return table?
function players.get(source)
    source = tonumber(source) --[[@as integer]]

    if not source then return end

    return Cobalt.Functions.GetPlayer(source)
end

---@param source integer
---@return boolean
function players.isFrozen(source)
    local ped <const> = players.frozen[source]

    return ped ~= nil and ped == GetPlayerPed(source)
end

---@param mover integer
---@param anchor integer
function players.joinBucket(mover, anchor)
    local bucket <const> = GetPlayerRoutingBucket(anchor)

    if GetPlayerRoutingBucket(mover) ~= bucket then
        exports.cobalt_core:SetPlayerBucket(mover, bucket)
    end
end

---@param admin integer
---@param target integer
function players.teleportTo(admin, target)
    players.joinBucket(admin, target)
    TriggerClientEvent('cobalt_adminmenu:client:teleport', admin, GetEntityCoords(GetPlayerPed(target)))
end

---@param player table
---@return string
function players.name(player)
    return exports.cobalt_core:GetName(player.PlayerData.source) or player.PlayerData.citizenid
end

---@param pd table
---@return table?
local function gangOf(pd)
    return pd.gang and pd.gang.name ~= 'none' and pd.gang or nil
end

---@param source integer
---@return boolean down
---@return integer? downSince
local function downState(source)
    local revive <const> = Player(source).state.revive

    if not revive or revive.state == 'alive' then return false end

    return true, revive.since and revive.since > 0 and os.time() - revive.since or nil
end

---@param player table
---@return PlayerIdentity
local function remember(player)
    local pd <const> = player.PlayerData
    local identity <const> = { name = players.name(player), citizenid = pd.citizenid, job = pd.job or {} }

    identities[pd.source] = identity

    return identity
end

---@param source integer
---@return PlayerIdentity?
local function identityOf(source)
    local known <const> = identities[source]

    if known then return known end

    local player <const> = Cobalt.Functions.GetPlayer(source)

    return player and remember(player)
end

---@param source integer
---@param identity PlayerIdentity
---@param origin vector3
---@return PlayerRow
local function row(source, identity, origin)
    local job <const> = identity.job
    local down <const>, downSince <const> = downState(source)

    return {
        id = source,
        name = identity.name,
        citizenid = identity.citizenid,
        job = job.label or locale('players.unemployed'),
        grade = job.grade?.name or locale('players.civilian'),
        onDuty = job.onduty == true and job.name ~= 'unemployed',
        down = down,
        downSince = downSince,
        staff = access.rank(source) ~= nil,
        distance = math.floor(#(GetEntityCoords(GetPlayerPed(source)) - origin)),
    }
end

---@param adminSource integer
---@return PlayerRow[]
function players.list(adminSource)
    local origin <const> = GetEntityCoords(GetPlayerPed(adminSource))
    local rows <const> = {}

    for _, source in ipairs(Cobalt.Functions.GetPlayers()) do
        local identity <const> = identityOf(source)

        if identity then
            rows[#rows + 1] = row(source, identity, origin)
        end
    end

    table.sort(rows, function(a, b) return a.id < b.id end)

    return rows
end

---@param citizenid string
---@return AdminOption[]
local function vehicleOptions(citizenid)
    local options <const> = {}

    for _, owned in ipairs(exports.cobalt_core:GetVehiclesByCitizenId(citizenid)) do
        local shared <const> = exports.cobalt_core:GetShared('Vehicles', owned.vehicle)

        options[#options + 1] = {
            label = ('%s (%s)'):format(shared?.name or owned.vehicle, owned.plate),
            value = owned.plate,
        }
    end

    return options
end

---@param adminSource integer
---@param source integer
---@return PlayerDetail?
function players.detail(adminSource, source)
    local player <const> = players.get(source)

    if not player then return end

    local pd <const> = player.PlayerData
    local detail <const> = row(pd.source, remember(player), GetEntityCoords(GetPlayerPed(adminSource)))
    local gang <const> = gangOf(pd)
    local license <const> = Cobalt.Functions.GetIdentifier(source, 'license')
    local count <const>, last <const> = db.countWarns(license)

    detail.cash = player.Functions.GetMoney('cash') or 0
    detail.bank = player.Functions.GetMoney('bank') or 0
    detail.phone = pd.charinfo?.phone
    detail.gang = gang?.label
    detail.gangGrade = gang?.grade?.name
    detail.warnings = { count = count, last = last }
    detail.onlineSeconds = os.time() - (joinedAt[source] or os.time())
    detail.bucket = GetPlayerRoutingBucket(source)
    detail.frozen = players.isFrozen(source)
    detail.identifiers = {
        license = license,
        discord = Cobalt.Functions.GetIdentifier(source, 'discord'),
        steam = Cobalt.Functions.GetIdentifier(source, 'steam'),
    }
    detail.vehicles = vehicleOptions(pd.citizenid)

    return detail
end

AddEventHandler('cobalt_core:Server:PlayerLoaded', function(player)
    joinedAt[player.PlayerData.source] = os.time()
    remember(player)
end)

AddEventHandler('cobalt_management:membershipChanged', function(source, job)
    local identity <const> = identities[source]

    if identity and job then identity.job = job end
end)

AddEventHandler('cobalt_core:Server:OnPlayerUnload', function(source)
    identities[source] = nil
end)

AddEventHandler('playerDropped', function()
    joinedAt[source] = nil
    identities[source] = nil
    players.frozen[source] = nil
    players.muted[source] = nil
end)

for _, source in ipairs(Cobalt.Functions.GetPlayers()) do
    joinedAt[source] = os.time()
end

return players
