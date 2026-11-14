local Cobalt <const> = exports.cobalt_core:GetCoreObject()
local access <const> = require 'server.access'

---@class Report
---@field id integer
---@field source integer
---@field name string
---@field message string
---@field at integer

---@class ChatMessage
---@field name string
---@field message string
---@field at integer

local MAX_CHAT <const> = 50

local reports <const> = {}

---@type Report[]
local open <const> = {}

---@type ChatMessage[]
local chat <const> = {}

local nextId = 1

---@return Report[]
function reports.list()
    return open
end

---@return ChatMessage[]
function reports.chat()
    return chat
end

---@param id integer
---@return Report?
function reports.find(id)
    for i = 1, #open do
        if open[i].id == id then
            return open[i]
        end
    end
end

local function pushReports()
    for _, staff in ipairs(access.staff()) do
        TriggerClientEvent('cobalt_adminmenu:client:reports', staff, open)
    end
end

local MAX_MESSAGE <const> = 300
local REPORT_COOLDOWN_SECONDS <const> = 60
local MAX_OPEN_PER_PLAYER <const> = 3

---@type table<integer, integer> player source to the os.time of their last report
local lastReport <const> = {}

---@param source integer
---@return integer
local function openCount(source)
    local count = 0

    for _, report in ipairs(open) do
        if report.source == source then count += 1 end
    end

    return count
end

---@param source integer
---@param message string
---@return Report? report
---@return string? reason
function reports.create(source, message)
    if os.time() - (lastReport[source] or 0) < REPORT_COOLDOWN_SECONDS then
        return nil, locale('reports.cooldown')
    end

    if openCount(source) >= MAX_OPEN_PER_PLAYER then
        return nil, locale('reports.too_many')
    end

    lastReport[source] = os.time()

    ---@type Report
    local report <const> = {
        id = nextId,
        source = source,
        name = GetPlayerName(source),
        message = message:sub(1, MAX_MESSAGE),
        at = os.time(),
    }

    nextId += 1
    open[#open + 1] = report

    for _, staff in ipairs(access.staff()) do
        if Cobalt.Functions.IsOptin(staff) then
            TriggerClientEvent('chat:addMessage', staff, {
                color = { 255, 0, 0 },
                multiline = true,
                args = { locale('reports.chat_author', report.id, report.name, source), message },
            })
        end
    end

    pushReports()

    return report
end

---@param id integer
---@return boolean
function reports.close(id)
    for i = 1, #open do
        if open[i].id == id then
            table.remove(open, i)
            pushReports()

            return true
        end
    end

    return false
end

---@param source integer
---@param message string
function reports.say(source, message)
    message = message:sub(1, MAX_MESSAGE)

    if message == '' then return end

    chat[#chat + 1] = { name = GetPlayerName(source), message = message, at = os.time() }

    if #chat > MAX_CHAT then
        table.remove(chat, 1)
    end

    for _, staff in ipairs(access.staff()) do
        TriggerClientEvent('cobalt_adminmenu:client:staffChat', staff, chat)
        TriggerClientEvent('chat:addMessage', staff, {
            color = { 255, 0, 0 },
            multiline = true,
            args = { locale('reports.staff_chat_author', GetPlayerName(source)), message },
        })
    end
end

AddEventHandler('playerDropped', function()
    local dropped <const> = source
    local removed = false

    lastReport[dropped] = nil

    for i = #open, 1, -1 do
        if open[i].source == dropped then
            table.remove(open, i)
            removed = true
        end
    end

    if removed then pushReports() end
end)

return reports
