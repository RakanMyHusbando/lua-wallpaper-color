---@class Theme
---@field foreground Color
---@field background Color
---@field color [Color[],Color[]]
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
local Theme = Class()

---@param colorList Color[]
---@param countByHex table<string, number>
---@param targetColorCount number
---@param selectFromLength number
function Theme:init(colorList, countByHex, targetColorCount, selectFromLength)
    if not colorList or #colorList == 0 then
        error("colorList must be a non-empty table")
    end
    if not countByHex then
        error("countByHex must be provided")
    end

    self.targetColorCount = targetColorCount or 8
    self.color = { {}, {} }

    -- Sort by frequency
    table.sort(colorList, function(a, b)
        return (countByHex[a.hex] or 0) > (countByHex[b.hex] or 0)
    end)

    -- Copy to self.selectColorList and self.selectCountByHex
    self:_fillColorPool(colorList, countByHex, selectFromLength or 50)
    if not self.selectColorList or not self.selectCountByHex then
        error("Failed to fill color pool: selectColorList or selectCountByHex is missing")
    end

    self:_filterBySaturateAndValue()

    if #self.selectColorList > 0 then
        table.sort(self.selectColorList, function(a, b) return a.hsv[3] < b.hsv[3] end)
        self.foreground = self.selectColorList[1]
        self.background = self.selectColorList[#self.selectColorList]
        self:_createColor()
    else
        print("Warning: No colors selected for theme")
    end
end

function Theme:_filterBySaturateAndValue()
    print("filter by staturate and value (hsv[2] and hsv[3])")
    -- TODO: create weight to filter colorList
end

function Theme:_colorFillMissing()
    print("fill missing color")
    -- TODO: create new colors if missing
end

---@param colorList Color[]
---@param countByHex table<string, number>
---@param maxLength number
function Theme:_fillColorPool(colorList, countByHex, maxLength)
    self.selectColorList, self.selectCountByHex = {}, {}
    local i = 1
    while #self.selectColorList < math.min(maxLength, #colorList) and
        i <= math.min(maxLength, #colorList) do
        if countByHex[colorList[i].hex] then
            table.insert(self.selectColorList, colorList[i])
            self.selectCountByHex[colorList[i].hex] = countByHex[colorList[i].hex] or 1
        end
        i = i + 1
    end
end

function Theme:_createColor()
    table.sort(self.selectColorList, function(a, b) return a.hsv[1] > b.hsv[1] end)
    self:_findHighestContrastColor()
    if self.targetColorCount > #self.color[1] then self:_colorFillMissing() end
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
        local candidateMinDistance = self:_minDistance(candidate, 10)
        if candidateMinDistance > bestContrast then
            bestContrast = candidateMinDistance
            bestColor = candidate
        end
    end
    if not bestColor then return end
    table.insert(self.color[1], bestColor)
    if #self.color[1] < self.targetColorCount then
        self:_findHighestContrastColor()
    end
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
    for _, el in ipairs(rgb) do
        if rgbAverage > (255 / 2) then
            table.insert(result, (el < (255 / 10) and 0 or el - (255 / 10)))
        else
            table.insert(result, (el + (255 / 10) > 255 and 255 or el + (255 / 10)))
        end
    end
    self.color[2][index] = Color(COLOR_FORMAT_ENUM.RGB, result)
end

function Theme:_lightenOrDarkenPair()
    if #self.color[1] == 0 then return end
    table.sort(self.color[1], function(a, b) return a.hsv[3] < b.hsv[3] end)
    local average = self:_rgbCalcAverage(self.color[1])
    for i = 1, math.min(8, #self.selectColorList) do
        if self.color[1][i] then self:_lightenOrDarkenRgb(self.selectColorList[i].rgb, average, i) end
    end
end

return Theme
