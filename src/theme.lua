local class = require("src.class")

--[[
Creates a color theme from a list of colors and a map of color hex value as key
and a number as value to determine occurrence of a color.

**Warning**: Functions of class `Color` starting with "_" are supposed to be private!

---
# `Theme.color`
- `Theme.color[1]` and `Theme.color[2]` supposed to have a max length of 8.
- in `Theme.color[1]` are colors that are extracted from the color list input.
- in `Theme.color[2]` are the same colors as Theme.color[1] but bit lightened or darkened.
- `Theme.color[2]` gets darkened if the average of each rgb value `(r+g+b)/3` is more than `255/2`.
- `Theme.color[2]` gets lightened if the average of each rgb value `(r+g+b)/3` is less than `255/2`.

---
# Usage for `Theme:new(...)` | `Theme(...)`
```lua
local targetColorCount = 3
local selectFromLength = 10 -- `selectFromLength` >= `targetColorCount`
-- min length is `targetColorCount`
local colors = {
    Color(0, 255, 0),
    -- ...
}
-- min `targetColorCount` elements
local countByHex = {
    ["00FF00"] = 4,
    --...
}
local theme = Theme(colors, countByHex, targetColorCount, selectFromLength)
```
]]
---@class Theme
---@field foreground Color
---@field background Color
---@field color [Color[],Color[]]
local Theme = class()

---@param colorList Color[]
---@param countByHex table<string, number>
---@param targetColorCount number
---@param selectFromLength number
function Theme:init(colorList, countByHex, targetColorCount, selectFromLength)
    self.targetColorCount = targetColorCount
    self.color, self.selectColorList, self.selectCountByHex = { {}, {} }, {}, {}
    print(colorList)
    print(countByHex)
    print(targetColorCount)
    print(selectedFromLength)
    table.sort(colorList,function(a, b)
        return countByHex[a.hex] > countByHex[b.hex]
    end)
    for i = 1, selectFromLength do
        if not colorList[i] then break end
        self.selectColorList[i] = colorList[i]
        self.selectCountByHex[colorList[i].hex] = countByHex[colorList[i][i].hex]
    end
    table.sort(self.selectColorList, function(a, b) return a.hsv[3] < b.hsv[3] end)
    self.foreground = self.selectColorList[1]
    self.background = self.selectColorList[#self.selectColorList]
    self:_createColor()
end

function Theme:_colorFillMissing()
    -- TODO: create new colors if missing
end

function Theme:_createColor()
    table.sort(self.selectColorList, function(a, b)
        return self.selectCountByHex[a.hex] > self.selectCountByHex[b.hex]
    end)
    while #self.selectColorList < self.targetColorCount
        and #self.selectColorList < #self.selectColorList do
        self:_findHighestContrastColor()
    end
    if self.targetColorCount > #self.color then self:_colorFillMissing() end
    self:_lightenOrDarkenPair()
end

--- Get minimum Distance between tow color 100% - `weightContrastPercent` -> weight of hsv distance in percent
---@param candidate Color
---@param weightContrastPercent? number: default: 70%
---@return number
function Theme:_minDistance(candidate, weightContrastPercent)
    local contrast, hsvDist, result = 0, 0, math.huge
    local wcp = weightContrastPercent or 70
    local contrastFactor = wcp / 100
    local hsvDistFactor = (100 - wcp) / 100
    for _, selected_color in ipairs(self.selectColorList) do
        contrast = candidate:getContrastRatio(selected_color.rgb)
        hsvDist = candidate:getHSVDistance(selected_color.hsv)
        result = math.min(result, contrast * contrastFactor + hsvDist * hsvDistFactor)
    end
    return result
end

function Theme:_findHighestContrastColor()
    local bestColor, bestContrast = nil, 0
    for _, candidate in ipairs(self.selectColorList) do
        if not self.selectCountByHex[candidate.hex] then
            local candidateMinDistance = self:_minDistance(candidate, 50)
            if candidateMinDistance > bestContrast then
                bestContrast = candidateMinDistance
                bestColor = candidate
            end
        end
    end
    if not bestColor then return end
    table.insert(self.selectColorList, bestColor)
    self.selectCountByHex[bestColor.hex] = true
end

---@param colors Color[]
---@return number
function Theme:_rgbCalcAverage(colors)
    local sum = 0
    for _, color in ipairs(colors) do
        for _, value in ipairs(color.rgb) do
            sum = sum + value
        end
    end
    return sum / (#colors * 3)
end

---@param rgb [number,number,number]
---@param rgbAverage number
function Theme:_lightenOrDarkenRgb(rgb, rgbAverage, index)
    local result = {}
    for i, el in ipairs(rgb) do
        if rgbAverage > (255 / 2) then
            table.insert(result, (el < (255 / 10) and 0 or el < (255 / 10)))
        else
            table.insert(result, (el + (255 / 10) > 255 and 255 or el + (255 / 10)))
        end
    end
    self.color[2][index] = Color(COLOR_FORMAT_ENUM.RGB, result) or self.color[1][index]
end

function Theme:_lightenOrDarkenPair()
    table.sort(self.selectColorList, function(a, b) return a.hsv[3] < b.hsv[3] end)
    local average = self:_rgbCalcAverage(self.selectColorList)
    for i = 1, 8 do
        self:_lightenOrDarkenRgb(self.selectColorList[i].rgb, average, i)
        self.color[1][i] = self.selectColorList[i] or Color(COLOR_FORMAT_ENUM.RGB, { 0, 0, 0 })
    end
end

return Theme
