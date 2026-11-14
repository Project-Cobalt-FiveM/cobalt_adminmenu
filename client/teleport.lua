local FADE_MS <const> = 500
local STREAM_TIMEOUT_MS <const> = 5000
local GROUND_PROBE_Z <const> = 1000.0
local FALLBACK_Z <const> = 150.0

---@param ped integer
---@param x number
---@param y number
---@param z number
local function waitForCollision(ped, x, y, z)
    local deadline <const> = GetGameTimer() + STREAM_TIMEOUT_MS

    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < deadline do
        RequestCollisionAtCoord(x, y, z)
        Wait(0)
    end
end

---@param ped integer
---@param x number
---@param y number
---@return number? z
local function findGround(ped, x, y)
    local deadline <const> = GetGameTimer() + STREAM_TIMEOUT_MS

    SetPedCoordsKeepVehicle(ped, x, y, GROUND_PROBE_Z)

    while GetGameTimer() < deadline do
        RequestCollisionAtCoord(x, y, GROUND_PROBE_Z)

        local found <const>, groundZ <const> = GetGroundZFor_3dCoord(x, y, GROUND_PROBE_Z, false)

        if found then return groundZ end

        Wait(100)
    end

    local onWater <const>, waterZ <const> = GetWaterHeight(x, y, GROUND_PROBE_Z)

    if onWater then return waterZ end
end

---Moves the player, and their vehicle if they are driving one, behind a fade.
---@param x number
---@param y number
---@param z? number height to land at; nil finds the ground under x, y
---@param heading? number
---@return boolean grounded false when z was nil and no ground was found
return function(x, y, z, heading)
    local ped <const> = cache.ped
    local vehicle <const> = GetVehiclePedIsIn(ped, false)
    local frozen <const> = vehicle ~= 0 and vehicle or ped

    DoScreenFadeOut(FADE_MS)

    while not IsScreenFadedOut() do
        Wait(0)
    end

    FreezeEntityPosition(frozen, true)

    local landZ = z

    if landZ then
        SetPedCoordsKeepVehicle(ped, x, y, landZ)
        waitForCollision(ped, x, y, landZ)
    else
        landZ = findGround(ped, x, y)
    end

    SetPedCoordsKeepVehicle(ped, x, y, landZ or FALLBACK_Z)

    if heading then
        SetEntityHeading(frozen, heading)
    end

    FreezeEntityPosition(frozen, false)
    DoScreenFadeIn(FADE_MS)

    if not landZ then
        exports.cobalt_core:Notify(locale('notify.no_ground'), 'error')
    end

    return landZ ~= nil
end
