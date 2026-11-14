---@class AdminOption
---@field label string
---@field value string|number

---@class AdminTimePreset
---@field name string
---@field hour integer

---@alias AdminLogBackend
---| 'fivemesh' # Default. Sends admin actions to FiveMesh through cobalt_core's LogPlayer.
---| 'database' # Highly unrecommended. Writes the local admin_logs table, which grows without limit and nothing reads back.

---@class AdminMenuConfig
---@field LogBackend AdminLogBackend Where admin actions are logged. Keep 'fivemesh'; 'database' is highly unrecommended.
---@field OpenKey string
---@field NoclipKey string
---@field DefaultGarage string
---@field ReviveRadius number
---@field PermanentBan integer
---@field BanLengths integer[]
---@field TimePresets AdminTimePreset[]
---@field Accounts string[]
---@field Sounds string[]
---@field Ranks AdminRank[]
---@field QuickLocations { name: string, coords: vector4 }[]
---@field BlockedRandomPeds table<string, true>

---@type AdminMenuConfig
return {
    -- Where admin actions are logged: 'fivemesh' (default) or 'database' (local admin_logs table, not recommended)
    LogBackend = 'fivemesh',

    -- Default keys; staff can rebind them in GTA settings
    OpenKey = 'F7', -- open the admin menu
    NoclipKey = 'PAGEUP', -- toggle noclip

    -- Actions
    DefaultGarage = 'legion_square', -- cobalt_garages id a vehicle given by an admin is stored in when none is picked
    ReviveRadius = 15.0, -- meters around the admin that "revive nearby" reaches
    PermanentBan = 2147483647, -- ban length in seconds treated as permanent

    -- Ban length choices in the menu, in seconds; labels are worked out from the length (600 shows as "10 minutes")
    BanLengths = { 600, 3600, 21600, 86400, 259200, 604800, 1814400, 2678400, 8035200, 32140800 },

    -- Time of day buttons: name is the locale key under time_presets in locales/en.json, hour is 0 to 23
    TimePresets = {
        { name = 'sunrise', hour = 6 },
        { name = 'morning', hour = 9 },
        { name = 'noon', hour = 12 },
        { name = 'sunset', hour = 19 },
        { name = 'evening', hour = 21 },
        { name = 'night', hour = 0 },
    },

    -- Money accounts admins can give or take from; labels live under accounts in locales/en.json
    Accounts = { 'cash', 'bank', 'crypto' },

    -- cobalt_sound files admins can play to a player; labels live under sounds in locales/en.json
    Sounds = { 'alert', 'error', 'glass' },

    -- Ranks admins can grant; labels live under ui.ranks in locales/en.json
    Ranks = { 'staff', 'admin', 'owner' },

    -- Teleport shortcuts: name is the locale key under locations in locales/en.json
    QuickLocations = {
        { name = 'legion_square', coords = vector4(195.17, -933.77, 30.69, 144.5) },
        { name = 'mission_row', coords = vector4(428.23, -984.28, 29.76, 3.5) },
        { name = 'pillbox', coords = vector4(298.6, -584.5, 43.26, 70.0) },
        { name = 'sandy_shores', coords = vector4(1853.9, 3686.9, 34.27, 210.0) },
        { name = 'paleto_bay', coords = vector4(-448.0, 6011.0, 31.72, 315.0) },
    },

    -- Ped models that get their default outfit instead of a random one when a player is changed into them
    BlockedRandomPeds = {
        mp_m_freemode_01 = true,
        mp_f_freemode_01 = true,
        tony = true,
        g_m_m_chigoon_02_m = true,
        u_m_m_jesus_01 = true,
        a_m_y_stbla_m = true,
        ig_terry_m = true,
        a_m_m_ktown_m = true,
        a_m_y_skater_m = true,
        u_m_y_coop = true,
        ig_car3guy1_m = true,
    },
}
