local labels <const> = {}

---@param group string
---@param name string
---@return string
function labels.of(group, name)
    local key <const> = ('%s.%s'):format(group, name)
    local text <const> = locale(key)

    return text ~= key and text or name
end

---@param group string
---@param names string[]
---@return AdminOption[]
function labels.options(group, names)
    local options <const> = {}

    for i, name in ipairs(names) do
        options[i] = { label = labels.of(group, name), value = name }
    end

    return options
end

return labels
