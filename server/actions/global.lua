local Cobalt <const> = exports.cobalt_core:GetCoreObject()
local config <const> = require 'config'
local access <const> = require 'server.access'
local args <const> = require 'server.args'
local db <const> = require 'server.db'
local labels <const> = require 'shared.labels'
local players <const> = require 'server.players'
local reports <const> = require 'server.reports'
local vehicles <const> = require 'server.vehicles'
local world <const> = require 'server.world'

local weather <const> = exports.cobalt_weather

local MAX_PROPS_BYTES <const> = 16384

---@type table<string, AdminHandler>
local handlers <const> = {}

---@param value unknown
---@return string?
local function plateOf(value)
    local plate <const> = args.trim(value):upper()

    if plate == '' or #plate > 8 then return end

    return plate
end

---@param source integer
---@return integer?
local function vehicleOf(source)
    local vehicle <const> = GetVehiclePedIsIn(GetPlayerPed(source), false)

    return vehicle ~= 0 and vehicle or nil
end

---@param source integer
local function pushWorld(source)
    TriggerClientEvent('cobalt_adminmenu:client:world', source, world.state())
end

handlers.spawnVehicle = function(source, input)
    if type(input.model) ~= 'string' or input.model == '' then
        return false, locale('vehicles.pick_vehicle')
    end

    return vehicles.spawn(source, input.model)
end

handlers.setAmmo = function(source, input)
    local amount <const> = math.tointeger(tonumber(input.amount))

    if not amount or amount < 0 then
        return false, locale('self.enter_rounds')
    end

    local ok <const>, reason <const> = exports.cobalt_inventory:SetWeaponAmmo(source, amount)

    if not ok then return false, reason end

    return true, locale('self.ammo_set', amount)
end

handlers.deleteEntity = function(_, input)
    local netId <const> = math.tointeger(tonumber(input.netId))
    local entity <const> = netId and NetworkGetEntityFromNetworkId(netId) or 0

    if entity == 0 or not DoesEntityExist(entity) then
        return false, locale('notify.entity_delete_failed')
    end

    if GetEntityType(entity) == 1 and IsPedAPlayer(entity) then
        return false, locale('notify.entity_is_player')
    end

    input.model = GetEntityModel(entity)
    DeleteEntity(entity)

    return true, locale('notify.entity_deleted')
end

handlers.refuelVehicle = function(source)
    local vehicle <const> = vehicleOf(source)

    if not vehicle then
        return false, locale('common.not_in_vehicle')
    end

    Entity(vehicle).state:set('fuel', 100.0, true)

    return true, locale('vehicles.refuelled')
end

handlers.deleteVehicle = function(source)
    local vehicle <const> = vehicleOf(source)

    if not vehicle then
        return false, locale('common.not_in_vehicle')
    end

    DeleteEntity(vehicle)

    return true, locale('vehicles.deleted')
end

handlers.changePlate = function(source, input)
    local vehicle <const> = vehicleOf(source)

    if not vehicle then
        return false, locale('common.not_in_vehicle')
    end

    local plate <const> = plateOf(input.plate)

    if not plate then
        return false, locale('vehicles.plate_length')
    end

    if exports.cobalt_core:GetVehicleOwnerByPlate(plate) then
        return false, locale('vehicles.plate_taken', plate)
    end

    local oldPlate <const> = args.trim(GetVehicleNumberPlateText(vehicle))

    db.changePlate(oldPlate, plate)
    SetVehicleNumberPlateText(vehicle, plate)
    exports.cobalt_vehiclekeys:RemoveKeys(oldPlate)
    exports.cobalt_vehiclekeys:GiveKey(source, plate, vehicle)

    return true, locale('vehicles.plate_changed', plate)
end

---@param source integer
---@return table?
local function vehiclePropsOf(source)
    local ok <const>, props <const> = pcall(lib.callback.await, 'cobalt_adminmenu:client:vehicleProps', source)

    if not ok or type(props) ~= 'table' or #json.encode(props) > MAX_PROPS_BYTES then return end

    return props
end

