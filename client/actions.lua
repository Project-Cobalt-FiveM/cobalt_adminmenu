local config <const> = require 'config'
local draw <const> = require 'client.draw'
local noclip <const> = require 'client.noclip'
local entityview <const> = require 'client.entityview'
local overlay <const> = require 'client.overlay'
local teleport <const> = require 'client.teleport'

local PERFORMANCE_MODS <const> = { 11, 12, 13, 15, 16 }
local FAST_RUN_MULTIPLIER <const> = 1.49

---@class AdminClientActions
---@field toggles table<string, boolean>
---@field onToggle? fun(toggles: table<string, boolean>)
local actions <const> = {}

actions.toggles = {
    noclip = false,
    godmode = false,
    invisible = false,
    names = false,
    blips = false,
    infiniteAmmo = false,
    coords = false,
    entityLaser = false,
    entityFreeAim = false,
    labelVehicles = false,
    labelPeds = false,
    labelObjects = false,
    vehicleDev = false,
    fastRun = false,
}

---@type vector3?
local lastCoords

---@param text string
---@param kind? string
local function notify(text, kind)
    exports.cobalt_core:Notify(text, kind or 'inform')
end

---@param name string
---@param on boolean
local function setToggle(name, on)
    actions.toggles[name] = on

    if actions.onToggle then
        actions.onToggle(actions.toggles)
    end
end

---@type table<string, integer>
local intervals <const> = {}

---@param name string
---@param interval integer
---@param tick fun()
local function startInterval(name, interval, tick)
    if intervals[name] then return end

    tick()
    intervals[name] = SetInterval(tick, interval)
end

---@param name string
local function stopInterval(name)
    local id <const> = intervals[name]

    if not id then return end

    ClearInterval(id)
    intervals[name] = nil
end

local OVERLAY_SCALE <const> = 0.4

---@param text string
---@param x number
---@param y number
local function drawText(text, x, y)
    draw.text(text, x, y, OVERLAY_SCALE)
end

---@param x number
---@param y number
---@param z? number nil lands on the ground under x, y
---@param heading? number
---@return boolean grounded
function actions.teleport(x, y, z, heading)
    lastCoords = GetEntityCoords(cache.ped)

    return teleport(x, y, z, heading)
end

---@param text string
local function copy(text)
    lib.setClipboard(text)
    notify(locale('notify.copied'), 'success')
end

---@param kind 2|3|4
local function copyVector(kind)
    TriggerEvent('cobalt_core:Client:PrintVector', kind)
end

---@param vehicle integer
function actions.fixVehicle(vehicle)
    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)
    SetVehicleDirtLevel(vehicle, 0.0)
end

---@param name string
---@return boolean
local function flip(name)
    local on <const> = not actions.toggles[name]
    setToggle(name, on)

    return on
end

function actions.applySelfToggles()
    SetEntityVisible(cache.ped, not actions.toggles.invisible, false)

    if actions.toggles.godmode then
        SetPlayerInvincible(cache.playerId, true)
    end
end

function actions.stopNoclip()
    if not noclip.active() then return end

    noclip.stop()
    setToggle('noclip', false)
end

---@type table<string, fun(args: table)>
local handlers <const> = {}

handlers.noclip = function()
    noclip.set(not noclip.active())
    setToggle('noclip', noclip.active())

    if not noclip.active() then
        actions.applySelfToggles()
    end
end

handlers.godmode = function()
    local on <const> = flip('godmode')

    SetPlayerInvincible(cache.playerId, on)
    notify(on and locale('notify.godmode_on') or locale('notify.godmode_off'))
end

handlers.invisible = function()
    local on <const> = flip('invisible')
    SetEntityVisible(cache.ped, not on, false)
end

handlers.names = function()
    setToggle('names', overlay.toggleNames())
end

handlers.blips = function()
    setToggle('blips', overlay.toggleBlips())
end

handlers.infiniteAmmo = function()
    SetPedInfiniteAmmoClip(cache.ped, flip('infiniteAmmo'))
end

---@param fast boolean
local function setRunSpeed(fast)
    local multiplier <const> = fast and FAST_RUN_MULTIPLIER or 1.0
    SetRunSprintMultiplierForPlayer(cache.playerId, multiplier)
    SetSwimMultiplierForPlayer(cache.playerId, multiplier)
end

handlers.fastRun = function()
    setRunSpeed(flip('fastRun'))
end

handlers.coords = function()
    local on <const> = flip('coords')

    if not on then return stopInterval('coords') end

    startInterval('coords', 0, function()
        local c <const> = GetEntityCoords(cache.ped)
        drawText(('vec4(%.2f, %.2f, %.2f, %.2f)'):format(c.x, c.y, c.z, GetEntityHeading(cache.ped)), 0.4, 0.015)
    end)
end

