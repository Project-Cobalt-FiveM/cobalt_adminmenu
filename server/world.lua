---@class WorldState
---@field weather string
---@field hour integer
---@field minute integer
---@field freezeTime boolean
---@field dynamicWeather boolean
---@field blackout boolean

local weather <const> = exports.cobalt_weather

local world <const> = {}

---@return WorldState
function world.state()
    local time <const> = weather:GetTime()
    local current <const> = weather:GetWeather()

    return {
        weather = current.current,
        hour = time.hour,
        minute = time.minute,
        freezeTime = time.frozen,
        dynamicWeather = not current.frozen,
        blackout = current.blackout,
    }
end

return world
