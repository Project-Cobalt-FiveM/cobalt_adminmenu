local MIN_PITCH <const>, MAX_PITCH <const> = -89.0, 89.0
local MAX_SPEED <const> = 16.0
local METERS_PER_SECOND <const> = 10.0

local MOVE_FORWARDS <const> = 32
local MOVE_BACKWARDS <const> = 33
local MOVE_LEFT <const> = 34
local MOVE_RIGHT <const> = 35
local MOVE_UP <const> = 44
local MOVE_DOWN <const> = 46
local SPEED_DECREASE <const> = 14
local SPEED_INCREASE <const> = 15
local SPEED_RESET <const> = 348
local SPEED_SLOW <const> = 36
local SPEED_FAST <const> = 21
local SPEED_FASTER <const> = 19

local UP <const> = vector3(0.0, 0.0, 1.0)

local IsControlPressed <const> = IsControlPressed
local IsDisabledControlPressed <const> = IsDisabledControlPressed

local noclip <const> = {}

local active = false
local entity = 0
local camera = 0
local inVehicle = false
local speed = 1.0

---@param control integer
---@return boolean
local function held(control)
    return IsControlPressed(0, control) or IsDisabledControlPressed(0, control)
end

local function disableControls()
    HudWeaponWheelIgnoreSelection()
    DisableAllControlActions(0)
    DisableAllControlActions(1)
    DisableAllControlActions(2)
    EnableControlAction(0, 220, true)
    EnableControlAction(0, 221, true)
    EnableControlAction(0, 245, true)
end

local function createCamera()
    local coords <const> = GetEntityCoords(entity)
    local heading <const> = GetEntityHeading(entity)

    camera = CreateCamWithParams(
        'DEFAULT_SCRIPTED_CAMERA',
        coords.x,
        coords.y,
        coords.z,
        0.0,
        0.0,
        heading,
        75.0,
        false,
        2
    )

    if inVehicle then
        AttachCamToEntity(camera, entity, 0.0, -4.5, 2.0, true)
    else
        AttachCamToEntity(camera, entity, 0.0, 0.0, 1.0, true)
    end

    SetCamActive(camera, true)
    RenderScriptCams(true, true, 500, true, false)
end

local function destroyCamera()
    SetGameplayCamRelativeHeading(0)
    RenderScriptCams(false, true, 1000, true, true)
    DetachEntity(entity, true, true)
    SetCamActive(camera, false)
    DestroyCam(camera, true)
    camera = 0
end

local function rotateCamera()
    local rotation <const> = GetCamRot(camera, 2)
    local pitch <const> = rotation.x + GetControlNormal(0, 221) * -5
    local yaw <const> = rotation.z + GetControlNormal(0, 220) * -10

    if pitch > MIN_PITCH and pitch < MAX_PITCH then
        SetCamRot(camera, vector3(pitch, rotation.y, yaw), 2)
    end

    SetEntityHeading(entity, math.max(0, rotation.z % 360))
end

---@param rotation vector3
---@return vector3 forward
---@return vector3 right
local function directions(rotation)
    local pitch <const> = math.rad(rotation.x)
    local yaw <const> = math.rad(rotation.z)
    local forward <const> = vector3(-math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch), math.sin(pitch))
    local right <const> = vector3(math.cos(yaw), math.sin(yaw), 0.0)

    return forward, right
end

local function step()
    rotateCamera()
    disableControls()

    if held(SPEED_DECREASE) then
        speed = math.max(0.5, speed - 0.5)
    elseif held(SPEED_INCREASE) then
        speed = math.min(MAX_SPEED, speed + 0.5)
    elseif IsDisabledControlJustReleased(0, SPEED_RESET) then
        speed = 1.0
    end

    local multiplier <const> = held(SPEED_FAST) and 2.0
        or held(SPEED_FASTER) and 4.0
        or held(SPEED_SLOW) and 0.25
        or 1.0
    local distance <const> = METERS_PER_SECOND * speed * multiplier * GetFrameTime()
    local forward <const>, right <const> = directions(GetCamRot(camera, 2))
    local offset = vector3(0.0, 0.0, 0.0)

    if held(MOVE_FORWARDS) then
        offset += forward
    elseif held(MOVE_BACKWARDS) then
        offset -= forward
    end

    if held(MOVE_LEFT) then
        offset -= right
    elseif held(MOVE_RIGHT) then
        offset += right
    end

    if held(MOVE_UP) then
        offset += UP
    elseif held(MOVE_DOWN) then
        offset -= UP
    end

    local coords <const> = GetEntityCoords(entity) + offset * distance
    SetEntityCoordsNoOffset(entity, coords.x, coords.y, coords.z, true, true, true)
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    SetLocalPlayerVisibleLocally(true)
end

local function detach()
    FreezeEntityPosition(entity, true)
    SetEntityCollision(entity, false, false)
    SetEntityVisible(entity, false, false)
    SetEntityInvincible(entity, true)
    SetEntityAlpha(entity, 51, false)
    SetEveryoneIgnorePlayer(cache.playerId, true)
    SetPoliceIgnorePlayer(cache.playerId, true)
end

local function restore()
    FreezeEntityPosition(entity, false)
    SetEntityCollision(entity, true, true)
    SetEntityVisible(entity, true, false)
    SetLocalPlayerVisibleLocally(true)
    ResetEntityAlpha(entity)
    ResetEntityAlpha(cache.ped)
    SetEveryoneIgnorePlayer(cache.playerId, false)
    SetPoliceIgnorePlayer(cache.playerId, false)
end

local function snapToGround()
    local coords <const> = GetEntityCoords(entity)
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)

    local found <const>, groundZ <const> = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 1.0, false)

    if found then
        SetEntityCoords(entity, coords.x, coords.y, groundZ, false, false, false, false)
    end
end

local function landThenMortal()
    local landed <const> = inVehicle and IsVehicleOnAllWheels or function(ped)
        return not IsPedFalling(ped) and not IsPedRagdoll(ped)
    end
    local landing <const> = entity

    CreateThread(function()
        local deadline <const> = GetGameTimer() + 10000

        while not active and not landed(landing) and GetGameTimer() < deadline do
            Wait(0)
        end

        if not active then
            SetEntityInvincible(landing, false)
        end
    end)
end

---@return boolean
function noclip.active()
    return active
end

---@param state boolean
function noclip.set(state)
    if state == active then return end

    active = state

    local ped <const> = cache.ped
    local vehicle <const> = cache.vehicle
    inVehicle = vehicle and GetPedInVehicleSeat(vehicle, -1) == ped or false
    entity = inVehicle and vehicle --[[@as integer]] or ped

    if active then
        if inVehicle then
            SetVehicleEngineOn(entity, false, true, true)
        else
            ClearPedTasksImmediately(ped)
        end

        createCamera()
        detach()
        PlaySoundFromEntity(-1, 'SELECT', ped, 'HUD_LIQUOR_STORE_SOUNDSET', false, 0)
        SetUserRadioControlEnabled(false)

        CreateThread(function()
            while active do
                step()
                Wait(0)
            end
        end)

        return
    end

    snapToGround()
    destroyCamera()
    restore()

    if inVehicle then
        SetVehicleEngineOn(entity, true, true, false)
    end

    PlaySoundFromEntity(-1, 'CANCEL', ped, 'HUD_LIQUOR_STORE_SOUNDSET', false, 0)
    SetUserRadioControlEnabled(true)
    landThenMortal()
end

function noclip.stop()
    noclip.set(false)
end

return noclip