handlers.vehicleDev = function()
    local on <const> = flip('vehicleDev')

    if not on then return stopInterval('vehicleDev') end

    startInterval('vehicleDev', 0, function()
        local vehicle <const> = cache.vehicle

        if not vehicle then return end

        local model <const> = GetEntityModel(vehicle)
        drawText(locale('overlay.vehicle_entity', vehicle, VehToNet(vehicle)), 0.4, 0.89)
        drawText(('%s | %d'):format(GetLabelText(GetDisplayNameFromVehicleModel(model)), model), 0.4, 0.915)

        local fuel <const> = Entity(vehicle).state.fuel or GetVehicleFuelLevel(vehicle)
        local engine <const>, body <const> = GetVehicleEngineHealth(vehicle), GetVehicleBodyHealth(vehicle)
        drawText(locale('overlay.vehicle_health', engine, body, fuel), 0.4, 0.94)
    end)
end

---@param toggle string
---@param mode EntityViewMode
local function viewToggle(toggle, mode)
    handlers[toggle] = function()
        setToggle(toggle, entityview.toggle(mode))
    end
end

viewToggle('entityLaser', 'laser')
viewToggle('entityFreeAim', 'freeAim')
viewToggle('labelVehicles', 'vehicles')
viewToggle('labelPeds', 'peds')
viewToggle('labelObjects', 'objects')

handlers.teleportMarker = function()
    local blip <const> = GetFirstBlipInfoId(8)

    if not DoesBlipExist(blip) then
        return notify(locale('notify.no_waypoint'), 'error')
    end

    local coords <const> = GetBlipInfoIdCoord(blip)

    if actions.teleport(coords.x, coords.y) then
        notify(locale('notify.teleported_waypoint'), 'success')
    end
end

handlers.teleportBack = function()
    if not lastCoords then
        return notify(locale('notify.no_back_position'), 'error')
    end

    actions.teleport(lastCoords.x, lastCoords.y, lastCoords.z)
end

---@param args { coords?: string }
handlers.teleportCoords = function(args)
    local numbers <const> = {}

    for n in tostring(args.coords or ''):gmatch('-?%d*%.?%d+') do
        numbers[#numbers + 1] = tonumber(n)
    end

    if #numbers < 2 then
        return notify(locale('notify.coords_format'), 'error')
    end

    actions.teleport(numbers[1], numbers[2], numbers[3], numbers[4])
end

---@param args { location?: string }
handlers.teleportLocation = function(args)
    local quick <const> = tostring(args.location or ''):match('^quick:(%d+)$')
    local coords <const> = quick and config.QuickLocations[tonumber(quick)]?.coords
        or exports.cobalt_core:GetShared('Locations', args.location)

    if not coords then
        return notify(locale('notify.unknown_location'), 'error')
    end

    actions.teleport(coords.x, coords.y, coords.z, coords.w)
end

handlers.copyVector2 = function()
    copyVector(2)
end

handlers.copyVector3 = function()
    copyVector(3)
end

handlers.copyVector4 = function()
    copyVector(4)
end

handlers.copyHeading = function()
    copy(('%.2f'):format(GetEntityHeading(cache.ped)))
end

handlers.copyEntity = function()
    local entity <const> = entityview.aimed()

    if entity == 0 then
        return notify(locale('notify.free_aim_required'), 'error')
    end

    copy(entityview.describe(entity))
end

handlers.fixVehicle = function()
    if not cache.vehicle then
        return notify(locale('common.not_in_vehicle'), 'error')
    end

    actions.fixVehicle(cache.vehicle)
    notify(locale('notify.vehicle_fixed'), 'success')
end

handlers.maxMods = function()
    local vehicle <const> = cache.vehicle

    if not vehicle then
        return notify(locale('common.not_in_vehicle'), 'error')
    end

    SetVehicleModKit(vehicle, 0)

    for _, modType in ipairs(PERFORMANCE_MODS) do
        SetVehicleMod(vehicle, modType, GetNumVehicleMods(vehicle, modType) - 1, false)
    end

    ToggleVehicleMod(vehicle, 18, true)
    actions.fixVehicle(vehicle)
    notify(locale('notify.mods_maxed'), 'success')
end

---@param name string
---@param args? table
function actions.apply(name, args)
    args = args or {}

    local handler <const> = handlers[name]

    if not handler then return end
    if type(args.enabled) == 'boolean' and actions.toggles[name] == args.enabled then return end

    handler(args)
end

function actions.reset()
    noclip.stop()
    entityview.reset()
    overlay.reset()

    for name in pairs(intervals) do
        stopInterval(name)
    end

    local toggles <const> = actions.toggles

    if toggles.godmode then
        SetPlayerInvincible(cache.playerId, false)
    end

    if toggles.invisible then
        SetEntityVisible(cache.ped, true, false)
    end

    if toggles.infiniteAmmo then
        SetPedInfiniteAmmoClip(cache.ped, false)
    end

    if toggles.fastRun then
        setRunSpeed(false)
    end

    for name in pairs(toggles) do
        toggles[name] = false
    end
end

lib.onCache('ped', function(ped)
    if actions.toggles.invisible then
        SetEntityVisible(ped, false, false)
    end

    if actions.toggles.infiniteAmmo then
        SetPedInfiniteAmmoClip(ped, true)
    end
end)

lib.callback.register('cobalt_adminmenu:client:vehicleProps', function()
    return cache.vehicle and lib.getVehicleProperties(cache.vehicle) or nil
end)

return actions
