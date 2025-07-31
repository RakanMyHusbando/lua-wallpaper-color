Class = require "src.class"
Color = require "src.color"
Theme = require "src.theme"
local Scheme = require "src.scheme"

--- Used to specify the format of the color when initializing a new Color object.
COLOR_FORMAT_ENUM = {
    HEX = "HEX",
    RGB = "RGB",
    HSV = "HSV",
}

local file = "assets/1.jpg"
local scaleFactor = 0.1      -- reduces the image size to 10% of the original
local targetColorCount = 8   -- Number of colors to target in the theme
local selectFromLength = 100 -- Number with the most frequent colors to select from when creating the theme
local theme ---@type Theme?
local imageData
local colorList, colorHexCount = {}, {}

--- @param N number: The number of levels to quantize to.
--- @param ... number: The color values to quantize.
--- @return table
local function quantize(N, ...)
    local result = {}
    for _, v in ipairs({ ... }) do
        table.insert(result, math.floor(v * (N - 1)) / (N - 1))
    end
    return result
end

function love.load()
    love.window.setMode(800, 600, { resizable = true })
    -- Use the modular function to generate and save the scheme
    local scheme = Scheme.generateAndSaveScheme(file, scaleFactor, targetColorCount, selectFromLength, "scheme.txt")
    -- Assign theme for drawing
    theme = {
        foreground = scheme.foreground,
        background = scheme.background,
        color = {scheme.colors1, scheme.colors2}
    }
end

function love.draw()
    if not theme then return end
    local squareSize = 20
    local spacing = 5
    local startX = 50
    local startY = 50
    local textOffsetY = squareSize + 5
    local verticalOffset = squareSize + spacing + textOffsetY

    -- Draw foreground color
    local nr, ng, nb = theme.foreground:getRgbNormalized()
    love.graphics.setColor(nr, ng, nb)
    love.graphics.rectangle("fill", startX, startY, squareSize, squareSize)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("foreground #" .. theme.foreground.hex, startX + squareSize + spacing,
        startY + (squareSize / 2) - 10)

    -- Draw background color
    startY = startY + verticalOffset
    love.graphics.setColor(theme.background:getRgbNormalized())
    love.graphics.rectangle("fill", startX, startY, squareSize, squareSize)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("background #" .. theme.background.hex, startX + squareSize + spacing,
        startY + (squareSize / 2) - 10)

    -- Draw first group of theme colors
    for i, color in ipairs(theme.color[1]) do
        startY = startY + verticalOffset
        nr, ng, nb = theme.color[1][i]:getRgbNormalized()
        love.graphics.setColor(nr, ng, nb)
        love.graphics.rectangle("fill", startX, startY, squareSize, squareSize)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(string.format("color%d #%s", i, color.hex), startX + squareSize + spacing,
            startY + (squareSize / 2) - 10)
    end

    -- Draw second group of theme colors
    for i, color in ipairs(theme.color[2]) do
        startY = startY + verticalOffset
        nr, ng, nb = theme.color[2][i]:getRgbNormalized()
        love.graphics.setColor(nr, ng, nb)
        love.graphics.rectangle("fill", startX, startY, squareSize, squareSize)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(string.format("color%d #%s", 8 + i, color.hex), startX + squareSize + spacing,
            startY + (squareSize / 2) - 10)
    end
end
