---@class AdminWarnRow
---@field id integer
---@field reason string
---@field by string
---@field at integer

---@class AdminOwnedVehicle
---@field license string
---@field citizenid string
---@field model string
---@field mods table
---@field plate string
---@field garage string
---@field state integer

local db <const> = {}

---@param senderLicense string?
---@param senderName string
---@param targetLicense string
---@param reason string
function db.insertWarn(senderLicense, senderName, targetLicense, reason)
    MySQL.insert.await(
        'INSERT INTO warns (sender_identifier, sender_name, target_identifier, reason) VALUES (?, ?, ?, ?)',
        { senderLicense, senderName, targetLicense, reason }
    )
end

---@param license string
---@return AdminWarnRow[]
function db.getWarns(license)
    local rows <const> = MySQL.query.await([[
        SELECT id, reason, sender_name AS `by`, UNIX_TIMESTAMP(created_at) AS `at`
        FROM warns WHERE target_identifier = ? ORDER BY id DESC LIMIT 100
    ]], { license })

    for _, row in ipairs(rows) do
        row.by = row.by or locale('warnings.unknown_sender')
    end

    return rows
end

---@param license string
---@return integer count
---@return integer? last
function db.countWarns(license)
    local row <const> = MySQL.single.await(
        'SELECT COUNT(*) AS count, UNIX_TIMESTAMP(MAX(created_at)) AS last FROM warns WHERE target_identifier = ?',
        { license }
    )

    return row?.count or 0, row?.last
end

---@param id integer
---@return boolean
function db.deleteWarn(id)
    return MySQL.update.await('DELETE FROM warns WHERE id = ?', { id }) == 1
end

---@param adminLicense string?
---@param adminName string
---@param action string
---@param targetLicense string?
---@param details table
function db.insertLog(adminLicense, adminName, action, targetLicense, details)
    MySQL.insert(
        'INSERT INTO admin_logs (admin_license, admin_name, action, target_license, details) VALUES (?, ?, ?, ?, ?)',
        { adminLicense, adminName, action, targetLicense, json.encode(details) }
    )
end

---@param vehicle AdminOwnedVehicle
---@return boolean inserted false when the plate already exists
function db.insertVehicle(vehicle)
    return MySQL.update.await([[
        INSERT IGNORE INTO player_vehicles (
            license,
            citizenid,
            vehicle,
            hash,
            mods,
            plate,
            garage,
            fuel,
            engine,
            body,
            state,
            depotprice
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, 100, 1000.0, 1000.0, ?, 0)
    ]], {
        vehicle.license,
        vehicle.citizenid,
        vehicle.model,
        tostring(joaat(vehicle.model)),
        json.encode(vehicle.mods),
        vehicle.plate,
        vehicle.garage,
        vehicle.state,
    }) > 0
end

---@param plate string
---@param state integer
---@return boolean
function db.setVehicleState(plate, state)
    return MySQL.update.await(
        'UPDATE player_vehicles SET state = ?, depotprice = 0 WHERE plate = ?',
        { state, plate }
    ) == 1
end

---@param oldPlate string
---@param newPlate string
---@return boolean
function db.changePlate(oldPlate, newPlate)
    return MySQL.update.await('UPDATE player_vehicles SET plate = ? WHERE plate = ?', { newPlate, oldPlate }) == 1
end

---@param plate string
---@return string?
function db.getVehicleModel(plate)
    return MySQL.scalar.await('SELECT vehicle FROM player_vehicles WHERE plate = ?', { plate })
end

---@param citizenid string
---@param plate string
---@return { vehicle: string, mods: string }?
function db.getOwnedVehicle(citizenid, plate)
    return MySQL.single.await(
        'SELECT vehicle, mods FROM player_vehicles WHERE citizenid = ? AND plate = ?',
        { citizenid, plate }
    )
end

return db
