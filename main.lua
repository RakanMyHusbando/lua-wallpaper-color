local Color = require "src.color"
local Theme = require "src.theme"

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
local image, imageData, colorList, colorHexCount = nil, nil, {}, {}

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
    -- Load the original image
    local originalImage = love.graphics.newImage(file)
    local origWidth, origHeight = originalImage:getWidth(), originalImage:getHeight()

    -- Calculate the new size
    local newWidth = math.floor(origWidth * scaleFactor)
    local newHeight = math.floor(origHeight * scaleFactor)

    -- Create a canvas for downscaling the image
    local canvas = love.graphics.newCanvas(newWidth, newHeight)

    -- Draw the image on the canvas for downscaling
    love.graphics.setCanvas(canvas)
    love.graphics.draw(originalImage, 0, 0, 0, scaleFactor, scaleFactor)
    love.graphics.setCanvas()

    -- Create a new image from the canvas
    image = love.graphics.newImage(canvas:newImageData())

    -- Get the ImageData to read the pixels
    imageData = canvas:newImageData()

    -- Read the color of each pixel
    for y = 0, newHeight - 1 do
        for x = 0, newWidth - 1 do
            local r, g, b, _ = imageData:getPixel(x, y)
            local rgb = quantize(16, math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
            local color = Color(COLOR_FORMAT_ENUM.RGB, rgb)
            colorHexCount[color.hex] = (colorHexCount[color.hex] or 0) + 1
            if colorHexCount[color.hex] == 1 then table.insert(colorList, color) end
        end
    end

    local theme = Theme(colorList, colorHexCount, targetColorCount, selectFromLength)

    print("{\n\tforeground: #" .. theme.foreground.hex)
    print("\tbackground: #" .. theme.background.hex)
    for i = 1, 2 do
        for j, color in ipairs(theme.color[i]) do
            print("\tcolor" .. ((i - 1) * 8 + j) .. ": #" .. color.hex)
        end
    end
    print("}")
end
