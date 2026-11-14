local draw <const> = {}

---@param text string
---@param x number
---@param y number
---@param scale number
function draw.text(text, x, y, scale)
    SetTextFont(4)
    SetTextScale(scale, scale)
    SetTextColour(250, 250, 250, 255)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

return draw
