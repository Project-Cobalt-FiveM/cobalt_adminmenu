local Cobalt <const> = exports.cobalt_core:GetCoreObject()
local access <const> = require 'server.access'
local catalog <const> = require 'shared.actions'
local db <const> = require 'server.db'
local dispatch <const> = require 'server.dispatch'
local players <const> = require 'server.players'
local reports <const> = require 'server.reports'

---@param source integer
---@param message string
local function system(source, message)
    TriggerClientEvent(
        'chat:addMessage',
        source,
        { color = { 255, 0, 0 }, multiline = true, args = { locale('common.system_author'), message } }
    )
end

---@param args string[]
---@param from integer
---@return string
local function rest(args, from)
    return table.concat(args, ' ', from)
end

---@class ActionCommand
---@field name string
---@field help string
---@field action string
---@field params? { name: string, help: string }[]
---@field args? fun(args: string[], source: integer): table

---@param command ActionCommand
local function actionCommand(command)
    Cobalt.Commands.Add(command.name, command.help, command.params or {}, false, function(source, args)
        if source == 0 then return end

        dispatch.run(source, command.action, command.args and command.args(args, source) or {})
    end, catalog.byName[command.action].rank)
end

Cobalt.Commands.Add('admin', locale('commands.admin'), {}, false, function(source)
    TriggerClientEvent('cobalt_adminmenu:client:open', source)
end, 'staff')

actionCommand({
    name = 'car',
    help = locale('commands.car'),
    action = 'spawnVehicle',
    params = { { name = 'model', help = locale('commands.params.vehicle_model') } },
    args = function(args) return { model = args[1] } end,
})

actionCommand({ name = 'admincar', help = locale('commands.admincar'), action = 'saveVehicle' })
actionCommand({ name = 'maxmods', help = locale('commands.maxmods'), action = 'maxMods' })
actionCommand({ name = 'blips', help = locale('commands.blips'), action = 'blips' })
actionCommand({ name = 'names', help = locale('commands.names'), action = 'names' })
actionCommand({ name = 'coords', help = locale('commands.coords'), action = 'coords' })
actionCommand({ name = 'vector2', help = locale('commands.vector2'), action = 'copyVector2' })
actionCommand({ name = 'vector3', help = locale('commands.vector3'), action = 'copyVector3' })
actionCommand({ name = 'vector4', help = locale('commands.vector4'), action = 'copyVector4' })
actionCommand({ name = 'heading', help = locale('commands.heading'), action = 'copyHeading' })
actionCommand({ name = 'reporttoggle', help = locale('commands.reporttoggle'), action = 'receiveReports' })

actionCommand({
    name = 'setammo',
    help = locale('commands.setammo'),
    action = 'setAmmo',
    params = { { name = 'amount', help = locale('commands.params.rounds') } },
    args = function(args) return { amount = tonumber(args[1]) or 250 } end,
})

actionCommand({
    name = 'announce',
    help = locale('commands.announce'),
    action = 'announce',
    params = { { name = 'message', help = locale('commands.params.message') } },
    args = function(args) return { message = rest(args, 1) } end,
})

actionCommand({
    name = 'reportr',
    help = locale('commands.reportr'),
    action = 'reportReply',
    params = { { name = 'report', help = locale('commands.params.report_number') }, { name = 'message', help = locale('commands.params.reply') } },
    args = function(args) return { report = tonumber(args[1]), message = rest(args, 2) } end,
})

actionCommand({
    name = 'warn',
    help = locale('commands.warn'),
    action = 'warn',
    params = { { name = 'id', help = locale('commands.params.player_id') }, { name = 'reason', help = locale('commands.params.reason') } },
    args = function(args) return { target = tonumber(args[1]), reason = rest(args, 2) } end,
})

Cobalt.Commands.Add('tp', locale('commands.tp'), {
    { name = 'target', help = locale('commands.params.tp_target') },
    { name = 'y', help = locale('commands.params.y') },
    { name = 'z', help = locale('commands.params.z') },
}, false, function(source, args)
    if source == 0 or not args[1] then return end

    local target <const> = tonumber(args[1])

    if args[2] then
        dispatch.run(source, 'teleportCoords', { coords = rest(args, 1) })
    elseif target then
        dispatch.run(source, 'goto', { target = target })
    else
        dispatch.run(source, 'teleportLocation', { location = args[1] })
    end
end, 'staff')

actionCommand({ name = 'tpm', help = locale('commands.tpm'), action = 'teleportMarker' })

