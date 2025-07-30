local Color = require "src.color"
local Theme = require "src.theme"

--- Used to specify the format of the color when initializing a new Color object.
COLOR_FORMAT_ENUM = {
    HEX = "HEX",
    RGB = "RGB",
    HSV = "HSV",
}

local file = "assets/0.jpg"
local scaleFactor = 0.1

function love.load()
    local image = love.graphics.newImage(file)
    local width = image:getWidth() / scaleFactor
    local height = image:getHeight() / scaleFactor
    print(width, height)
end
