local LABEL_RANGE <const> = 10.0
local DETAIL_RANGE <const> = 5.0
local RAY_FLAGS <const> = 30
local BOX_EDGES <const> = {
    { 0, 1 }, { 1, 3 }, { 3, 2 }, { 2, 0 },
    { 4, 5 }, { 5, 7 }, { 7, 6 }, { 6, 4 },
    { 0, 4 }, { 1, 5 }, { 2, 6 }, { 3, 7 },
}

local draw <const> = require 'client.draw'

local DrawLine <const> = DrawLine
local GetEntityCoords <const> = GetEntityCoords
local GetOffsetFromEntityInWorldCoords <const> = GetOffsetFromEntityInWorldCoords

---@type table<integer, string>?
local names

---@alias EntityViewMode 'freeAim'|'laser'|'vehicles'|'peds'|'objects'

local entityview <const> = {}

---@type table<EntityViewMode, boolean>
local modes <const> = { freeAim = false, laser = false, vehicles = false, peds = false, objects = false }
local running = false
local aimed = 0
---@type table<integer, boolean>
local frozen <const> = {}

---@param value number
---@return string
local function round(value)
    return ('%.2f'):format(value)
end

---@param v vector3
---@return string
local function vec(v)
    return ('vec3(%s, %s, %s)'):format(round(v.x), round(v.y), round(v.z))
end

