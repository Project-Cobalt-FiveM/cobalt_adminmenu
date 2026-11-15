local Cobalt <const> = exports.cobalt_core:GetCoreObject()
local config <const> = require 'config'
local access <const> = require 'server.access'
local db <const> = require 'server.db'
local dispatch <const> = require 'server.dispatch'
local labels <const> = require 'shared.labels'
local players <const> = require 'server.players'
local reports <const> = require 'server.reports'
local world <const> = require 'server.world'

local COMMAND_BLACKLIST <const> = {
    '^sv_', '^adhesive_', '^citizen_', '^con_', '^endpoint_', '^fileserver', '^load_server', '^mysql_connection',
    '^net_tcp', '^netPort', '^netlib', '^onesync', '^rateLimiter_', '^svgui', '^web_base', '^temp_', '^txAdmin', '^txa',
    '^%+', '^%-', '^_',
}

---@param name string
---@param allowed fun(source: integer): any
---@param handler fun(source: integer, ...): any
local function guardedCallback(name, allowed, handler)
    lib.callback.register('cobalt_adminmenu:server:' .. name, function(source, ...)
        if not allowed(source) then return end

        return handler(source, ...)
    end)
end

---@param name string
---@param handler fun(source: integer, ...): any
local function menuCallback(name, handler)
    guardedCallback(name, access.rank, handler)
end

---@param name string
---@param handler fun(source: integer, ...): any
local function staffCallback(name, handler)
    guardedCallback(name, access.isStaff, handler)
end

---@return string
local function buildNumber()
    return GetConvar('version', ''):match('v%d+%.%d+%.%d+%.(%d+)') or 'unknown'
end

---@param options AdminOption[]
---@return AdminOption[]
local function sortedByLabel(options)
    table.sort(options, function(a, b) return tostring(a.label):lower() < tostring(b.label):lower() end)

    return options
end