actionCommand({
    name = 'setjob',
    help = locale('commands.setjob'),
    action = 'setJob',
    params = {
        { name = 'id', help = locale('commands.params.player_id') },
        { name = 'job', help = locale('commands.params.job') },
        { name = 'grade', help = locale('commands.params.grade') },
    },
    args = function(args) return { target = tonumber(args[1]), job = args[2] and args[2]:lower(), grade = args[3] } end,
})

actionCommand({
    name = 'setgang',
    help = locale('commands.setgang'),
    action = 'setGang',
    params = {
        { name = 'id', help = locale('commands.params.player_id') },
        { name = 'gang', help = locale('commands.params.gang') },
        { name = 'grade', help = locale('commands.params.grade') },
    },
    args = function(args) return { target = tonumber(args[1]), gang = args[2] and args[2]:lower(), grade = args[3] } end,
})

---@type table<string, boolean>
local DUTY_STATES <const> = { ['1'] = true, on = true, ['0'] = false, off = false }

actionCommand({
    name = 'setduty',
    help = locale('commands.setduty'),
    action = 'setDuty',
    params = {
        { name = 'id', help = locale('commands.params.player_id_optional') },
        { name = 'state', help = locale('commands.params.duty_state') },
    },
    args = function(args, source)
        return { target = tonumber(args[1]) or source, onDuty = DUTY_STATES[args[2] and args[2]:lower() or ''] }
    end,
})

actionCommand({
    name = 'setmodel',
    help = locale('commands.setmodel'),
    action = 'setPed',
    params = { { name = 'model', help = locale('commands.params.ped_model') }, { name = 'id', help = locale('commands.params.player_id_optional') } },
    args = function(args, source) return { model = args[1], target = tonumber(args[2]) or source } end,
})

actionCommand({
    name = 'kickall',
    help = locale('commands.kickall'),
    action = 'kickAll',
    params = { { name = 'reason', help = locale('commands.params.reason') } },
    args = function(args) return { reason = rest(args, 1) } end,
})

actionCommand({
    name = 'unban',
    help = locale('commands.unban'),
    action = 'unban',
    params = { { name = 'ban', help = locale('commands.params.ban') } },
    args = function(args) return { ban = args[1] } end,
})

Cobalt.Commands.Add('report', locale('commands.report'), {
    { name = 'message', help = locale('commands.params.what_happened') },
}, true, function(source, args)
    local message <const> = rest(args, 1)

    if message == '' then return end

    local report <const>, reason <const> = reports.create(source, message)

    if not report then return Cobalt.Functions.Notify(source, reason, 'error') end

    Cobalt.Functions.Notify(source, locale('reports.sent', report.id), 'success')
end)

Cobalt.Commands.Add('staffchat', locale('commands.staffchat'), {
    { name = 'message', help = locale('commands.params.message') },
}, true, function(source, args)
    reports.say(source, rest(args, 1))
end, 'staff')

Cobalt.Commands.Add('checkwarns', locale('commands.checkwarns'), {
    { name = 'id', help = locale('commands.params.player_id') },
}, true, function(source, args)
    local target <const> = players.get(args[1])

    if not target then
        return Cobalt.Functions.Notify(source, locale('common.player_offline'), 'error')
    end

    local warnings <const> = db.getWarns(target.PlayerData.license)

    system(source, locale('warnings.count', players.name(target), #warnings))

    for _, warning in ipairs(warnings) do
        system(
            source,
            locale('warnings.entry', warning.id, warning.by, os.date('%d/%m/%Y', warning.at), warning.reason)
        )
    end
end, 'staff')

actionCommand({
    name = 'delwarn',
    help = locale('commands.delwarn'),
    action = 'deleteWarning',
    params = { { name = 'warning', help = locale('commands.params.warning_number') } },
    args = function(args) return { warning = tonumber(args[1]) } end,
})

actionCommand({
    name = 'setspeed',
    help = locale('commands.setspeed'),
    action = 'fastRun',
    params = { { name = 'speed', help = locale('commands.params.speed') } },
    args = function(args) return { enabled = args[1] == 'fast' } end,
})

actionCommand({
    name = 'givenuifocus',
    help = locale('commands.givenuifocus'),
    action = 'nuiFocus',
    params = {
        { name = 'id', help = locale('commands.params.player_id') },
        { name = 'focus', help = locale('commands.params.boolean') },
        { name = 'mouse', help = locale('commands.params.boolean') },
    },
    args = function(args)
        return { target = tonumber(args[1]), focus = args[2] == 'true', mouse = args[3] == 'true' }
    end,
})

AddEventHandler('cobalt_core:Server:PlayerLoaded', function(player)
    local playerId <const> = player.PlayerData.source

    if access.rank(playerId) and #reports.list() > 0 then
        TriggerClientEvent('cobalt_adminmenu:client:reports', playerId, reports.list())
    end
end)
