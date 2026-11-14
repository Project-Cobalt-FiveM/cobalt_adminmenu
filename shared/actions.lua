---@alias AdminRank 'staff'|'admin'|'owner'
---@alias AdminScope 'self'|'player'|'vehicle'|'world'|'server'|'report'
---@alias AdminFieldKind 'text'|'textarea'|'number'|'select'
---@alias AdminListName 'items'|'jobs'|'gangs'|'grades'|'vehicles'|'peds'|'locations'|'accounts'|'sounds'|'ranks'|'weatherTypes'|'timePresets'|'playerVehicles'

---@class AdminField
---@field key string
---@field label string
---@field kind AdminFieldKind
---@field list? AdminListName
---@field dependsOn? string
---@field optional? boolean
---@field placeholder? string

---@class AdminAction
---@field name string
---@field label string
---@field hint? string
---@field scope AdminScope
---@field rank AdminRank
---@field side 'server'|'client'
---@field toggle? boolean
---@field danger? boolean
---@field hidden? boolean
---@field fields? AdminField[]

---@type AdminField
local playerField <const> = { key = 'target', label = locale('fields.player'), kind = 'number' }

---@type AdminAction[]
local Actions <const> = {
    { name = 'noclip', label = locale('catalog.noclip.label'), scope = 'self', rank = 'staff', side = 'client', toggle = true },
    { name = 'godmode', label = locale('catalog.godmode.label'), scope = 'self', rank = 'admin', side = 'client', toggle = true },
    { name = 'invisible', label = locale('catalog.invisible.label'), scope = 'self', rank = 'staff', side = 'client', toggle = true },
    { name = 'names', label = locale('catalog.names.label'), scope = 'self', rank = 'staff', side = 'client', toggle = true },
    { name = 'blips', label = locale('catalog.blips.label'), scope = 'self', rank = 'staff', side = 'client', toggle = true },
    { name = 'infiniteAmmo', label = locale('catalog.infinite_ammo.label'), scope = 'self', rank = 'admin', side = 'client', toggle = true },
    { name = 'reviveSelf', label = locale('catalog.revive_self.label'), scope = 'self', rank = 'admin', side = 'server' },
    { name = 'teleportMarker', label = locale('catalog.teleport_marker.label'), scope = 'self', rank = 'staff', side = 'client' },
    { name = 'teleportBack', label = locale('catalog.teleport_back.label'), scope = 'self', rank = 'staff', side = 'client' },
    {
        name = 'teleportCoords',
        label = locale('catalog.teleport_coords.label'),
        hint = locale('catalog.teleport_coords.hint'),
        scope = 'self',
        rank = 'admin',
        side = 'client',
        fields = {
            { key = 'coords', label = locale('fields.coords'), kind = 'text', placeholder = locale('fields.coords_placeholder') },
        },
    },
    {
        name = 'teleportLocation',
        label = locale('catalog.teleport_location.label'),
        scope = 'self',
        rank = 'admin',
        side = 'client',
        fields = { { key = 'location', label = locale('fields.location'), kind = 'select', list = 'locations' } },
    },
    {
        name = 'setAmmo',
        label = locale('catalog.set_ammo.label'),
        hint = locale('catalog.set_ammo.hint'),
        scope = 'self',
        rank = 'admin',
        side = 'server',
        fields = { { key = 'amount', label = locale('fields.rounds'), kind = 'number' } },
    },
    { name = 'coords', label = locale('catalog.coords.label'), scope = 'self', rank = 'admin', side = 'client', toggle = true },
    { name = 'fastRun', label = locale('catalog.fast_run.label'), scope = 'self', rank = 'admin', side = 'client', toggle = true },
    { name = 'entityLaser', label = locale('catalog.entity_laser.label'), scope = 'self', rank = 'admin', side = 'client', toggle = true },
    {
        name = 'entityFreeAim',
        label = locale('catalog.entity_free_aim.label'),
        scope = 'self',
        rank = 'admin',
        side = 'client',
        toggle = true,
    },
    {
        name = 'labelVehicles',
        label = locale('catalog.label_vehicles.label'),
        scope = 'self',
        rank = 'admin',
        side = 'client',
        toggle = true,
    },
    {
        name = 'labelPeds',
        label = locale('catalog.label_peds.label'),
        scope = 'self',
        rank = 'admin',
        side = 'client',
        toggle = true,
    },
    {
        name = 'labelObjects',
        label = locale('catalog.label_objects.label'),
        scope = 'self',
        rank = 'admin',
        side = 'client',
        toggle = true,
    },
    { name = 'copyVector2', label = locale('catalog.copy_vector2.label'), scope = 'self', rank = 'admin', side = 'client' },
    { name = 'copyVector3', label = locale('catalog.copy_vector3.label'), scope = 'self', rank = 'admin', side = 'client' },
    { name = 'copyVector4', label = locale('catalog.copy_vector4.label'), scope = 'self', rank = 'admin', side = 'client' },
    { name = 'copyHeading', label = locale('catalog.copy_heading.label'), scope = 'self', rank = 'admin', side = 'client' },
    {
        name = 'copyEntity',
        label = locale('catalog.copy_entity.label'),
        hint = locale('catalog.copy_entity.hint'),
        scope = 'self',
        rank = 'admin',
        side = 'client',
    },
    {
        name = 'deleteEntity',
        label = locale('catalog.delete_entity.label'),
        scope = 'self',
        rank = 'admin',
        side = 'server',
        hidden = true,
    },

    { name = 'goto', label = locale('catalog.goto.label'), scope = 'player', rank = 'staff', side = 'server', fields = { playerField } },
    { name = 'bring', label = locale('catalog.bring.label'), scope = 'player', rank = 'staff', side = 'server', fields = { playerField } },
    {
        name = 'spectate',
        label = locale('catalog.spectate.label'),
        scope = 'player',
        rank = 'staff',
        side = 'server',
        fields = { playerField },
    },
    {
        name = 'intoVehicle',
        label = locale('catalog.into_vehicle.label'),
        scope = 'player',
        rank = 'admin',
        side = 'server',
        fields = { playerField },
    },
    {
        name = 'setBucket',
        label = locale('catalog.set_bucket.label'),
        scope = 'player',
        rank = 'admin',
        side = 'server',
        fields = { playerField, { key = 'bucket', label = locale('fields.bucket'), kind = 'number' } },
    },
    { name = 'revive', label = locale('catalog.revive.label'), scope = 'player', rank = 'admin', side = 'server', fields = { playerField } },
    {
        name = 'heal',
        label = locale('catalog.heal.label'),
        hint = locale('catalog.heal.hint'),
        scope = 'player',
        rank = 'admin',
        side = 'server',
        fields = { playerField },
    },
    { name = 'freeze', label = locale('catalog.freeze.label'), scope = 'player', rank = 'staff', side = 'server', fields = { playerField } },
    { name = 'cuff', label = locale('catalog.cuff.label'), scope = 'player', rank = 'admin', side = 'server', fields = { playerField } },
    {
        name = 'removeStress',
        label = locale('catalog.remove_stress.label'),
        scope = 'player',
        rank = 'admin',
        side = 'server',
        fields = { playerField },
    },
    {
        name = 'mute',
        label = locale('catalog.mute.label'),
        scope = 'player',
        rank = 'staff',
        side = 'server',
        fields = { playerField },
    },
    {
        name = 'nuiFocus',
        label = locale('catalog.nui_focus.label'),
        hint = locale('catalog.nui_focus.hint'),
        scope = 'player',
        rank = 'admin',
        side = 'server',
        fields = { playerField },
    },
    {
        name = 'kill',
        label = locale('catalog.kill.label'),
        scope = 'player',
        rank = 'admin',
        side = 'server',
        danger = true,
        fields = { playerField },
    },
    {
        name = 'setJob',
        label = locale('catalog.set_job.label'),
        scope = 'player',
        rank = 'owner',
        side = 'server',
        fields = {
            playerField,
            { key = 'job', label = locale('fields.job'), kind = 'select', list = 'jobs' },
            { key = 'grade', label = locale('fields.grade'), kind = 'select', list = 'grades', dependsOn = 'job' },
        },
    },
    {
        name = 'setGang',
        label = locale('catalog.set_gang.label'),
        scope = 'player',
        rank = 'admin',
        side = 'server',
        fields = {
            playerField,
            { key = 'gang', label = locale('fields.gang'), kind = 'select', list = 'gangs' },
            { key = 'grade', label = locale('fields.grade'), kind = 'select', list = 'grades', dependsOn = 'gang' },
        },
    },
    {
        name = 'setDuty',
        label = locale('catalog.set_duty.label'),
        hint = locale('catalog.set_duty.hint'),
        scope = 'player',
        rank = 'admin',
        side = 'server',
        fields = { playerField },
    },
    {
        name = 'setPed',
        label = locale('catalog.set_ped.label'),
        scope = 'player',
        rank = 'admin',
        side = 'server',
        fields = { playerField, { key = 'model', label = locale('fields.ped_model'), kind = 'select', list = 'peds' } },
    },
    {
        name = 'clothing',
        label = locale('catalog.clothing.label'),
        hint = locale('catalog.clothing.hint'),
        scope = 'player',
        rank = 'admin',
        side = 'server',
        fields = { playerField },
    },
    {
        name = 'openInventory',
        label = locale('catalog.open_inventory.label'),
        scope = 'player',
        rank = 'admin',
        side = 'server',
        fields = { playerField },
    },
    {
        name = 'giveItem',
        label = locale('catalog.give_item.label'),
        hint = locale('catalog.give_item.hint'),
        scope = 'player',
        rank = 'admin',
        side = 'server',
        fields = {
            playerField,
            { key = 'item', label = locale('fields.item'), kind = 'select', list = 'items' },
            { key = 'amount', label = locale('fields.amount'), kind = 'number' },
        },
    },
    {
        name = 'clearInventory',
        label = locale('catalog.clear_inventory.label'),
        scope = 'player',
        rank = 'admin',
        side = 'server',
        danger = true,
        fields = { playerField },
    },
    {
        name = 'giveMoney',
        label = locale('catalog.give_money.label'),
        hint = locale('catalog.give_money.hint'),
        scope = 'player',
        rank = 'owner',
        side = 'server',
        fields = {
            playerField,
            { key = 'account', label = locale('fields.account'), kind = 'select', list = 'accounts' },
            { key = 'amount', label = locale('fields.amount'), kind = 'number' },
        },
    },
    {
        name = 'removeMoney',
        label = locale('catalog.remove_money.label'),
        hint = locale('catalog.remove_money.hint'),
        scope = 'player',
        rank = 'owner',
        side = 'server',
        fields = {
            playerField,
            { key = 'account', label = locale('fields.account'), kind = 'select', list = 'accounts' },
            { key = 'amount', label = locale('fields.amount'), kind = 'number' },
        },
    },
    {
        name = 'giveCar',
        label = locale('catalog.give_car.label'),
        hint = locale('catalog.give_car.hint'),
        scope = 'player',
        rank = 'owner',
        side = 'server',
        fields = {
            playerField,
            { key = 'model', label = locale('fields.vehicle'), kind = 'select', list = 'vehicles' },
            { key = 'plate', label = locale('fields.plate'), kind = 'text', optional = true },
            { key = 'garage', label = locale('fields.garage'), kind = 'text', optional = true },
        },
    },
    {
        name = 'spawnTheirVehicle',
        label = locale('catalog.spawn_their_vehicle.label'),
        scope = 'player',
        rank = 'admin',
        side = 'server',
        fields = { playerField, { key = 'plate', label = locale('fields.vehicle'), kind = 'select', list = 'playerVehicles' } },
    },
    {
        name = 'fixTheirVehicle',
        label = locale('catalog.fix_their_vehicle.label'),
        scope = 'player',
        rank = 'admin',
        side = 'server',
        fields = { playerField },
    },
    {
        name = 'drunk',
        label = locale('catalog.drunk.label'),
        scope = 'player',
        rank = 'admin',
        side = 'server',
        fields = { playerField },
    },
    {
        name = 'playSound',
        label = locale('catalog.play_sound.label'),
        scope = 'player',
        rank = 'admin',
        side = 'server',
        fields = { playerField, { key = 'sound', label = locale('fields.sound'), kind = 'select', list = 'sounds' } },
    },
    {
        name = 'setOnFire',
        label = locale('catalog.set_on_fire.label'),
        scope = 'player',
        rank = 'admin',
        side = 'server',
        danger = true,
        fields = { playerField },
    },
    {
        name = 'explode',
        label = locale('catalog.explode.label'),
        scope = 'player',
        rank = 'admin',
        side = 'server',
        danger = true,
        fields = { playerField },
    },
    {
        name = 'warn',
        label = locale('catalog.warn.label'),
        scope = 'player',
        rank = 'staff',
        side = 'server',
        fields = { playerField, { key = 'reason', label = locale('fields.reason'), kind = 'textarea' } },
    },
    {
        name = 'setPermission',
        label = locale('catalog.set_permission.label'),
        scope = 'player',
        rank = 'owner',
        side = 'server',
        fields = { playerField, { key = 'rank', label = locale('fields.rank'), kind = 'select', list = 'ranks' } },
    },
    {
        name = 'kick',
        label = locale('catalog.kick.label'),
        scope = 'player',
        rank = 'staff',
        side = 'server',
        danger = true,
        fields = { playerField, { key = 'reason', label = locale('fields.reason'), kind = 'textarea' } },
    },
    {
        name = 'ban',
        label = locale('catalog.ban.label'),
        scope = 'player',
        rank = 'admin',
        side = 'server',
        danger = true,
        fields = { playerField },
    },

    {
        name = 'spawnVehicle',
        label = locale('catalog.spawn_vehicle.label'),
        hint = locale('catalog.spawn_vehicle.hint'),
        scope = 'vehicle',
        rank = 'admin',
        side = 'server',
        fields = { { key = 'model', label = locale('fields.vehicle'), kind = 'select', list = 'vehicles' } },
    },
    { name = 'fixVehicle', label = locale('catalog.fix_vehicle.label'), scope = 'vehicle', rank = 'admin', side = 'client' },
    { name = 'refuelVehicle', label = locale('catalog.refuel_vehicle.label'), scope = 'vehicle', rank = 'admin', side = 'server' },
    { name = 'maxMods', label = locale('catalog.max_mods.label'), scope = 'vehicle', rank = 'admin', side = 'client' },
    {
        name = 'changePlate',
        label = locale('catalog.change_plate.label'),
        scope = 'vehicle',
        rank = 'admin',
        side = 'server',
        fields = { { key = 'plate', label = locale('fields.new_plate'), kind = 'text', placeholder = locale('fields.new_plate_placeholder') } },
    },
    { name = 'saveVehicle', label = locale('catalog.save_vehicle.label'), scope = 'vehicle', rank = 'admin', side = 'server' },
    {
        name = 'deleteVehicle',
        label = locale('catalog.delete_vehicle.label'),
        scope = 'vehicle',
        rank = 'admin',
        side = 'server',
        danger = true,
    },
    {
        name = 'vehicleDev',
        label = locale('catalog.vehicle_dev.label'),
        hint = locale('catalog.vehicle_dev.hint'),
        scope = 'vehicle',
        rank = 'admin',
        side = 'client',
        toggle = true,
    },
    {
        name = 'openTrunk',
        label = locale('catalog.open_trunk.label'),
        scope = 'vehicle',
        rank = 'admin',
        side = 'server',
        fields = { { key = 'plate', label = locale('fields.plate'), kind = 'text' } },
    },
    {
        name = 'markInGarage',
        label = locale('catalog.mark_in_garage.label'),
        scope = 'vehicle',
        rank = 'admin',
        side = 'server',
        fields = { { key = 'plate', label = locale('fields.plate'), kind = 'text' } },
    },
    {
        name = 'markOut',
        label = locale('catalog.mark_out.label'),
        scope = 'vehicle',
        rank = 'admin',
        side = 'server',
        fields = { { key = 'plate', label = locale('fields.plate'), kind = 'text' } },
    },

    {
        name = 'setWeather',
        label = locale('catalog.set_weather.label'),
        scope = 'world',
        rank = 'admin',
        side = 'server',
        fields = { { key = 'weather', label = locale('fields.weather'), kind = 'select', list = 'weatherTypes' } },
    },
    {
        name = 'setTime',
        label = locale('catalog.set_time.label'),
        scope = 'world',
        rank = 'admin',
        side = 'server',
        fields = { { key = 'hour', label = locale('fields.time'), kind = 'select', list = 'timePresets' } },
    },
    { name = 'freezeTime', label = locale('catalog.freeze_time.label'), scope = 'world', rank = 'admin', side = 'server', toggle = true },
    {
        name = 'dynamicWeather',
        label = locale('catalog.dynamic_weather.label'),
        scope = 'world',
        rank = 'admin',
        side = 'server',
        toggle = true,
    },
    { name = 'blackout', label = locale('catalog.blackout.label'), scope = 'world', rank = 'admin', side = 'server', toggle = true },

    {
        name = 'announce',
        label = locale('catalog.announce.label'),
        hint = locale('catalog.announce.hint'),
        scope = 'server',
        rank = 'admin',
        side = 'server',
        fields = { { key = 'message', label = locale('fields.message'), kind = 'textarea' } },
    },
    { name = 'reviveAll', label = locale('catalog.revive_all.label'), scope = 'server', rank = 'admin', side = 'server' },
    {
        name = 'reviveRadius',
        label = locale('catalog.revive_radius.label'),
        hint = locale('catalog.revive_radius.hint'),
        scope = 'server',
        rank = 'admin',
        side = 'server',
    },
    {
        name = 'giveItemAll',
        label = locale('catalog.give_item_all.label'),
        hint = locale('catalog.give_item_all.hint'),
        scope = 'server',
        rank = 'admin',
        side = 'server',
        fields = {
            { key = 'item', label = locale('fields.item'), kind = 'select', list = 'items' },
            { key = 'amount', label = locale('fields.amount'), kind = 'number' },
        },
    },
    {
        name = 'giveMoneyAll',
        label = locale('catalog.give_money_all.label'),
        hint = locale('catalog.give_money_all.hint'),
        scope = 'server',
        rank = 'owner',
        side = 'server',
        fields = {
            { key = 'account', label = locale('fields.account'), kind = 'select', list = 'accounts' },
            { key = 'amount', label = locale('fields.amount'), kind = 'number' },
        },
    },
    {
        name = 'kickAll',
        label = locale('catalog.kick_all.label'),
        scope = 'server',
        rank = 'owner',
        side = 'server',
        danger = true,
        fields = { { key = 'reason', label = locale('fields.reason'), kind = 'textarea' } },
    },
    {
        name = 'unban',
        label = locale('catalog.unban.label'),
        hint = locale('catalog.unban.hint'),
        scope = 'server',
        rank = 'admin',
        side = 'server',
        fields = { { key = 'ban', label = locale('fields.ban_id_or_identifier'), kind = 'text' } },
    },
    {
        name = 'deleteWarning',
        label = locale('catalog.delete_warning.label'),
        hint = locale('catalog.delete_warning.hint'),
        scope = 'server',
        rank = 'admin',
        side = 'server',
        fields = { { key = 'warning', label = locale('fields.warning_number'), kind = 'number' } },
    },
    {
        name = 'clearInventoryOffline',
        label = locale('catalog.clear_inventory_offline.label'),
        hint = locale('catalog.clear_inventory_offline.hint'),
        scope = 'server',
        rank = 'admin',
        side = 'server',
        danger = true,
        fields = { { key = 'citizenid', label = locale('fields.citizen_id'), kind = 'text' } },
    },
    {
        name = 'openStash',
        label = locale('catalog.open_stash.label'),
        scope = 'server',
        rank = 'admin',
        side = 'server',
        fields = { { key = 'stash', label = locale('fields.stash_id'), kind = 'text' } },
    },
    { name = 'resource', label = locale('catalog.resource.label'), scope = 'server', rank = 'owner', side = 'server' },

    {
        name = 'receiveReports',
        label = locale('catalog.receive_reports.label'),
        scope = 'report',
        rank = 'staff',
        side = 'server',
        toggle = true,
    },
    { name = 'reportGoto', label = locale('catalog.report_goto.label'), scope = 'report', rank = 'staff', side = 'server' },
    {
        name = 'reportReply',
        label = locale('catalog.report_reply.label'),
        scope = 'report',
        rank = 'staff',
        side = 'server',
        fields = { { key = 'message', label = locale('fields.reply'), kind = 'textarea' } },
    },
    { name = 'reportClose', label = locale('catalog.report_close.label'), scope = 'report', rank = 'staff', side = 'server' },
}

---@type table<string, AdminAction>
local byName <const> = {}

for i = 1, #Actions do
    byName[Actions[i].name] = Actions[i]
end

---@type table<AdminRank, integer>
local RANK_LEVEL <const> = { staff = 1, admin = 2, owner = 3 }

---@param rank AdminRank?
---@param required AdminRank
---@return boolean
local function rankAllows(rank, required)
    return rank ~= nil and RANK_LEVEL[rank] >= RANK_LEVEL[required]
end

---@class AdminCatalog
---@field list AdminAction[]
---@field byName table<string, AdminAction>
---@field rankAllows fun(rank: AdminRank?, required: AdminRank): boolean

---@type AdminCatalog
return {
    list = Actions,
    byName = byName,
    rankAllows = rankAllows,
}
