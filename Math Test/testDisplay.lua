-- Required libraries
local component = require("component")
local computer = require("computer")
local event = require("event")
local term = require("term")
local os = require("os")

-- Required components
local modem = component.modem
local gpu = component.gpu

-- Pre initialization

term.clear()
computer.beep()
print("Starting Display Script")
os.sleep(1)
print("Loading variables...")

-- Global variables
local displayInitializationState = 0
local displayKey = "abcd"
local displaySyncKey = "xyz"
local displayDataTable = { temperature = 0, status = false, message = "" } -- Fixed keys for data
local _, _, from, port, _, message

print("Done")
os.sleep(1)
print("Loading functions...")

-- Error handling functions
local function Fatal_err(error_message)
gpu.setForeground(0xFF0000)
print(debug.traceback("FATAL ERROR: " .. error_message))
gpu.setForeground(0xFFFFFF)
return nil
end

local function Warn_err(error_message)
gpu.setForeground(0xFFFF00)
print("WARN: " .. error_message)
gpu.setForeground(0xFFFFFF)
end

-- Functions
local function checkForKey(keyPort)
_, _, from, port, _, message = event.pull("modem_message")
print("Key Received From :" .. from .. " : " .. message)
if port == keyPort and message == displayKey then
print("Correct Key Received from :" .. from .. " on port :" .. port)
displayInitializationState = 1
else
gpu.set(1, 1, "Incorrect Key")
end
return displayInitializationState
end

local function displayData(data)
term.clear()
gpu.set(1, 1, "Displaying Data:")
if type(data) == "table" then
local line = 2
for key, value in pairs(data) do
gpu.set(1, line, key .. ": " .. tostring(value))
line = line + 1
end
else
gpu.set(1, 2, tostring(data)) -- Display non-table data
end
end

local function processData(key, value)
if displayDataTable[key] ~= nil then
displayDataTable[key] = value
print("Updated " .. key .. " to " .. tostring(value))
else
Warn_err("Unknown key received: " .. key)
end
end

local function receiveData()
if displayInitializationState == 2 then
local _, _, _, port, _, message = event.pull("modem_message")
if port == 1 then
local key, value = message:match("([^:]+):([^:]+)")
if key and value then
if tonumber(value) then
value = tonumber(value)
elseif value == "true" or value == "false" then
value = value == "true"
end
processData(key, value)
else
Warn_err("Malformed data received: " .. message)
end
end
else
Fatal_err("Incorrect Display State! Display State: " .. displayInitializationState)
end
end

print("Done")

-- Initialization phase 1
modem.open(1)
modem.broadcast(1, "Display waiting for key...")
print("Waiting for key...")
while displayInitializationState == 0 do
checkForKey(1)
end

-- Initialization phase 2
while displayInitializationState == 1 do
print("Attempting to sync with processor...")
modem.send(from, 1, displaySyncKey) -- Send sync key to processor
local _, _, sender, senderPort, _, receivedMessage = event.pull(5, "modem_message") -- Add a timeout of 5 seconds
if sender and senderPort == 1 and receivedMessage == displaySyncKey then
displayInitializationState = 2
print("Synced with processor")
else
Warn_err("Failed to sync with processor. Retrying...")
end
end

-- Main Loop
while displayInitializationState == 2 do
receiveData()
displayData(displayDataTable)
end