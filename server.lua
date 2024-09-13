local spawnedObjects = {}

RegisterServerEvent('broadcastObjectSpawn')
AddEventHandler('broadcastObjectSpawn', function(objectName, randomId, x, y, z)
    -- Store the object details on the server (optional, for tracking)
    table.insert(spawnedObjects, {objectName = objectName, id = randomId, x = x, y = y, z = z})

    -- Broadcast the event to all clients to spawn the object at the specified coordinates
    TriggerClientEvent('spawnObjectOnClient', -1, objectName, randomId, x, y, z)
end)

-- Optional: Command to list all spawned objects (for debugging or admin purposes)
RegisterCommand('listSpawnedObjects', function(source, args, rawCommand)
    print("List of spawned objects:")
    for i, object in ipairs(spawnedObjects) do
        print("Object ID: " .. object.id .. ", Object Name: " .. object.objectName)
    end
end, true)  -- true indicates this command is restricted to admins (or the server console)



-- Table to store the count of adjustments per object ID
local objectAdjustments = {}
local objectLowerings = {}

-- Event to handle the height adjustment
RegisterServerEvent('adjustObjectHeight')
AddEventHandler('adjustObjectHeight', function(objectId)
    -- Initialize the counts for this object ID if they don't exist
    if not objectAdjustments[objectId] then
        objectAdjustments[objectId] = 0
    end
    if not objectLowerings[objectId] then
        objectLowerings[objectId] = 0
    end

    -- If both counters are 0, we start with height adjustment
    if objectAdjustments[objectId] < 13 and objectLowerings[objectId] == 0 then
        -- Increment the height adjustment count
        objectAdjustments[objectId] = objectAdjustments[objectId] + 1

        -- Trigger the height adjustment event on all clients
        TriggerClientEvent('adjustObjectHeightOnClient', -1, objectId)

    elseif objectAdjustments[objectId] == 13 and objectLowerings[objectId] < 13 then
        -- If height adjustment is maxed out, start lowering the height
        objectLowerings[objectId] = objectLowerings[objectId] + 1

        -- Trigger the lowering event on all clients
        TriggerClientEvent('lowerObjectHeightOnClient', -1, objectId)

    elseif objectAdjustments[objectId] == 13 and objectLowerings[objectId] == 13 then
        -- Reset both counters when both have reached 13
        objectAdjustments[objectId] = 0
        objectLowerings[objectId] = 0
        print("Object ID: " .. objectId .. " counters reset after reaching limits.")
    end
end)

-- Command to debug and see how many times the height has been adjusted and lowered per object ID
RegisterCommand('debugAdjustments', function(source, args, rawCommand)
    -- Output the adjustment counts to the console
    print("Height Adjustment Counts Per Object ID:")
    for objectId, count in pairs(objectAdjustments) do
        print("Object ID: " .. objectId .. " - Adjustments: " .. count)
    end
    print("Height Lowering Counts Per Object ID:")
    for objectId, count in pairs(objectLowerings) do
        print("Object ID: " .. objectId .. " - Lowerings: " .. count)
    end
end, true)  -- true means the command can be executed by server console/admin only





local Framework = Config.Framework
local QBCore = nil
local ESX = nil

-- Framework initialization
if Framework == "QBCore" then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Framework == "ESX" then
    ESX = exports['es_extended']:getSharedObject()
end

-- Create usable shovel item based on the framework
if Framework == "QBCore" then
    -- QBCore version of usable item
    QBCore.Functions.CreateUseableItem(Config.ShovelItem, function(source, item)
        local Player = QBCore.Functions.GetPlayer(source)
        if Player.Functions.GetItemByName(item.name) then
            TriggerClientEvent("SxM-bury:UseShovel", source, item.name)
        end
    end)

elseif Framework == "ESX" then
    -- ESX version of usable item
    ESX.RegisterUsableItem(Config.ShovelItem, function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            TriggerClientEvent("SxM-bury:UseShovel", source, Config.ShovelItem)
        end
    end)
end




local attachedPlayers = {}
local attachedBy = {}

-- Sync attachment event
RegisterServerEvent("customAttach:sync")
AddEventHandler("customAttach:sync", function(targetSrc)
    local src = source
    local srcPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(targetSrc)
    
    if #(GetEntityCoords(srcPed) - GetEntityCoords(targetPed)) <= 3.0 then
        TriggerClientEvent("customAttach:syncTarget", targetSrc, src)
        attachedPlayers[src] = targetSrc
        attachedBy[targetSrc] = src
    else
        print("Players not within 3.0 units.")
    end
end)

-- Stop attachment event
RegisterServerEvent("customAttach:stop")
AddEventHandler("customAttach:stop", function(targetSrc)
    local src = source
    
    if attachedPlayers[src] then
        TriggerClientEvent("customAttach:stopTarget", targetSrc)
        attachedBy[attachedPlayers[src]] = nil
        attachedPlayers[src] = nil
    elseif attachedBy[src] then
        TriggerClientEvent("customAttach:stopTarget", attachedBy[src])
        attachedPlayers[attachedBy[src]] = nil
        attachedBy[src] = nil
    end

    -- Update the position of the detached player
    local targetPed = GetPlayerPed(targetSrc)
    local srcPed = GetPlayerPed(src)
    local srcCoords = GetEntityCoords(srcPed)
    SetEntityCoords(targetPed, srcCoords.x, srcCoords.y, srcCoords.z, false, false, false, true)
end)

