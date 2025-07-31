local Color = require "src.color"
local Theme = require "src.theme"

local M = {}

local function quantize(N, ...)
    local result = {}
    for _, v in ipairs({ ... }) do
        table.insert(result, math.floor(v * (N - 1)) / (N - 1))
    end
    return result
end

--- Generate and save a color scheme from an image file.
function M.generateAndSaveScheme(imagePath, scaleFactor, targetColorCount, selectFromLength, filename)
    local colorList, colorHexCount = {}, {}
    local originalImage = love.graphics.newImage(imagePath)
    local origWidth, origHeight = originalImage:getWidth(), originalImage:getHeight()
    local newWidth = math.floor(origWidth * scaleFactor)
    local newHeight = math.floor(origHeight * scaleFactor)
    local canvas = love.graphics.newCanvas(newWidth, newHeight)
    love.graphics.setCanvas(canvas)
    love.graphics.draw(originalImage, 0, 0, 0, scaleFactor, scaleFactor)
    love.graphics.setCanvas()
    local imageData = canvas:newImageData()

    for y = 0, newHeight - 1 do
        for x = 0, newWidth - 1 do
            local r, g, b, _ = imageData:getPixel(x, y)
            local rgb = quantize(16, math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
            local color = Color("RGB", rgb)
            colorHexCount[color.hex] = (colorHexCount[color.hex] or 0) + 1
            if colorHexCount[color.hex] == 1 then table.insert(colorList, color) end
        end
    end

    local theme = Theme(colorList, colorHexCount, targetColorCount, selectFromLength)
    local scheme = {
        foreground = theme.foreground,
        background = theme.background,
        colors1 = theme.color[1],
        colors2 = theme.color[2]
    }

    -- Save to file
    M.saveSchemeToFile(scheme, filename)
    return scheme
end

--- Save a color scheme to a file in the requested format.
function M.saveSchemeToFile(scheme, filename)
    local lines = {}
    table.insert(lines, "foreground: #" .. scheme.foreground.hex .. ";")
    table.insert(lines, "background: #" .. scheme.background.hex .. ";")
    local allColors = {}
    for i = 1, 8 do
        allColors[i] = scheme.colors1[i] and scheme.colors1[i].hex or scheme.colors1[#scheme.colors1].hex
    end
    for i = 1, 8 do
        allColors[8 + i] = scheme.colors2[i] and scheme.colors2[i].hex or scheme.colors2[#scheme.colors2].hex
    end
    for i = 1, 16 do
        table.insert(lines, string.format("color%d: #%s;", i, allColors[i]))
    end
    local text = table.concat(lines, "\n")
    love.filesystem.write(filename, text)
end

return M