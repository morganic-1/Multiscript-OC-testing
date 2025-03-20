local frameBuffer = {}

local component = require("component")
local gpu = component.gpu

-- Get screen resolution
local width, height = gpu.getResolution()

-- Buffers
local bufferCurrent = {}
local bufferNext = {}

-- Initialize Buffers
function frameBuffer.init()
    for y = 1, height do
        bufferCurrent[y] = {}
        bufferNext[y] = {}
        for x = 1, width do
            bufferCurrent[y][x] = " "
            bufferNext[y][x] = " "
        end
    end
end

-- Function to draw to the next buffer
function frameBuffer.setPixel(x, y, char)
    if x >= 1 and x <= width and y >= 1 and y <= height then
        bufferNext[y][x] = char
    end
end

-- Function to clear the next buffer
function frameBuffer.clear(char)
    char = char or " "
    for y = 1, height do
        for x = 1, width do
            bufferNext[y][x] = char
        end
    end
end

-- Function to render buffer to screen
function frameBuffer.render()
    for y = 1, height do
        for x = 1, width do
            local char = bufferNext[y][x]
            if bufferCurrent[y][x] ~= char then
                gpu.set(x, y, char)
                bufferCurrent[y][x] = char
            end
        end
    end
end

-- Return the library
return frameBuffer