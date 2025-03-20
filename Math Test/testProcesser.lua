-- Required libraries
local component = require("component")
local event = require("event")
local os = require("os")

-- Required components
local modem = component.modem

-- Global variables
local displayKey = "abcd"
local displaySyncKey = "xyz"
local synced = false

modem.open(1)

-- Functions
local function sendKey()
    print("Sending key to display...")
    modem.broadcast(1, displayKey)
end

local function syncWithDisplay()
    print("Waiting for sync key from display...")
    local _, _, sender, senderPort, _, receivedMessage = event.pull("modem_message")
    os.sleep(1) -- Adding a small delay to ensure the message is processed
    if sender and senderPort == 1 and receivedMessage == displaySyncKey then
        print("Sync key received from display.")
        modem.send(sender, 1, displaySyncKey)
        synced = true
        return true
    else
        print("Failed to sync with display. Retrying...")
        return false
    end
end

local function sendData(key, value)
    local message = key .. ":" .. tostring(value)
    modem.broadcast(1, message)
end

-- Main Script
print("Starting Processor Script")
sendKey()
os.sleep(2) -- Wait for the display to process the key

while not syncWithDisplay() do
    os.sleep(1) -- Retry syncing every second
end

while synced do
    os.sleep(1) -- Keep syncing every second
    sendData("temperature", math.random(0, 1000)) -- Example: Sending temperature
    sendData("status", true) -- Example: Sending a boolean
    sendData("message", "Hello, Display!") -- Example: Sending a string
end