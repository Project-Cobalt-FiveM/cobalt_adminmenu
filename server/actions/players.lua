local Cobalt <const> = exports.cobalt_core:GetCoreObject()
local config <const> = require 'config'
local args <const> = require 'server.args'
local db <const> = require 'server.db'
local labels <const> = require 'shared.labels'
local players <const> = require 'server.players'
local access <const> = require 'server.access'
local vehicles <const> = require 'server.vehicles'

local DRUNK_ALCOHOL <const> = 60

---@alias AdminHandler fun(source: integer, args: table): boolean, string?

---@type table<integer, integer> spectating admin to the routing bucket they were in before
local spectateBuckets <const> = {}

---@param admin integer
local function endSpectate(admin)
    local bucket <const> = spectateBuckets[admin]

    spectateBuckets[admin] = nil

    if bucket then exports.cobalt_core:SetPlayerBucket(admin, bucket) end
end

RegisterNetEvent('cobalt_adminmenu:server:spectateEnded', function()
    endSpectate(source)
end)

AddEventHandler('cobalt_core:Server:OnPlayerUnload', endSpectate)

AddEventHandler('playerDropped', function()
    spectateBuckets[source] = nil
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for admin, bucket in pairs(spectateBuckets) do exports.cobalt_core:SetPlayerBucket(admin, bucket) end
    for _, ped in pairs(players.frozen) do
        if DoesEntityExist(ped) then FreezeEntityPosition(ped, false) end
    end
    for target in pairs(players.muted) do MumbleSetPlayerMuted(target, false) end
end)

---@param source integer
---@return boolean
local function revive(source)
    return exports.cobalt_ambulancejob:RevivePlayer(source) == true
end

---@param target integer
---@param actor integer
---@return boolean
local function outranks(target, actor)
    if target == actor or access.allows(actor, 'owner') then return false end

    local actorRank <const> = access.rank(actor)

    return actorRank ~= nil and access.allows(target, actorRank)
end

---@param handler fun(source: integer, target: table, args: table): boolean, string?
---@return AdminHandler
local function onPlayer(handler)
    return function(source, input)
        local target <const> = players.get(input.target)

        if not target then
            return false, locale('players.not_online', input.target)
        end

        if outranks(target.PlayerData.source, source) then
            return false, locale('players.rank_too_low')
        end

        return handler(source, target, input)
    end
end

---@param seconds integer
---@return string
local function expiryText(seconds)
    if seconds >= config.PermanentBan then
        return locale('players.ban_permanent')
    end

    return locale('players.ban_expires', os.date('%d/%m/%Y %H:%M', seconds))
end

---@type table<string, AdminHandler>
local handlers <const> = {}

handlers.reviveSelf = function(source)
    if not revive(source) then
        return false, locale('players.revive_self_failed')
    end

    return true
end

handlers['goto'] = onPlayer(function(source, target)
    players.teleportTo(source, target.PlayerData.source)

    return true
end)

handlers.bring = onPlayer(function(source, target)
    local targetId <const> = target.PlayerData.source

    players.joinBucket(targetId, source)
    SetEntityCoords(GetPlayerPed(targetId), GetEntityCoords(GetPlayerPed(source)), false, false, false, false)

    return true
end)

handlers.spectate = onPlayer(function(source, target)
    local targetId <const> = target.PlayerData.source

    if targetId == source then
        return false, locale('players.spectate_self')
    end

    spectateBuckets[source] = spectateBuckets[source] or GetPlayerRoutingBucket(source)
    players.joinBucket(source, targetId)
    TriggerClientEvent('cobalt_adminmenu:client:spectate', source, targetId, GetEntityCoords(GetPlayerPed(targetId)))

    return true
end)

handlers.intoVehicle = onPlayer(function(source, target)
    local vehicle <const> = GetVehiclePedIsIn(GetPlayerPed(target.PlayerData.source), false)

    if vehicle == 0 then
        return false, locale('players.not_in_vehicle')
    end

    for seat = 0, 8 do
        if GetPedInVehicleSeat(vehicle, seat) == 0 then
            players.joinBucket(source, target.PlayerData.source)
            SetPedIntoVehicle(GetPlayerPed(source), vehicle, seat)

            return true
        end
    end

    return false, locale('players.no_free_seats')
end)

