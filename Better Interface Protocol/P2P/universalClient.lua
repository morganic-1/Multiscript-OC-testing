-- Required Libraries
local component = require("component")
local computer = require("computer")
local event = require("event")
local os = require("os")

-- Required Component
local modem = component.modem

-- Global Variables
local runtimePhase = 0

local foundClients = 0
local connectedClients = 0
local port = 1

-- Global Strings
local myAddress = modem.address()
local networkScanKey = "scan" -- Replace with your network scan key
local globalSyncKey = "whatever" -- Replace with your sync key

-- Global Tables
local foundClientAddresses = {}
local clientAddresses = {} -- Data will be entered like this: { [Index] = address } where the Index is the type of client (processor, display, etc.)
local receivedMessages = {} -- Data will be entered like this: { [Index] = value } where the Index is the address the message was sent from and the value is what was sent

-- Global Booleans

-- Functions
local function scanNetwork()
    modem.broadcast(port, networkScanKey)
    local _, remoteAddress, _, _, _, message = event.pull(1,"modem_message")
    if message == networkScanKey then
        table.insert(foundClientAddresses, remoteAddress)
        foundClients = foundClients + 1
    end
end

local function syncWithClient(Index)
    local _, remoteAddress, _, _, _, Key, type = event.pull(1,"modem_message")
    modem.send(foundClientAddresses[Index], port, globalSyncKey)
    if Key == globalSyncKey then
        table.insert(clientAddresses, type, remoteAddress)
        connectedClients = connectedClients + 1
        runtimePhase = 2
        return true
    else
        return false
    end
end

local function receiveData()
    local _, remoteAddress, _, _, _, message = event.pull(1, "modem_message")
    for _, address in ipairs(clientAddresses) do
        if remoteAddress == address then
            receivedMessages[remoteAddress] = message
            break
        end
    end
end

local function sendData(type, Data)
    modem.send(clientAddresses[type], port, Data)
end

-- Initialization
modem.open(port)
runtimePhase = 1
repeat
    scanNetwork()
    os.sleep(1)
until foundClients > 0

-- Syncing with initial client
repeat
    local synced = syncWithClient(1)
    os.sleep(1)
until synced == true

-- Main Communication Loop
while runtimePhase == 2 do
    receiveData()
    os.sleep(1)
    sendData(basic, Data)
end