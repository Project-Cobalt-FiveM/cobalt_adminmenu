local config <const> = require 'config'
local catalog <const> = require 'shared.actions'
local actions <const> = require 'client.actions'
local effects <const> = require 'client.effects'
local labels <const> = require 'shared.labels'

---@class CurrentVehicle
---@field label string
---@field model string
---@field plate string
---@field netId integer
---@field owner? string
---@field engine integer
---@field body integer
---@field fuel integer

---@class AdminServerSnapshot
---@field rank AdminRank
---@field name string
---@field online integer
---@field staffOnDuty integer
---@field receivingReports boolean
---@field reports table[]
---@field staffChat table[]
---@field build string
---@field uptime integer

---@class AdminCatalogEntry : AdminAction
---@field allowed boolean

---@class AdminActionResult
---@field ok boolean
---@field message? string

local isOpen = false

---@type CKeybind
local noclipKeybind

---@param action string
---@param data? any
local function send(action, data)
    SendNUIMessage({ action = action, data = data })
end

---@param rank AdminRank
---@return AdminCatalogEntry[]
local function catalogFor(rank)
    local list <const> = {}

    for _, action in ipairs(catalog.list) do
        local allowed <const> = catalog.actionAllows(rank, action)

        if not action.hidden and (allowed or rank ~= 'tester') then
            local entry <const> = table.clone(action)
            entry.allowed = allowed
            list[#list + 1] = entry
        end
    end

    return list
end

---@return AdminOption[]
local function quickLocations()
    local options <const> = {}

    for i, location in ipairs(config.QuickLocations) do
        options[i] = { label = labels.of('locations', location.name), value = ('quick:%d'):format(i) }
    end

    return options
end

---@type table<string, string>?
local uiStrings

---@return table<string, string>
local function uiLocales()
    if uiStrings then return uiStrings end

    local strings <const> = {}

    for key, value in pairs(lib.getLocales()) do
        if key:sub(1, 3) == 'ui.' then
            strings[key] = value
        end
    end

    uiStrings = strings
    return strings
end

---@param hidden boolean
local function hideHud(hidden)
    LocalPlayer.state:set('hideHud', hidden, false)
end

local function openMenu()
    if isOpen then return end

    local server <const> = lib.callback.await('cobalt_adminmenu:server:open', false) --[[@as AdminServerSnapshot?]]

    if not server then return end

    isOpen = true
    hideHud(true)
    SetNuiFocus(true, true)

    send('open', {
        rank = server.rank,
        self = { id = cache.serverId, name = server.name },
        actions = catalogFor(server.rank),
        toggles = actions.toggles,
        online = server.online,
        staffOnDuty = server.staffOnDuty,
        receivingReports = server.receivingReports,
        reports = server.reports,
        staffChat = server.staffChat,
        keys = { noclip = noclipKeybind:getCurrentKey() },
        quickLocations = quickLocations(),
        build = server.build,
        uptime = server.uptime,
        locales = uiLocales(),
    })
end

local function closeMenu()
    if not isOpen then return end

    isOpen = false
    SetNuiFocus(false, false)
    send('close')
    hideHud(false)
end

---@param toggles table<string, boolean>
actions.onToggle = function(toggles)
    if isOpen then
        send('toggles', toggles)
    end
end

---@param name string
---@param args? table
---@return AdminActionResult
local function runAction(name, args)
    return lib.callback.await('cobalt_adminmenu:server:action', false, name, args) or { ok = false }
end

---@return CurrentVehicle?
local function currentVehicle()
    local vehicle <const> = cache.vehicle

    if not vehicle then return end

    local model <const> = GetEntityModel(vehicle)
    local shared <const> = exports.cobalt_core:GetShared('VehicleHashes', model)
    local plate <const> = exports.cobalt_core:GetPlate(vehicle)

    return {
        label = shared?.name or GetLabelText(GetDisplayNameFromVehicleModel(model)),
        model = shared?.model or tostring(model),
        plate = plate,
        netId = VehToNet(vehicle),
        owner = lib.callback.await('cobalt_adminmenu:server:vehicleOwner', false, plate),
        engine = math.floor(GetVehicleEngineHealth(vehicle)),
        body = math.floor(GetVehicleBodyHealth(vehicle)),
        fuel = math.floor(Entity(vehicle).state.fuel or GetVehicleFuelLevel(vehicle)),
    }
end

---@param name string
---@param handler fun(data: table): any
local function nui(name, handler)
    RegisterNUICallback(name, function(data, cb)
        cb(handler(data or {}))
    end)
end

---@param name string
local function relay(name)
    nui(name, function(data)
        return lib.callback.await('cobalt_adminmenu:server:' .. name, false, data.id)
    end)
end

nui('close', function()
    closeMenu()

    return true
end)

nui('action', function(data)
    return runAction(data.name, data.args)
end)

relay('getPlayers')
relay('getPlayer')
relay('getWarnings')
relay('getLists')
relay('getResources')
relay('getWorld')
relay('getCommands')

nui('getVehicle', currentVehicle)

nui('sendStaffChat', function(data)
    return lib.callback.await('cobalt_adminmenu:server:sendStaffChat', false, data.message) == true
end)

nui('runCommand', function(data)
    local command <const> = tostring(data.name or ''):gsub('^/', '')

    if command == '' then return false end

    closeMenu()
    ExecuteCommand(command)

    return true
end)

RegisterNetEvent('cobalt_adminmenu:client:open', openMenu)

for _, name in ipairs({ 'reports', 'staffChat', 'world' }) do
    RegisterNetEvent('cobalt_adminmenu:client:' .. name, function(data)
        if isOpen then
            send(name, data)
        end
    end)
end

lib.addKeybind({
    name = 'cobalt_adminmenu',
    description = locale('keybinds.open_menu'),
    defaultKey = config.OpenKey,
    onPressed = openMenu,
})

noclipKeybind = lib.addKeybind({
    name = 'cobalt_adminmenu_noclip',
    description = locale('keybinds.toggle_noclip'),
    defaultKey = config.NoclipKey,
    onPressed = function()
        runAction('noclip')
    end,
})

local function reset()
    closeMenu()
    effects.reset()
    actions.reset()
end

RegisterNetEvent('cobalt_core:Client:OnPlayerUnload', reset)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        reset()
    end
end)