handlers.setBucket = onPlayer(function(_, target, input)
    local bucket <const> = math.tointeger(tonumber(input.bucket))

    if not bucket or bucket < 0 then
        return false, locale('players.enter_bucket')
    end

    exports.cobalt_core:SetPlayerBucket(target.PlayerData.source, bucket)

    return true, locale('players.bucket_moved', players.name(target), bucket)
end)

handlers.revive = onPlayer(function(_, target)
    if not revive(target.PlayerData.source) then
        return false, locale('players.revive_failed', players.name(target))
    end

    return true, locale('players.revived', players.name(target))
end)

handlers.heal = onPlayer(function(_, target)
    local targetId <const> = target.PlayerData.source

    exports.cobalt_core:SetNeed(targetId, 'hunger', 100)
    exports.cobalt_core:SetNeed(targetId, 'thirst', 100)
    TriggerClientEvent('cobalt_adminmenu:client:heal', targetId)

    return true, locale('players.healed', players.name(target))
end)

handlers.freeze = onPlayer(function(_, target)
    local targetId <const> = target.PlayerData.source
    local ped <const> = GetPlayerPed(targetId)
    local frozen <const> = not players.isFrozen(targetId)

    players.frozen[targetId] = frozen and ped or nil
    FreezeEntityPosition(ped, frozen)

    return true, frozen and locale('players.froze', players.name(target)) or locale('players.unfroze', players.name(target))
end)

handlers.cuff = onPlayer(function(source, target)
    local targetId <const> = target.PlayerData.source

    if exports.cobalt_police:IsCuffed(targetId) then
        exports.cobalt_police:Uncuff(targetId)

        return true, locale('players.uncuffed', players.name(target))
    end

    local admin <const> = players.get(source)

    exports.cobalt_police:Cuff(targetId, 'cuffs', admin?.PlayerData.citizenid or 'admin')

    return true, locale('players.cuffed', players.name(target))
end)

handlers.removeStress = onPlayer(function(_, target)
    exports.cobalt_hud:SetStress(target.PlayerData.source, 0)

    return true, locale('players.stress_removed', players.name(target))
end)

handlers.mute = onPlayer(function(_, target)
    local targetId <const> = target.PlayerData.source
    local muted <const> = not players.muted[targetId]

    players.muted[targetId] = muted or nil
    MumbleSetPlayerMuted(targetId, muted)

    return true, muted and locale('players.muted', players.name(target)) or locale('players.unmuted', players.name(target))
end)

handlers.nuiFocus = onPlayer(function(_, target, input)
    TriggerClientEvent('cobalt_adminmenu:client:nuiFocus', target.PlayerData.source, input.focus == true, input.mouse == true)

    return true, locale('players.nui_focus', players.name(target))
end)

handlers.kill = onPlayer(function(_, target)
    if not exports.cobalt_ambulancejob:KillPlayer(target.PlayerData.source) then
        return false, locale('players.already_dead', players.name(target))
    end

    return true
end)

---@param kind 'Jobs'|'Gangs'
---@return AdminHandler
local function setOrg(kind)
    local key <const> = kind == 'Jobs' and 'job' or 'gang'

    return onPlayer(function(_, target, input)
        local name <const> = tostring(input[key] or '')
        local grade <const> = math.tointeger(tonumber(input.grade)) or 0
        local org <const> = exports.cobalt_core:GetShared(kind, name)

        if not org or not org.grades[tostring(grade)] then
            return false, kind == 'Jobs' and locale('players.pick_job') or locale('players.pick_gang')
        end

        local targetId <const> = target.PlayerData.source
        local changed

        if kind == 'Jobs' then
            changed = exports.cobalt_management:SetJob(targetId, name, grade)
        else
            changed = exports.cobalt_management:SetGang(targetId, name, grade)
        end

        if not changed then
            return false, locale('players.org_refused')
        end

        return true, locale('players.org_set', players.name(target), org.label, org.grades[tostring(grade)].name)
    end)
end

handlers.setJob = setOrg('Jobs')
handlers.setGang = setOrg('Gangs')

