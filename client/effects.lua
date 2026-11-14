local config <const> = require 'config'
local actions <const> = require 'client.actions'

local effects <const> = {}

local spectating = false
local spectateSession = 0
---@type vector3?
local spectateReturn

---@param session integer
---@return boolean
local function isSpectating(session)
    return spectating and spectateSession == session
end

RegisterNetEvent('cobalt_adminmenu:client:apply', function(name, args)
    actions.apply(name, args)
end)

RegisterNetEvent('cobalt_adminmenu:client:teleport', function(coords)
    actions.teleport(coords.x, coords.y, coords.z)
end)

RegisterNetEvent('cobalt_adminmenu:client:heal', function()
    SetEntityHealth(cache.ped, GetEntityMaxHealth(cache.ped))
    SetPedArmour(cache.ped, 100)
    ClearPedBloodDamage(cache.ped)
end)

local function stopSpectating()
    local ped <const> = cache.ped

    NetworkSetInSpectatorMode(false, ped)
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
    SetEntityVisible(ped, true, false)
    SetEntityInvincible(ped, false)
    NetworkSetEntityInvisibleToNetwork(ped, false)

    if spectateReturn then
        RequestCollisionAtCoord(spectateReturn.x, spectateReturn.y, spectateReturn.z)
        SetEntityCoords(ped, spectateReturn.x, spectateReturn.y, spectateReturn.z, false, false, false, false)
    end

    actions.applySelfToggles()
    spectateReturn = nil
    spectating = false
    TriggerServerEvent('cobalt_adminmenu:server:spectateEnded')
end

RegisterNetEvent('cobalt_adminmenu:client:spectate', function(targetId, coords)
    if spectating then
        return stopSpectating()
    end

    actions.stopNoclip()

    local ped <const> = cache.ped

    spectateSession += 1

    local session <const> = spectateSession

    spectating = true
    spectateReturn = GetEntityCoords(ped)
    SetEntityVisible(ped, false, false)
    SetEntityCollision(ped, false, false)
    SetEntityInvincible(ped, true)
    NetworkSetEntityInvisibleToNetwork(ped, true)
    SetEntityCoords(ped, coords.x, coords.y, coords.z - 10.0, false, false, false, false)
    FreezeEntityPosition(ped, true)

    local found <const>, player <const> = pcall(lib.waitFor, function()
        local index <const> = GetPlayerFromServerId(targetId)

        if index ~= -1 and DoesEntityExist(GetPlayerPed(index)) then
            return index
        end
    end, nil, 5000)

    if not isSpectating(session) then return end

    if not found then
        return stopSpectating()
    end

    NetworkSetInSpectatorMode(true, GetPlayerPed(player))
    exports.cobalt_core:Notify(locale('spectate.started'), 'inform')

    CreateThread(function()
        while isSpectating(session) do
            Wait(1000)

            if isSpectating(session) and (GetPlayerFromServerId(targetId) == -1 or not DoesEntityExist(GetPlayerPed(player))) then
                exports.cobalt_core:Notify(locale('spectate.target_left'), 'inform')
                stopSpectating()
            end
        end
    end)
end)

function effects.reset()
    if spectating then
        stopSpectating()
    end
end

RegisterNetEvent('cobalt_adminmenu:client:setPed', function(model)
    local hash <const> = joaat(model)

    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return end

    lib.requestModel(hash)
    SetPlayerModel(cache.playerId, hash)

    if not config.BlockedRandomPeds[model] then
        SetPedRandomComponentVariation(PlayerPedId(), 0)
    else
        SetPedDefaultComponentVariation(PlayerPedId())
    end

    SetModelAsNoLongerNeeded(hash)
end)

RegisterNetEvent('cobalt_adminmenu:client:fixVehicle', function()
    if cache.vehicle then
        actions.fixVehicle(cache.vehicle)
    end
end)

RegisterNetEvent('cobalt_adminmenu:client:fire', function()
    StartEntityFire(cache.ped)

    SetTimeout(10000, function()
        StopEntityFire(cache.ped)
    end)
end)

RegisterNetEvent('cobalt_adminmenu:client:explode', function()
    local coords <const> = GetEntityCoords(cache.ped)
    AddExplosion(coords.x, coords.y, coords.z, 2, 0.9, true, false, 1.0)
end)

RegisterNetEvent('cobalt_adminmenu:client:vehicleSpawned', function(netId, mods)
    local found <const>, vehicle <const> = pcall(lib.waitFor, function()
        local entity <const> = NetworkDoesNetworkIdExist(netId) and NetToVeh(netId) or 0

        if entity ~= 0 and NetworkGetEntityOwner(entity) == cache.playerId then
            return entity
        end
    end, nil, 5000)

    if not found then return end

    SetVehicleOnGroundProperly(vehicle)

    if mods and next(mods) then
        lib.setVehicleProperties(vehicle, mods)
    end

    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehRadioStation(vehicle, 'OFF')
end)

RegisterNetEvent('cobalt_adminmenu:client:nuiFocus', function(focus, mouse)
    SetNuiFocus(focus, mouse)
end)

return effects
