local VEHICLE_SPRITES <const> = {
    [8] = 226, [9] = 757, [10] = 477, [11] = 477, [12] = 67, [13] = 226, [14] = 427,
    [15] = 422, [16] = 423, [17] = 198, [18] = 56, [19] = 421, [20] = 477,
}

local REFRESH_INTERVAL <const> = 5000

local overlay <const> = {}

local showBlips = false
local showNames = false
local running = false

---@type table<integer, string>
local characterNames <const> = {}
---@class OverlayMarker
---@field handle integer
---@field ped integer

---@type table<integer, OverlayMarker>
local tags <const> = {}
---@type table<integer, OverlayMarker>
local blips <const> = {}

local function refreshNames()
    local rows <const> = lib.callback.await('cobalt_adminmenu:server:getPlayers', false) or {}

    table.wipe(characterNames)

    for _, row in ipairs(rows) do
        characterNames[row.id] = row.name
    end
end

---@param serverId integer
---@param player integer
---@param ped integer
local function updateTag(serverId, player, ped)
    local marker <const> = tags[serverId]
    local tag = marker?.handle

    if marker and (marker.ped ~= ped or not IsMpGamerTagActive(tag)) then
        RemoveMpGamerTag(tag)
        tag = nil
    end

    if not tag then
        tag = CreateFakeMpGamerTag(
            ped,
            ('%d | %s'):format(serverId, characterNames[serverId] or GetPlayerName(player)),
            false,
            false,
            '',
            0
        )
        SetMpGamerTagHealthBarColour(tag, 25)
        tags[serverId] = { handle = tag, ped = ped }
    end

    SetMpGamerTagVisibility(tag, 0, true)
    SetMpGamerTagVisibility(tag, 2, true)
    SetMpGamerTagAlpha(tag, 2, 255)
    SetMpGamerTagVisibility(tag, 4, NetworkIsPlayerTalking(player))
    SetMpGamerTagVisibility(tag, 6, GetPlayerInvincible(player))
end

---@param serverId integer
---@param player integer
---@param ped integer
local function updateBlip(serverId, player, ped)
    local marker <const> = blips[serverId]
    local blip = marker?.handle

    if marker and (marker.ped ~= ped or not DoesBlipExist(blip)) then
        RemoveBlip(blip)
        blip = nil
    end

    if not blip then
        blip = AddBlipForEntity(ped)
        SetBlipCategory(blip, 7)
        SetBlipScale(blip, 0.85)
        blips[serverId] = { handle = blip, ped = ped }
    end

    local vehicle <const> = GetVehiclePedIsIn(ped, false)

    if vehicle ~= 0 then
        SetBlipSprite(blip, VEHICLE_SPRITES[GetVehicleClass(vehicle)] or 225)
        ShowHeadingIndicatorOnBlip(blip, false)
        ShowNumberOnBlip(blip, GetVehicleNumberOfPassengers(vehicle) + (IsVehicleSeatFree(vehicle, -1) and 0 or 1))
    else
        SetBlipSprite(blip, IsEntityDead(ped) and 274 or 1)
        ShowHeadingIndicatorOnBlip(blip, true)
        HideNumberOnBlip(blip)
    end

    SetBlipNameToPlayerName(blip, player)
end

local function clear()
    for id, tag in pairs(tags) do
        RemoveMpGamerTag(tag.handle)
        tags[id] = nil
    end

    for id, blip in pairs(blips) do
        RemoveBlip(blip.handle)
        blips[id] = nil
    end
end

---@param seen table<integer, true>
local function prune(seen)
    for id, tag in pairs(tags) do
        if not seen[id] or not showNames then
            RemoveMpGamerTag(tag.handle)
            tags[id] = nil
        end
    end

    for id, blip in pairs(blips) do
        if not seen[id] or not showBlips then
            RemoveBlip(blip.handle)
            blips[id] = nil
        end
    end
end

local function run()
    if running then return end

    running = true

    CreateThread(function()
        local nextRefresh = 0

        while showBlips or showNames do
            if GetGameTimer() >= nextRefresh then
                refreshNames()
                nextRefresh = GetGameTimer() + REFRESH_INTERVAL
            end

            local seen <const> = {}

            for _, player in ipairs(GetActivePlayers()) do
                if player ~= cache.playerId then
                    local serverId <const> = GetPlayerServerId(player)
                    local ped <const> = GetPlayerPed(player)
                    seen[serverId] = true

                    if showNames then
                        updateTag(serverId, player, ped)
                    end

                    if showBlips then
                        updateBlip(serverId, player, ped)
                    end
                end
            end

            prune(seen)
            Wait(1000)
        end

        clear()
        running = false
    end)
end

---@return boolean
function overlay.toggleBlips()
    showBlips = not showBlips
    run()

    return showBlips
end

---@return boolean
function overlay.toggleNames()
    showNames = not showNames
    run()

    return showNames
end

function overlay.reset()
    showBlips = false
    showNames = false
    clear()
end

return overlay