handlers.setDuty = onPlayer(function(_, target, input)
    local targetId <const> = target.PlayerData.source
    local job <const> = exports.cobalt_management:GetJob(targetId)

    if not job then
        return false, locale('players.no_job', players.name(target))
    end

    local onDuty <const> = type(input.onDuty) == 'boolean' and input.onDuty or not job.onduty

    if not exports.cobalt_management:SetDuty(targetId, onDuty) then
        return false, locale('players.org_refused')
    end

    return true, locale(onDuty and 'players.duty_on' or 'players.duty_off', players.name(target), job.label)
end)

handlers.setPed = onPlayer(function(_, target, input)
    if type(input.model) ~= 'string' or input.model == '' then
        return false, locale('players.pick_ped')
    end

    TriggerClientEvent('cobalt_adminmenu:client:setPed', target.PlayerData.source, input.model)

    return true
end)

handlers.clothing = onPlayer(function(_, target)
    TriggerClientEvent('qb-clothing:client:openMenu', target.PlayerData.source)

    return true
end)

handlers.openInventory = onPlayer(function(source, target)
    exports.cobalt_inventory:OpenPlayerInventory(source, target.PlayerData.source)

    return true
end)

handlers.giveItem = onPlayer(function(_, target, input)
    local amount <const> = math.tointeger(tonumber(input.amount))

    if not amount or amount < 1 then
        return false, locale('common.amount_above_zero')
    end

    if not exports.cobalt_inventory:GetItemDef(input.item) then
        return false, locale('common.unknown_item', input.item)
    end

    local targetId <const> = target.PlayerData.source
    local added <const> = exports.cobalt_inventory:AddItem(targetId, input.item, amount, nil, nil, 'cobalt_adminmenu')

    if not added then
        return false, locale('players.inventory_full')
    end

    return true, locale('players.gave_item', amount, input.item, players.name(target))
end)

handlers.clearInventory = onPlayer(function(_, target)
    exports.cobalt_inventory:ClearInventory(target.PlayerData.source)

    return true, locale('common.inventory_cleared', players.name(target))
end)

handlers.giveMoney = onPlayer(function(_, target, input)
    local account <const>, amount <const> = args.money(input)

    if not account then
        return false, locale('common.account_and_amount')
    end

    target.Functions.AddMoney(account, amount, 'cobalt_adminmenu')

    return true, locale('players.gave_money', amount, labels.of('accounts', account), players.name(target))
end)

handlers.removeMoney = onPlayer(function(_, target, input)
    local account <const>, amount <const> = args.money(input)

    if not account then
        return false, locale('common.account_and_amount')
    end

    if not target.Functions.RemoveMoney(account, amount, 'cobalt_adminmenu') then
        return false, locale('players.not_enough_money')
    end

    return true, locale('players.took_money', amount, labels.of('accounts', account), players.name(target))
end)

handlers.giveCar = onPlayer(function(_, target, input)
    local shared <const> = exports.cobalt_core:GetShared('Vehicles', input.model)

    if not shared then
        return false, locale('players.pick_vehicle')
    end

    local plate = args.trim(input.plate):upper():gsub('%s+', '')

    if plate == '' then
        plate = exports.cobalt_core:GeneratePlate()
    end

    if #plate > 8 then
        return false, locale('players.plate_max')
    end

    local garage <const> = args.trim(input.garage) ~= '' and args.trim(input.garage) or config.DefaultGarage
    local inserted <const> = db.insertVehicle({
        license = target.PlayerData.license,
        citizenid = target.PlayerData.citizenid,
        model = input.model,
        mods = {},
        plate = plate,
        garage = garage,
        state = 1,
    })

    if not inserted then
        return false, locale('vehicles.plate_taken', plate)
    end

    Cobalt.Functions.Notify(
        target.PlayerData.source,
        locale('players.car_received', shared.name, plate, garage),
        'success'
    )

    return true, locale('players.gave_car', players.name(target), shared.name)
end)

handlers.spawnTheirVehicle = onPlayer(function(source, target, input)
    local plate <const> = args.trim(input.plate)
    local owned <const> = plate ~= '' and db.getOwnedVehicle(target.PlayerData.citizenid, plate)

    if not owned then
        return false, locale('players.vehicle_not_theirs')
    end

    if vehicles.inWorld(plate) then
        return false, locale('players.vehicle_already_out', plate)
    end

    return vehicles.spawn(source, owned.vehicle, plate, json.decode(owned.mods or '{}'))
end)

