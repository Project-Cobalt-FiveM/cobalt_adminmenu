local FADE_MS <const> = 500
local STREAM_TIMEOUT_MS <const> = 5000
local STEP_STREAM_MS <const> = 400
local PROBE_TOP_Z <const> = 1000.0
local PROBE_BOTTOM_Z <const> = -50.0
local PROBE_STEP <const> = 50.0
local RAY_END_Z <const> = -200.0
local RAY_WORLD_FLAGS <const> = 1 | 16
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

---@param ignore integer
---@param x number
---@param y number
---@param fromZ number
---@return number? z where a straight-down ray first hits the world
local function castDown(ignore, x, y, fromZ)
    local handle <const> = StartExpensiveSynchronousShapeTestLosProbe(x, y, fromZ, x, y, RAY_END_Z, RAY_WORLD_FLAGS, ignore, 4)
    local _, hit <const>, coords <const> = GetShapeTestResult(handle)

    if hit == 1 then return coords.z end
end

---@param ped integer
---@param ignore integer
---@param x number
---@param y number
---@return number? z
local function findGround(ped, ignore, x, y)
    for z = PROBE_TOP_Z, PROBE_BOTTOM_Z, -PROBE_STEP do
        SetPedCoordsKeepVehicle(ped, x, y, z)

        local deadline <const> = GetGameTimer() + STEP_STREAM_MS

        repeat
            RequestCollisionAtCoord(x, y, z)
            Wait(0)
        until HasCollisionLoadedAroundEntity(ped) or GetGameTimer() > deadline

        local rayZ <const> = castDown(ignore, x, y, z)

        if rayZ then return rayZ end

        local found <const>, groundZ <const> = GetGroundZFor_3dCoord(x, y, z, false)

        if found then return groundZ end
    end

    local onWater <const>, waterZ <const> = GetWaterHeight(x, y, PROBE_TOP_Z)

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
        landZ = findGround(ped, frozen, x, y)
    end

    SetPedCoordsKeepVehicle(ped, x, y, landZ or FALLBACK_Z)
    waitForCollision(ped, x, y, landZ or FALLBACK_Z)

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
