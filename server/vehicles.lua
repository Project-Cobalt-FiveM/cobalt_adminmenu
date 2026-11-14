local Cobalt <const> = exports.cobalt_core:GetCoreObject()
local args <const> = require 'server.args'

local WARP_TIMEOUT <const> = 2000

local vehicles <const> = {}

---@param plate string
---@return boolean
function vehicles.inWorld(plate)
    for _, vehicle in ipairs(GetAllVehicles()) do
        if args.trim(GetVehicleNumberPlateText(vehicle)) == plate then
            return true
        end
    end

    return false
end

---@param ped integer
---@param vehicle integer
local function warpInto(ped, vehicle)
    local deadline <const> = GetGameTimer() + WARP_TIMEOUT

    while GetVehiclePedIsIn(ped, false) ~= vehicle and GetGameTimer() < deadline do
        TaskWarpPedIntoVehicle(ped, vehicle, -1)
        Wait(50)
    end
end

---@param source integer
---@param model string
---@param plate? string
---@param mods? table
---@return boolean ok
---@return string? message
function vehicles.spawn(source, model, plate, mods)
    local vehicleType <const> = exports.cobalt_core:GetVehicleType(source, model)

    if not vehicleType then
        return false, locale('vehicles.unknown_model', model)
    end

    local ped <const> = GetPlayerPed(source)
    local coords <const> = GetEntityCoords(ped)
    local spawnAt <const> = vector4(coords.x, coords.y, coords.z + 0.5, GetEntityHeading(ped))
    local vehicle <const>, spawnPlate <const> = Cobalt.Functions.SpawnVehicle(source, model, spawnAt, false, vehicleType)

    if not vehicle then
        return false, locale('vehicles.spawn_failed', model)
    end

    SetEntityRoutingBucket(vehicle, GetPlayerRoutingBucket(source))

    if plate then
        SetVehicleNumberPlateText(vehicle, plate)
    end

    local finalPlate <const> = plate or spawnPlate

    exports.cobalt_vehiclekeys:GiveKey(source, finalPlate, vehicle)
    warpInto(ped, vehicle)

    TriggerClientEvent('cobalt_adminmenu:client:vehicleSpawned', source, NetworkGetNetworkIdFromEntity(vehicle), mods)

    return true
end

return vehicles