handlers.fixTheirVehicle = onPlayer(function(_, target)
    TriggerClientEvent('cobalt_adminmenu:client:fixVehicle', target.PlayerData.source)

    return true, locale('players.vehicle_fixed', players.name(target))
end)

handlers.drunk = onPlayer(function(_, target)
    exports.cobalt_hud:AddAlcohol(target.PlayerData.source, DRUNK_ALCOHOL)

    return true
end)

---@type table<string, true>
local sounds <const> = {}

for _, sound in ipairs(config.Sounds) do
    sounds[sound] = true
end

handlers.playSound = onPlayer(function(_, target, input)
    if not sounds[input.sound] then
        return false, locale('players.pick_sound')
    end

    return exports.cobalt_sound:PlayFrontend(target.PlayerData.source, input.sound, 0.3) ~= nil
end)

handlers.setOnFire = onPlayer(function(_, target)
    TriggerClientEvent('cobalt_adminmenu:client:fire', target.PlayerData.source)

    return true
end)

handlers.explode = onPlayer(function(_, target)
    TriggerClientEvent('cobalt_adminmenu:client:explode', target.PlayerData.source)

    return true
end)

handlers.warn = onPlayer(function(source, target, input)
    local reason <const> = args.trim(input.reason)

    if reason == '' then
        return false, locale('common.give_reason')
    end

    local targetId <const> = target.PlayerData.source

    db.insertWarn(
        Cobalt.Functions.GetIdentifier(source, 'license'),
        GetPlayerName(source),
        target.PlayerData.license,
        reason
    )

    TriggerClientEvent('chat:addMessage', targetId, {
        color = { 255, 0, 0 },
        args = { locale('common.system_author'), locale('players.warned_by', GetPlayerName(source), reason) },
    })

    return true, locale('players.warned', players.name(target))
end)

---@type table<string, true>
local ranks <const> = {}

for _, rank in ipairs(config.Ranks) do
    ranks[rank] = true
end

handlers.setPermission = onPlayer(function(_, target, input)
    if not ranks[input.rank] then
        return false, locale('players.pick_rank')
    end

    local rankLabel <const> = labels.of('ui.ranks', input.rank)

    Cobalt.Functions.AddPermission(target.PlayerData.source, input.rank)
    Cobalt.Functions.Notify(target.PlayerData.source, locale('players.rank_received', rankLabel), 'success')

    return true, locale('players.rank_set', players.name(target), rankLabel)
end)

handlers.kick = onPlayer(function(_, target, input)
    local reason <const> = args.trim(input.reason)

    if reason == '' then
        return false, locale('common.give_reason')
    end

    Cobalt.Functions.Kick(target.PlayerData.source, locale('players.kick_reason', reason))

    return true, locale('players.kicked', players.name(target))
end)

---@type table<integer, true>
local banLengths <const> = {}

for _, seconds in ipairs(config.BanLengths) do
    banLengths[seconds] = true
end

handlers.ban = onPlayer(function(source, target, input)
    local reason <const> = args.trim(input.reason)

    if reason == '' then
        return false, locale('common.give_reason')
    end

    local permanent <const> = input.duration == 'permanent'

    if permanent and not Cobalt.Functions.HasPermission(source, 'owner') then
        return false, locale('players.permanent_needs_owner')
    end

    if not permanent and not banLengths[input.duration] then
        return false, locale('players.pick_duration')
    end

    local identifiers <const> = {}

    for _, idType in ipairs({ 'license', 'discord', 'steam' }) do
        if input[idType] then
            identifiers[#identifiers + 1] = idType
        end
    end

    if #identifiers == 0 then
        return false, locale('players.ban_identifier')
    end

    local targetId <const> = target.PlayerData.source
    local expire <const> = permanent and config.PermanentBan or math.min(os.time() + input.duration, config.PermanentBan)
    local id <const> = exports.cobalt_core:Ban(targetId, {
        reason = reason,
        expire = expire,
        bannedBy = GetPlayerName(source),
        identifiers = identifiers,
    })

    if not id then
        return false, locale('players.ban_failed')
    end

    Cobalt.Functions.Kick(targetId, locale('players.ban_reason', reason, expiryText(expire)))

    return true, locale('players.banned', players.name(target), id)
end)

return handlers