handlers.saveVehicle = function(source, input)
    local vehicle <const> = vehicleOf(source)

    if not vehicle then
        return false, locale('common.not_in_vehicle')
    end

    local hash <const> = GetEntityModel(vehicle)
    local shared <const> = exports.cobalt_core:GetShared('VehicleHashes', hash)

    if not shared then
        return false, locale('notify.model_not_listed')
    end

    local plate <const> = plateOf(GetVehicleNumberPlateText(vehicle))

    if not plate then
        return false, locale('vehicles.plate_length')
    end

    local player <const> = players.get(source)

    if not player then
        return false, locale('vehicles.not_saved')
    end

    local owner <const> = exports.cobalt_core:GetVehicleOwnerByPlate(plate)

    if owner == player.PlayerData.citizenid then
        return false, locale('vehicles.already_yours')
    end

    if owner then
        return false, locale('vehicles.plate_taken', plate)
    end

    local props <const> = vehiclePropsOf(source)

    if not props or vehicleOf(source) ~= vehicle then
        return false, locale('vehicles.not_saved')
    end

    props.model = hash
    props.plate = plate

    local inserted <const> = db.insertVehicle({
        license = player.PlayerData.license,
        citizenid = player.PlayerData.citizenid,
        model = shared.model,
        mods = props,
        plate = plate,
        garage = config.DefaultGarage,
        state = 0,
    })

    if not inserted then
        return false, locale('vehicles.plate_taken', plate)
    end

    exports.cobalt_vehiclekeys:GiveKey(source, plate, vehicle)
    input.model = shared.model
    input.plate = plate

    return true, locale('vehicles.saved')
end

handlers.openTrunk = function(source, input)
    local plate <const> = plateOf(input.plate)

    if not plate then
        return false, locale('vehicles.enter_plate')
    end

    if not exports.cobalt_inventory:OpenTrunk(source, plate, db.getVehicleModel(plate)) then
        return false, locale('vehicles.no_trunk', plate)
    end

    return true
end

---@param state integer
---@return AdminHandler
local function markGarage(state)
    return function(_, input)
        local plate <const> = plateOf(input.plate)

        if not plate or not db.setVehicleState(plate, state) then
            return false, locale('vehicles.no_owned_plate')
        end

        return true, state == 1 and locale('vehicles.marked_in_garage', plate) or locale('vehicles.marked_out', plate)
    end
end

handlers.markInGarage = markGarage(1)
handlers.markOut = markGarage(0)

handlers.setWeather = function(source, input)
    if not weather:SetWeather(input.weather) then
        return false, locale('world.pick_weather')
    end

    pushWorld(source)

    return true
end

handlers.setTime = function(source, input)
    if not weather:SetTime(math.tointeger(tonumber(input.hour)), 0) then
        return false, locale('world.pick_time')
    end

    pushWorld(source)

    return true
end

---@param apply fun(enabled: boolean)
---@return AdminHandler
local function worldToggle(apply)
    return function(source, input)
        if type(input.enabled) ~= 'boolean' then
            return false, locale('world.pick_toggle')
        end

        apply(input.enabled)
        pushWorld(source)

        return true
    end
end

handlers.freezeTime = worldToggle(function(enabled) weather:FreezeTime(enabled) end)
handlers.dynamicWeather = worldToggle(function(enabled) weather:FreezeWeather(not enabled) end)
handlers.blackout = worldToggle(function(enabled) weather:SetBlackout(enabled) end)

handlers.announce = function(_, input)
    local message <const> = type(input.message) == 'string' and input.message or ''

    if message == '' then
        return false, locale('server.write_message')
    end

    TriggerClientEvent(
        'chat:addMessage',
        -1,
        { color = { 255, 0, 0 }, multiline = true, args = { locale('server.announcement_author'), message } }
    )

    return true, locale('server.announcement_sent')
end

handlers.reviveAll = function()
    for _, source in ipairs(Cobalt.Functions.GetPlayers()) do
        exports.cobalt_ambulancejob:RevivePlayer(source)
    end

    return true, locale('server.revived_all')
end

handlers.reviveRadius = function(source)
    local origin <const> = GetEntityCoords(GetPlayerPed(source))
    local bucket <const> = GetPlayerRoutingBucket(source)
    local count = 0

    for _, target in ipairs(Cobalt.Functions.GetPlayers()) do
        local nearby <const> = #(GetEntityCoords(GetPlayerPed(target)) - origin) <= config.ReviveRadius

        if nearby and GetPlayerRoutingBucket(target) == bucket then
            exports.cobalt_ambulancejob:RevivePlayer(target)
            count += 1
        end
    end

    return true, locale('server.revived_radius', count)
end

handlers.giveItemAll = function(_, input)
    local amount <const> = math.tointeger(tonumber(input.amount))

    if not amount or amount < 1 then
        return false, locale('common.amount_above_zero')
    end

    if not exports.cobalt_inventory:GetItemDef(input.item) then
        return false, locale('common.unknown_item', input.item)
    end

    for _, target in ipairs(Cobalt.Functions.GetPlayers()) do
        exports.cobalt_inventory:AddItem(target, input.item, amount, nil, nil, 'cobalt_adminmenu')
    end

    return true, locale('server.gave_item_all', amount, input.item)
end