-- Player dropped event
AddEventHandler('playerDropped', function(reason)
    local src = source
    
    if attachedPlayers[src] then
        TriggerClientEvent("customAttach:stopTarget", attachedPlayers[src])
        attachedBy[attachedPlayers[src]] = nil
        attachedPlayers[src] = nil
    end

    if attachedBy[src] then
        TriggerClientEvent("customAttach:stopTarget", attachedBy[src])
        attachedPlayers[attachedBy[src]] = nil
        attachedBy[src] = nil
    end
end)

-- Adjust heading on the server and broadcast it to all clients
RegisterServerEvent('updateHeading')
AddEventHandler('updateHeading', function(adjustment)
    local src = source
    local srcPed = GetPlayerPed(src)
    local currentHeading = GetEntityHeading(srcPed)
    local newHeading = currentHeading + adjustment

    -- Apply the new heading on the server side
    SetEntityHeading(srcPed, newHeading)

    -- Broadcast the new heading to all clients
    TriggerClientEvent('syncHeading', -1, src, newHeading)
end)





-- Server-Side Script

RegisterServerEvent('notifyPlayerInAnimation')
AddEventHandler('notifyPlayerInAnimation', function(playerId, animName, trunkBoneIndex, distance, trunkPos)
    -- Broadcast the animation info to all clients
    TriggerClientEvent('receivePlayerAnimationInfo', -1, playerId, animName, trunkBoneIndex, distance, trunkPos)
end)

-- Server-side tracking of who is carrying whom
local carryRelationships = {}

-- Event to start carrying a player
RegisterServerEvent('carry:server:startCarry')
AddEventHandler('carry:server:startCarry', function(targetPlayer)
    local sourcePlayer = source

    -- Store the carry relationship on the server
    carryRelationships[targetPlayer] = sourcePlayer

    -- Notify both players to start animations
    TriggerClientEvent('carry:client:startCarry', sourcePlayer, targetPlayer)
    TriggerClientEvent('carry:client:beingCarried', targetPlayer, sourcePlayer)
    
    print("Player ID", sourcePlayer, "is now carrying player ID", targetPlayer) -- Server-side debug
end)

-- Event to stop carrying a player
RegisterServerEvent('carry:server:stopCarry')
AddEventHandler('carry:server:stopCarry', function(targetPlayer)
    local sourcePlayer = source

    -- Clear the carry relationship on the server
    if carryRelationships[targetPlayer] == sourcePlayer then
        carryRelationships[targetPlayer] = nil
    end

    -- Notify both players to stop the animations and detach entities
    TriggerClientEvent('carry:client:stopCarry', sourcePlayer)
    TriggerClientEvent('carry:client:stopCarry', targetPlayer)
    
    print("Player ID", sourcePlayer, "has stopped carrying player ID", targetPlayer) -- Server-side debug
end)

-- Command to debug relationships (Optional for admins)
RegisterCommand('debugcarry', function(source, args, rawCommand)
    print("Current carry relationships:", carryRelationships) -- Debug all current carry relationships
end, true) -- The 'true' here makes the command only executable by admins


-- Event to check the carry status for a specific player
RegisterServerEvent('carry:server:checkCarryStatus')
AddEventHandler('carry:server:checkCarryStatus', function()
    local sourcePlayer = source

    -- Check if the player is carrying someone
    local targetPlayer = nil
    for carried, carrier in pairs(carryRelationships) do
        if carrier == sourcePlayer then
            targetPlayer = carried
            break
        end
    end

    -- Send the carry status back to the client
    local isCarrying = targetPlayer ~= nil
    TriggerClientEvent('carry:client:sendCarryStatus', sourcePlayer, isCarrying, targetPlayer)
end)


-- Server-Side Script

RegisterServerEvent('carry:server:attachToTrunk')
AddEventHandler('carry:server:attachToTrunk', function(carrierPlayerId, targetPlayerId, vehicleNetId, trunkBoneIndex)
    -- Broadcast to all clients to handle the attachment process
    TriggerClientEvent('carry:client:attachToTrunk', -1, carrierPlayerId, targetPlayerId, vehicleNetId, trunkBoneIndex)
end)

-- Table to store player and targeted ID data on the server
local playerTargetData = {}

-- Handle receiving player and object data from the client
RegisterServerEvent('sendPlayerAndObjectData')
AddEventHandler('sendPlayerAndObjectData', function(playerSrc, objectId)
    -- Debugging: Print the received player src and object ID
    print("Received from client -> Player src: " .. playerSrc .. ", Object ID: " .. objectId)

    -- Store the player src as a targeted ID
    playerTargetData[playerSrc] = objectId

    -- Send the targeted player ID and object ID back to the client
    TriggerClientEvent('receiveTargetedData', playerSrc, playerSrc, objectId)

    -- Debugging: Print the stored data
    print("Stored targeted ID for player src: " .. playerSrc .. " -> Targeted Object ID: " .. objectId)
end)

-- Example function to retrieve all stored data for debugging purposes
RegisterCommand('showStoredData', function(source, args, rawCommand)
    print("Current stored player-targeted data:")
    for playerSrc, objectId in pairs(playerTargetData) do
        print("Player src: " .. playerSrc .. " has targeted Object ID: " .. objectId)
    end
end, true)


-- Server-side event to handle player movement
RegisterNetEvent("dropPlayerAtCoords")
AddEventHandler("dropPlayerAtCoords", function(targetPlayerId, coords)
    -- Ensure the target player ID is valid
    if targetPlayerId then
        TriggerClientEvent("dropPlayerAtCoords", targetPlayerId, coords)
    end
end)