---@param entity integer
---@return string[]
local function describe(entity)
    local model <const> = GetEntityModel(entity)

    names = names or lib.load('data.entities')

    local lines <const> = {
        locale('entity.model', names[model] or locale('entity.unknown'), model),
        locale(
            'entity.ids',
            entity,
            NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity) or locale('entity.local_only'),
            GetPlayerServerId(NetworkGetEntityOwner(entity))
        ),
    }

    local kind <const> = GetEntityType(entity)

    if kind == 1 then
        lines[#lines + 1] = locale(
            'entity.health',
            GetEntityHealth(entity),
            GetPedMaxHealth(entity),
            GetPedArmour(entity)
        )
    elseif kind == 2 then
        lines[#lines + 1] = locale(
            'entity.vehicle_health',
            round(GetVehicleEngineHealth(entity)),
            round(GetVehicleBodyHealth(entity))
        )
        lines[#lines + 1] = locale(
            'entity.speed',
            math.floor(GetEntitySpeed(entity) * 3.6),
            GetVehicleCurrentGear(entity)
        )
    end

    lines[#lines + 1] = locale(
        'entity.heading',
        round(GetEntityHeading(entity)),
        round(#(GetEntityCoords(cache.ped) - GetEntityCoords(entity)))
    )
    lines[#lines + 1] = locale('entity.coords', vec(GetEntityCoords(entity)))
    lines[#lines + 1] = locale('entity.rotation', vec(GetEntityRotation(entity, 2)))

    return lines
end

local drawText <const> = draw.text

---@param entity integer
---@param r integer
---@param g integer
---@param b integer
local function drawBox(entity, r, g, b)
    local min <const>, max <const> = GetModelDimensions(GetEntityModel(entity))
    local corners <const> = {}

    for i = 0, 7 do
        local x <const> = (i & 1) == 0 and min.x or max.x
        local y <const> = (i & 2) == 0 and min.y or max.y
        local z <const> = (i & 4) == 0 and min.z or max.z
        corners[i] = GetOffsetFromEntityInWorldCoords(entity, x, y, z)
    end

    for _, edge in ipairs(BOX_EDGES) do
        local from <const>, to <const> = corners[edge[1]], corners[edge[2]]
        DrawLine(from.x, from.y, from.z, to.x, to.y, to.z, r, g, b, 255)
    end
end

---@param pool string
---@param origin vector3
local function labelPool(pool, origin)
    for _, entity in ipairs(GetGamePool(pool)) do
        if entity ~= cache.ped and entity ~= aimed then
            local coords <const> = GetEntityCoords(entity)
            local distance <const> = #(origin - coords)

            if distance < DETAIL_RANGE then
                local onScreen <const>, x <const>, y <const> = World3dToScreen2d(coords.x, coords.y, coords.z)

                if onScreen then
                    for i, line in ipairs(describe(entity)) do
                        drawText(line, x, y + (i - 1) * 0.015, 0.25)
                    end
                end
            elseif distance < LABEL_RANGE then
                drawBox(entity, 250, 250, 250)
            end
        end
    end
end

local function freeAim()
    local hit <const>, entity <const> = lib.raycast.cam(RAY_FLAGS, 4, 1000.0)
    aimed = hit and entity ~= 0 and GetEntityType(entity) ~= 0 and entity or 0
    drawText(locale('entity.free_aim_hint'), 0.5, 0.02, 0.4)

    if aimed == 0 then return end

    drawBox(aimed, 80, 120, 215)

    for i, line in ipairs(describe(aimed)) do
        drawText(line, 0.6, 0.06 + (i - 1) * 0.022, 0.35)
    end

    if IsControlJustReleased(0, 47) then
        local freeze <const> = not frozen[aimed]

        frozen[aimed] = freeze or nil
        FreezeEntityPosition(aimed, freeze)
        exports.cobalt_core:Notify(freeze and locale('notify.entity_frozen') or locale('notify.entity_unfrozen'), 'inform')
    end
end

local function unfreezeAll()
    for entity in pairs(frozen) do
        if DoesEntityExist(entity) then
            FreezeEntityPosition(entity, false)
        end

        frozen[entity] = nil
    end
end

---@param entity integer
local function deleteEntity(entity)
    if NetworkGetEntityIsNetworked(entity) then
        lib.callback('cobalt_adminmenu:server:action', 500, function() end, 'deleteEntity', {
            netId = NetworkGetNetworkIdFromEntity(entity),
        })

        return
    end

    SetEntityAsMissionEntity(entity, true, true)
    DeleteEntity(entity)

    local remains <const> = DoesEntityExist(entity)
    exports.cobalt_core:Notify(
        remains and locale('notify.entity_delete_failed') or locale('notify.entity_deleted'),
        remains and 'error' or 'success'
    )
end

local function laser()
    local hit <const>, entity <const>, coords <const> = lib.raycast.cam(RAY_FLAGS, 4, 1000.0)

    if not hit then return end

    local origin <const> = GetEntityCoords(cache.ped)
    DrawLine(origin.x, origin.y, origin.z, coords.x, coords.y, coords.z, 80, 120, 215, 255)
    DrawMarker(
        28,
        coords.x,
        coords.y,
        coords.z,
        0.0,
        0.0,
        0.0,
        0.0,
        180.0,
        0.0,
        0.1,
        0.1,
        0.1,
        80,
        120,
        215,
        255,
        false,
        true,
        2,
        false,
        nil,
        nil,
        false
    )
    drawText(locale('entity.laser_hint', vec(coords)), 0.5, 0.05, 0.35)

    if IsControlJustReleased(0, 74) then
        lib.setClipboard(vec(coords))
        exports.cobalt_core:Notify(locale('notify.coords_copied'), 'success')
    end

    if entity == 0 or GetEntityType(entity) == 0 or entity == cache.ped then return end
    if not IsControlJustReleased(0, 38) then return end

    deleteEntity(entity)
end

---@return boolean
local function anyActive()
    for _, on in pairs(modes) do
        if on then
            return true
        end
    end

    return false
end

local function run()
    if running then return end

    running = true

    CreateThread(function()
        while anyActive() do
            local origin <const> = GetEntityCoords(cache.ped)

            if modes.vehicles then
                labelPool('CVehicle', origin)
            end

            if modes.peds then
                labelPool('CPed', origin)
            end

            if modes.objects then
                labelPool('CObject', origin)
            end

            if modes.freeAim then
                freeAim()
            else
                aimed = 0
            end

            if modes.laser then
                laser()
            end

            Wait(0)
        end

        aimed = 0
        running = false
    end)
end

---@param mode EntityViewMode
---@return boolean
function entityview.toggle(mode)
    modes[mode] = not modes[mode]

    if modes[mode] then
        run()
    elseif mode == 'freeAim' then
        unfreezeAll()
    end

    return modes[mode]
end

function entityview.reset()
    for mode in pairs(modes) do
        modes[mode] = false
    end

    aimed = 0
    unfreezeAll()
end

---@return integer
function entityview.aimed()
    return aimed
end

---@param entity integer
---@return string
function entityview.describe(entity)
    return table.concat(describe(entity), '\n')
end

return entityview