handlers.giveMoneyAll = function(_, input)
    local account <const>, amount <const> = args.money(input)

    if not account then
        return false, locale('common.account_and_amount')
    end

    for _, target in ipairs(Cobalt.Functions.GetPlayers()) do
        local player <const> = Cobalt.Functions.GetPlayer(target)

        if player then
            player.Functions.AddMoney(account, amount, 'cobalt_adminmenu')
        end
    end

    return true, locale('server.gave_money_all', amount, labels.of('accounts', account))
end

handlers.kickAll = function(_, input)
    local reason <const> = args.trim(input.reason)

    if reason == '' then
        return false, locale('common.give_reason')
    end

    local message <const> = locale('players.kick_reason', reason)

    for _, playerId in ipairs(GetPlayers()) do
        local target <const> = tonumber(playerId) --[[@as integer]]

        if not access.rank(target) then
            Cobalt.Functions.Kick(target, message)
        end
    end

    return true, locale('server.kicked_all')
end

handlers.unban = function(source, input)
    local term <const> = type(input.ban) == 'string' and args.trim(input.ban) or tostring(input.ban or '')

    if term == '' then
        return false, locale('server.enter_ban')
    end

    local removed <const> = exports.cobalt_core:Unban(term, not access.allows(source, 'owner') and config.PermanentBan or nil)

    if removed == 0 then
        return false, locale('server.ban_not_found')
    end

    return true, locale('server.bans_removed', removed)
end

handlers.deleteWarning = function(_, input)
    local id <const> = math.tointeger(tonumber(input.warning))

    if not id or not db.deleteWarn(id) then
        return false, locale('warnings.not_found')
    end

    return true, locale('warnings.deleted', id)
end

handlers.clearInventoryOffline = function(_, input)
    local citizenid <const> = type(input.citizenid) == 'string' and input.citizenid:upper() or ''
    local online <const> = Cobalt.Functions.GetPlayerByCitizenId(citizenid)

    if online then
        exports.cobalt_inventory:ClearInventory(online.PlayerData.source)

        return true, locale('common.inventory_cleared', players.name(online))
    end

    if not exports.cobalt_core:GetName(citizenid) then
        return false, locale('server.no_citizen')
    end

    exports.cobalt_inventory:ClearInventory(citizenid)

    return true, locale('common.inventory_cleared', citizenid)
end

handlers.openStash = function(source, input)
    if type(input.stash) ~= 'string' or not exports.cobalt_inventory:OpenStash(source, input.stash, nil, true) then
        return false, locale('server.no_stash')
    end

    return true
end

---@type table<string, true>
local resourceStates <const> = { start = true, stop = true, restart = true }

handlers.resource = function(_, input)
    local name <const> = input.name

    if type(name) ~= 'string' or GetResourceState(name) == 'missing' then
        return false, locale('server.unknown_resource')
    end

    if not resourceStates[input.state] then
        return false, locale('server.unknown_state')
    end

    if name == cache.resource and input.state ~= 'restart' then
        return false, locale('server.stop_from_console')
    end

    if input.state == 'start' then
        StartResource(name)
    elseif input.state == 'stop' then
        StopResource(name)
    else
        StopResource(name)
        StartResource(name)
    end

    return true, locale('server.resource_state', name, input.state)
end

handlers.receiveReports = function(source, input)
    if input.enabled ~= Cobalt.Functions.IsOptin(source) then
        Cobalt.Functions.ToggleOptin(source)
    end

    local on <const> = Cobalt.Functions.IsOptin(source)

    return true, on and locale('reports.receiving_on') or locale('reports.receiving_off')
end

---@param input table
---@return Report?
local function reportOf(input)
    return reports.find(math.tointeger(tonumber(input.report)) or -1)
end

handlers.reportGoto = function(source, input)
    local report <const> = reportOf(input)

    if not report or not players.get(report.source) then
        return false, locale('reports.reporter_gone')
    end

    players.teleportTo(source, report.source)

    return true
end

handlers.reportReply = function(source, input)
    local report <const> = reportOf(input)
    local message <const> = type(input.message) == 'string' and input.message or ''

    if not report then
        return false, locale('reports.closed')
    end

    if message == '' then
        return false, locale('reports.write_reply')
    end

    TriggerClientEvent(
        'chat:addMessage',
        report.source,
        { color = { 255, 0, 0 }, multiline = true, args = { locale('reports.response_author'), message } }
    )

    reports.say(source, locale('reports.reply_to', report.id, message))

    return true, locale('reports.reply_sent')
end

handlers.reportClose = function(_, input)
    local report <const> = reportOf(input)

    if not report or not reports.close(report.id) then
        return false, locale('reports.closed')
    end

    return true
end

return handlers