---@param orgs table<string, { label: string, grades: table<string, { name: string }> }>
---@return { label: string, value: string, grades: AdminOption[] }[]
local function gradedOptions(orgs)
    local options <const> = {}

    for name, org in pairs(orgs) do
        local grades <const> = {}

        for level, grade in pairs(org.grades or {}) do
            grades[#grades + 1] = { label = grade.name, value = tonumber(level) }
        end

        table.sort(grades, function(a, b) return a.value < b.value end)

        options[#options + 1] = { label = org.label, value = name, grades = grades }
    end

    return sortedByLabel(options)
end

---@type { name: string, seconds: integer }[]
local DURATION_UNITS <const> = {
    { name = 'year', seconds = 32140800 },
    { name = 'month', seconds = 2678400 },
    { name = 'week', seconds = 604800 },
    { name = 'day', seconds = 86400 },
    { name = 'hour', seconds = 3600 },
    { name = 'minute', seconds = 60 },
}

---@param seconds integer
---@return string
local function durationLabel(seconds)
    for _, unit in ipairs(DURATION_UNITS) do
        if seconds % unit.seconds == 0 then
            local count <const> = seconds // unit.seconds

            return locale(('durations.%s%s'):format(unit.name, count == 1 and '' or 's'), count)
        end
    end

    return locale('durations.seconds', seconds)
end

---@return AdminOption[]
local function banLengthOptions()
    local options <const> = {}

    for i, seconds in ipairs(config.BanLengths) do
        options[i] = { label = durationLabel(seconds), value = seconds }
    end

    return options
end

---@return AdminOption[]
local function timePresetOptions()
    local options <const> = {}

    for i, preset in ipairs(config.TimePresets) do
        options[i] = { label = labels.of('time_presets', preset.name), value = preset.hour }
    end

    return options
end

menuCallback('open', function(source)
    local player <const> = players.get(source)
    local isStaff <const> = access.isStaff(source)

    return {
        rank = access.rank(source),
        name = player and players.name(player) or GetPlayerName(source),
        online = #GetPlayers(),
        staffOnDuty = #access.staff(),
        receivingReports = isStaff and Cobalt.Functions.IsOptin(source),
        reports = isStaff and reports.list() or {},
        staffChat = isStaff and reports.chat() or {},
        build = buildNumber(),
        uptime = GetGameTimer() // 1000,
    }
end)

menuCallback('action', function(source, name, args)
    local ok <const>, message <const> = dispatch.run(source, name, args)

    return { ok = ok, message = message }
end)

menuCallback('getPlayers', function(source)
    return players.list(source)
end)

staffCallback('getPlayer', function(source, id)
    return players.detail(source, id)
end)

staffCallback('getWarnings', function(_, id)
    local license <const> = Cobalt.Functions.GetIdentifier(tonumber(id) or -1, 'license')

    return license and db.getWarns(license) or {}
end)

menuCallback('getLists', function()
    local items <const> = {}

    for name, item in pairs(exports.cobalt_inventory:GetSharedItems()) do
        items[#items + 1] = { label = item.label or name, value = name }
    end

    local vehicles <const> = {}

    for model, vehicle in pairs(exports.cobalt_core:GetShared('Vehicles')) do
        vehicles[#vehicles + 1] = { model = model, name = vehicle.name, category = vehicle.category or 'other' }
    end

    table.sort(vehicles, function(a, b) return a.name:lower() < b.name:lower() end)

    local peds <const> = {}

    for _, model in ipairs(lib.load('data.peds')) do
        peds[#peds + 1] = { label = model, value = model }
    end

    local locations <const> = {}

    for name in pairs(Cobalt.Shared.Locations) do
        locations[#locations + 1] = { label = name, value = name }
    end

    return {
        items = sortedByLabel(items),
        jobs = gradedOptions(exports.cobalt_core:GetShared('Jobs')),
        gangs = gradedOptions(exports.cobalt_core:GetShared('Gangs')),
        vehicles = vehicles,
        peds = peds,
        locations = sortedByLabel(locations),
        accounts = labels.options('accounts', config.Accounts),
        sounds = labels.options('sounds', config.Sounds),
        ranks = labels.options('ui.ranks', config.Ranks),
        weatherTypes = labels.options('weather', exports.cobalt_weather:GetWeatherTypes()),
        timePresets = timePresetOptions(),
        banLengths = banLengthOptions(),
    }
end)

staffCallback('getResources', function()
    local resources <const> = {}

    for i = 0, GetNumResources() - 1 do
        local name <const> = GetResourceByFindIndex(i)

        if name then
            resources[#resources + 1] = {
                name = name,
                version = GetResourceMetadata(name, 'version', 0),
                description = GetResourceMetadata(name, 'description', 0),
                state = GetResourceState(name),
            }
        end
    end
    table.sort(resources, function(a, b) return a.name:lower() < b.name:lower() end)

    return resources
end)

menuCallback('getWorld', world.state)

menuCallback('getCommands', function()
    local seen <const> = {}
    local commands <const> = {}

    for _, command in ipairs(GetRegisteredCommands()) do
        local blocked = seen[command.name]

        for i = 1, #COMMAND_BLACKLIST do
            blocked = blocked or command.name:find(COMMAND_BLACKLIST[i]) ~= nil
        end

        if not blocked then
            seen[command.name] = true
            commands[#commands + 1] = { name = '/' .. command.name }
        end
    end
    table.sort(commands, function(a, b) return a.name < b.name end)

    return commands
end)

staffCallback('sendStaffChat', function(source, message)
    if type(message) ~= 'string' or message == '' then return false end

    reports.say(source, message:sub(1, 300))

    return true
end)

menuCallback('vehicleOwner', function(_, plate)
    local citizenid <const> = type(plate) == 'string' and exports.cobalt_core:GetVehicleOwnerByPlate(plate)

    if not citizenid then return end

    return exports.cobalt_core:GetName(citizenid) or citizenid
end)

require 'server.commands'
require 'server.tester'
