local class = require "src.class"

--[[
When the class is created, each of the other color format is generated from the input color format.

**Warning**: Functions of class `Color` starting with "_" are supposed to be private!

# `Color.color` types
- `nil`: Color.color is not selected yet.
- `number`: Color.color is selected as color `string.format("color%d", Color.color)` from color1 to color16.
- `string`: Color.color is selected as another color like `"background"`, `"foreground"` etc.
# Usage for `Color:new(...)` | `Color(...)`
RGB
```lua
local format = COLOR_FORMAT_ENUM.RGB
local r, g, b = 255,255,255
local color = Color(format, {r, g, b})
```
HSV
```lua
local format = COLOR_FORMAT_ENUM.HSV
local h, s, v = 0, 0, 100
local color = Color(format, {h, s, v})
```
HEX
```lua
local format = COLOR_FORMAT_ENUM.HEX
local hex = "ffffff"
local color = Color(format, hex)
```
]]
---@class Color
---@field color? number | string
---@field hex string
---@field rgb [number, number, number]
---@field hsv [number, number, number]
local Color = class()

--- Initialize a color object from a given format and value.
---@param format string: Use a property of COLOR_FORMAT_ENUM.
---@param value string|[number, number, number]: the color value in the specified format like this.
function Color:init(format, value)
    if format == COLOR_FORMAT_ENUM.RGB and type(value) == "table" then
        self:_handleRgb(value)
    elseif format == COLOR_FORMAT_ENUM.HSV and type(value) == "table" then
        self:_handleHsv(value)
    elseif format == COLOR_FORMAT_ENUM.HEX and type(value) == "string" then
        self:_handleHex(value)
    else
        error("Unsupported color format or value type")
    end
end

function Color:_handleRgb(value)
    self.rgb = (value[1] > 255 or value[2] > 255 or value[3] > 255)
        and self:_quantize(16, value[1], value[2], value[3])
        or value
    self:_rgbToHex()
    self:_rgbToHsv()
end

function Color:_handleHsv(value)
    self.hsv = value
    self:_hsvToRgb()
    self:_rgbToHex()
end

function Color:_handleHex(value)
    self.hex = value
    self:_hexToRgb()
    self:_rgbToHsv()
end

---@param diffrentRgb [number,number,number]
---@return number
function Color:getContrastRatio(diffrentRgb)
    local luminance = { 0, 0 }
    local luminanceFactor = { 0.2126, 0.7152, 0.0722 }
    for i, factor in pairs(luminanceFactor) do
        if not diffrentRgb[i] then
            error("Index `diffrentRgb[" ..
                i .. "]` out of range in `Color:getContrastRation`.")
        end
        if not self.rgb[i] then
            error("Index `self.rgb[" ..
                i .. "]` out of range in `Color:getContrastRation`.")
        end
        local c = { self.rgb[i] / 255, diffrentRgb[i] / 255 }
        for j = 1, 2 do
            luminance[j] = luminance[j] + factor *
                (c[j] <= 0.03928 and c[j] / 12.92 or math.pow((c1 + 0.055) / 1.055, 2.4))
        end
    end
    table.sort(luminance, function(a, b) return a < b end)
    return (luminance[1] + 0.05) / (luminance[2] + 0.05)
end

--- Calculate difference between own hsv and `diffrentHsv`.
---@param diffrentHsv Color
---@return number
function Color:getHSVDistance(diffrentHsv)
    local h, s, v = diffrentHsv[1], diffrentHsv[2], diffrentHsv[3]
    local dh = math.min(math.abs(self.hsv[1] - h), 360 - math.abs(self.hsv[1] - h))
    local ds = math.abs(self.hsv[2] - s)
    local dv = math.abs(self.hsv[3] - v)
    return math.sqrt(dh * dh + ds * ds * 100 + dv * dv * 100)
end

--- Converts RGB color values to HEX color values.
function Color:_rgbToHex()
    self.hex = string.format("%02X%02X%02X", self.rgb[1], self.rgb[2], self.rgb[3])
end

--- Converts RGB color values to HSV color values.
function Color:_rgbToHsv()
    local r, g, b = self.rgb[1], self.rgb[2], self.rgb[3]
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local delta = max - min
    local h, s, v = 0, (max == 0 and 0 or delta / max), max
    if delta == 0 then
        h = 0
    elseif max == r then
        h = (g - b) / delta + (g < b and 6 or 0)
    elseif max == g then
        h = (b - r) / delta + 2
    elseif max == b then
        h = (r - g) / delta + 4
    end
    return { h * 60, s, v / 255 }
end

--- Converts HEX color values to RGB color values.
function Color:_hexToRgb(hex)
    self.rgb = {
        tonumber(hex:sub(1, 2), 16),
        tonumber(hex:sub(3, 4), 16),
        tonumber(hex:sub(5, 6), 16)
    }
end

--- Converts HSV color values to RGB color values.
function Color:_hsvToRgb()
    local h, s, v = self.hsv[1], self.hsv[2], self.hsv[3]
    local c, x, m, r, g, b
    if s <= 0 then
        return { math.floor(v * 255), math.floor(v * 255), math.floor(v * 255) }
    end
    h, c = h % 360, v * s
    x, m = c * (1 - math.abs((h / 60) % 2 - 1)), v - c
    if h < 60 then
        r, g, b = c, x, 0
    elseif h < 120 then
        r, g, b = x, c, 0
    elseif h < 180 then
        r, g, b = 0, c, x
    elseif h < 240 then
        r, g, b = 0, x, c
    elseif h < 300 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end
    self.hsv = {
        math.floor((r + m) * 255 + 0.5),
        math.floor((g + m) * 255 + 0.5),
        math.floor((b + m) * 255 + 0.5)
    }
end

--- Quantize a color value to a given number of levels.
--- @param N number: The number of levels to quantize to.
--- @param ... number: The color values to quantize.
--- @return table: The quantized color values.
function Color:_quantize(N, ...)
    local result = {}
    for _, v in ipairs({ ... }) do
        table.insert(result, math.floor(v * (N - 1)) / (N - 1))
    end
    return result
end

return Color
