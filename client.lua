-- Carry and drop in trunk

local attachment = {
    InProgress = false,
    targetSrc = -1,
    type = "",
    playerAttaching = {
        animDict = "combat@drag_ped@",
        anim = "injured_drag_plyr",
        flag = 49,
    },
    playerAttached = {
        animDict = "combat@drag_ped@",
        anim = "injured_drag_ped",
        attachX = 0.0,
        attachY = 0.5,  -- Adjusted position
        attachZ = 0.0,
        flag = 33,
    }
}

-- Function to show a notification
local function showNotification(text)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

-- Function to find the closest player
local function findClosestPlayer(radius)
    local players = GetActivePlayers()
    local closestDistance = -1
    local closestPlayer = -1
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    for _, playerId in ipairs(players) do
        local targetPed = GetPlayerPed(playerId)
        if targetPed ~= playerPed then
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(targetCoords - playerCoords)
            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = playerId
                closestDistance = distance
            end
        end
    end
    if closestDistance ~= -1 and closestDistance <= radius then
        return closestPlayer
    else
        return nil
    end
end

-- Function to ensure an animation dictionary is loaded
local function ensureAnimDictLoaded(animDict)
    if not HasAnimDictLoaded(animDict) then
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(0)
        end        
    end
    return animDict
end

-- Command to attach a player
RegisterCommand("attachPlayer", function()
    if not attachment.InProgress then
        local closestPlayer = findClosestPlayer(3)
        if closestPlayer then
            local targetSrc = GetPlayerServerId(closestPlayer)
            if targetSrc ~= -1 then
                local targetPed = GetPlayerPed(closestPlayer)

                -- Check if the target player is in one of the allowed animations
                local isPlayingAllowedAnim = IsEntityPlayingAnim(targetPed, 'dead', 'dead_a', 3) or 
                   IsEntityPlayingAnim(targetPed, 'combat@damage@writhe', 'writhe_loop', 3)

                if isPlayingAllowedAnim then
                    attachment.InProgress = true
                    attachment.targetSrc = targetSrc
                    TriggerServerEvent("customAttach:sync", targetSrc)
                    ensureAnimDictLoaded(attachment.playerAttaching.animDict)
                    ensureAnimDictLoaded(attachment.playerAttached.animDict)
                    attachment.type = "attaching"
                else
                    showNotification("~r~Player is not in a carryable state!")
                end
            else
                showNotification("~r~No one nearby to attach!")
            end
        else
            showNotification("~r~No one nearby to attach!")
        end
    else
        attachment.InProgress = false
        ClearPedSecondaryTask(PlayerPedId())
        DetachEntity(PlayerPedId(), true, false)
        TriggerServerEvent("customAttach:stop", attachment.targetSrc)
        attachment.targetSrc = -1
    end
end, false)


-- Event to sync attachment to target
RegisterNetEvent("customAttach:syncTarget")
AddEventHandler("customAttach:syncTarget", function(targetSrc)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetSrc))
    attachment.InProgress = true
    ensureAnimDictLoaded(attachment.playerAttached.animDict)
    AttachEntityToEntity(PlayerPedId(), targetPed, 11816, attachment.playerAttached.attachX, attachment.playerAttached.attachY, attachment.playerAttached.attachZ, 0.5, 0.5, 180, false, false, false, false, 2, false)
    attachment.type = "beingAttached"
end)

-- Event to stop attachment
RegisterNetEvent("customAttach:stopTarget")
AddEventHandler("customAttach:stopTarget", function()
    attachment.InProgress = false
    ClearPedSecondaryTask(PlayerPedId())
    DetachEntity(PlayerPedId(), true, false)
end)

-- Main thread for managing attachment animations and movements
Citizen.CreateThread(function()
    while true do
        if attachment.InProgress then
            local playerPed = PlayerPedId()
            if attachment.type == "beingAttached" then
                if not IsEntityPlayingAnim(playerPed, attachment.playerAttached.animDict, attachment.playerAttached.anim, 3) then
                    TaskPlayAnim(playerPed, attachment.playerAttached.animDict, attachment.playerAttached.anim, 8.0, -8.0, -1, attachment.playerAttached.flag, 0, false, false, false)
                end
            elseif attachment.type == "attaching" then
                if not IsEntityPlayingAnim(playerPed, attachment.playerAttaching.animDict, attachment.playerAttaching.anim, 3) then
                    TaskPlayAnim(playerPed, attachment.playerAttaching.animDict, attachment.playerAttaching.anim, 8.0, -8.0, -1, attachment.playerAttaching.flag, 0, false, false, false)
                end
                
                -- Movement and heading adjustment logic
                if IsControlPressed(0, 32) or IsControlPressed(0, 33) then  -- 'W' or 'S' key
                    if not IsEntityPlayingAnim(playerPed, attachment.playerAttaching.animDict, attachment.playerAttaching.anim, 3) then
                        TaskPlayAnim(playerPed, attachment.playerAttaching.animDict, attachment.playerAttaching.anim, 8.0, -8.0, -1, attachment.playerAttaching.flag, 0, false, false, false)
                    end

                    -- Adjust player heading with 'A' and 'D' keys
                    if IsControlPressed(0, 34) then  -- 'A' key
                        TriggerServerEvent('updateHeading', 1.0)  -- Request server to adjust heading left by 1 degree
                    elseif IsControlPressed(0, 35) then  -- 'D' key
                        TriggerServerEvent('updateHeading', -1.0)  -- Request server to adjust heading right by 1 degree
                    end
                else
                    ClearPedTasks(playerPed)
                end
            end
        end
        Wait(0)
    end
end)

-- Event handler for updating the player's heading from the server
RegisterNetEvent('syncHeading')
AddEventHandler('syncHeading', function(source, heading)
    local playerPed = GetPlayerPed(GetPlayerFromServerId(source))
    if playerPed and playerPed ~= -1 then
        SetEntityHeading(playerPed, heading)
    end
end)

-- Load the animation dictionary when the resource starts
Citizen.CreateThread(function()
    RequestAnimDict("combat@drag_ped@")
    while not HasAnimDictLoaded("combat@drag_ped@") do
        Citizen.Wait(100)
    end
end)


-- Ensure the animation plays when 'W' or 'S' key is pressed
Citizen.CreateThread(function()
    local isPlayingAnim = false

    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()

        if attachment.InProgress then
            if IsControlPressed(0, 32) or IsControlPressed(0, 33) or IsControlPressed(0, 34) or IsControlPressed(0, 35) then  -- 'W', 'A', 'S' or 'D' key
                if not isPlayingAnim then
                    TaskPlayAnim(playerPed, "combat@drag_ped@", "injured_drag_plyr", 8.0, -8.0, -1, 1, 0, false, false, false)
                    isPlayingAnim = true
                end

                -- Adjust player heading with 'A' and 'D' keys
                if IsControlPressed(0, 34) then  -- 'A' key
                    local heading = GetEntityHeading(playerPed)
                    SetEntityHeading(playerPed, heading + 1.0)  -- Turn left
                elseif IsControlPressed(0, 35) then  -- 'D' key
                    local heading = GetEntityHeading(playerPed)
                    SetEntityHeading(playerPed, heading - 1.0)  -- Turn right
                end
            else
                if isPlayingAnim then
                    ClearPedTasks(playerPed)
                    isPlayingAnim = false

                    -- Ensure the attached player is positioned correctly before detachment
                    local targetPed = GetPlayerPed(GetPlayerFromServerId(attachment.targetSrc))
                    local playerCoords = GetEntityCoords(playerPed)
                    SetEntityCoords(targetPed, playerCoords.x, playerCoords.y, playerCoords.z, false, false, false, true)

                    -- Trigger detachment when no key is pressed
                    attachment.InProgress = false
                    DetachEntity(playerPed, true, false)
                    TriggerServerEvent("customAttach:stop", attachment.targetSrc)
                    attachment.targetSrc = -1
                end
            end

            if isPlayingAnim then
                if not IsEntityPlayingAnim(playerPed, "combat@drag_ped@", "injured_drag_plyr", 3) then
                    TaskPlayAnim(playerPed, "combat@drag_ped@", "injured_drag_plyr", 8.0, -8.0, -1, 1, 0, false, false, false)
                end
            end
        end
    end
end)



-- Client-Side Script

-- Variables to store the text and position received from the server
local displayText = ""
local textPosition = nil
local isNearTrunk = false  -- Variable to check proximity to the trunk

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) -- Prevents crashing, runs every frame

        local playerPed = PlayerPedId()
        local vehicle = GetClosestVehicle(GetEntityCoords(playerPed), 5.0, 0, 70)

        if vehicle ~= 0 then
            -- Get the trunk bone index and position
            local trunkBoneIndex = GetEntityBoneIndexByName(vehicle, "boot")
            local trunkPos = GetWorldPositionOfEntityBone(vehicle, trunkBoneIndex)
            local playerPos = GetEntityCoords(playerPed)

            -- Calculate the distance between the player and the trunk
            local distance = #(playerPos - trunkPos)

            if distance <= 3.0 then
                isNearTrunk = true  -- Player is near the trunk
                -- Check if the player is in one of the specified animations
                local inWritheAnimation = IsEntityPlayingAnim(playerPed, 'combat@damage@writhe', 'writhe_loop', 3)
                local inDeadAnimation = IsEntityPlayingAnim(playerPed, 'dead', 'dead_a', 3)

                if inWritheAnimation or inDeadAnimation then
                    local animName = inWritheAnimation and "writhe_loop" or "dead_a"
                    
                    -- Send the animation data to the server
                    TriggerServerEvent('notifyPlayerInAnimation', GetPlayerServerId(PlayerId()), animName, trunkBoneIndex, distance, trunkPos)
                end

            else
                isNearTrunk = false -- Player is not near the trunk
            end
        else
            isNearTrunk = false -- No vehicle nearby
        end
    end
end)



-- Handle the broadcast from the server and update the existing text display for all clients
RegisterNetEvent('receivePlayerAnimationInfo')
AddEventHandler('receivePlayerAnimationInfo', function(playerId, animName, trunkBoneIndex, distance, trunkPos)
    -- Update the display text and position with the data received from the server
    displayText = string.format("Player %d in Animation: %s\nDistance: %.2f\nTrunk Bone ID: %d", playerId, animName, distance, trunkBoneIndex)
    textPosition = trunkPos
end)

-- Thread to draw the text only when there is data to display
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) -- This loop will run every frame to check if there's something to display

        if displayText ~= "" and textPosition ~= nil then
            -- If there's something to display, draw the text
            -- DrawText3D(textPosition.x, textPosition.y, textPosition.z, displayText)
        end
    end
end)

-- Variables to store the text and position received from the server
local displayText = ""
local textPosition = nil
local isNearTrunk = false  -- Variable to check proximity to the trunk
local wasNearTrunk = true  -- Track if the player was near the trunk in the previous frame

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100) -- Check every 100ms

        local playerPed = PlayerPedId()
        local vehicle = GetClosestVehicle(GetEntityCoords(playerPed), 5.0, 0, 70)

        if vehicle ~= 0 then
            -- Get the trunk bone index and position
            local trunkBoneIndex = GetEntityBoneIndexByName(vehicle, "boot")
            local trunkPos = GetWorldPositionOfEntityBone(vehicle, trunkBoneIndex)
            local playerPos = GetEntityCoords(playerPed)

            -- Calculate the distance between the player and the trunk
            local distance = #(playerPos - trunkPos)

            if distance <= 3.0 then
                isNearTrunk = true  -- Player is near the trunk

            else
                isNearTrunk = false -- Player is not near the trunk
            end
        else
            isNearTrunk = false -- No vehicle nearby
        end

        -- Check if the player was near the trunk and now is not, trigger the drop
        if carrying and not isNearTrunk and wasNearTrunk then
            TriggerServerEvent('carry:server:stopCarry', carriedPlayer) -- Drop the target player
            carrying = false -- Ensure carrying is reset so we don't trigger again
        end

        -- Update the tracking variable
        wasNearTrunk = isNearTrunk
    end
end)



-- Carry animation

local carrying = false
local carriedPlayer = nil
local carrierPlayer = nil -- Store the ID of the player carrying you
local isNearTrunk = false -- Variable to check proximity to the trunk
local wasNearTrunk = true -- Track if the player was near the trunk in the previous frame

-- Function to carry a player
RegisterNetEvent('carry:client:startCarry')
AddEventHandler('carry:client:startCarry', function(targetPlayer)
    if not isNearTrunk then
        print("You must be near a trunk to carry someone.")
        return -- Block the action if not near the trunk
    end

    local playerPed = PlayerPedId()
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetPlayer))

    if carrying then
        return -- Prevent multiple carry actions
    end

    carrying = true
    carriedPlayer = targetPlayer

    print("You (ID:", GetPlayerServerId(PlayerId()), ") are carrying player ID:", targetPlayer) -- Debug message

    RequestAnimDict("missfinale_c2mcs_1")
    while not HasAnimDictLoaded("missfinale_c2mcs_1") do
        Citizen.Wait(100)
    end

    TaskPlayAnim(playerPed, "missfinale_c2mcs_1", "fin_c2_mcs_1_camman", 8.0, -8.0, -1, 49, 0, false, false, false)
    
    AttachEntityToEntity(targetPed, playerPed, 0, 0.26, 0.15, 0.63, 0.5, 0.5, 0.0, false, false, false, false, 2, false)
end)

-- Function to stop carrying a player
RegisterNetEvent('carry:client:stopCarry')
AddEventHandler('carry:client:stopCarry', function()
    local playerPed = PlayerPedId()
    
    if carriedPlayer then
        local targetPed = GetPlayerPed(GetPlayerFromServerId(carriedPlayer))
        DetachEntity(targetPed, true, true)
        ClearPedTasksImmediately(targetPed)

        print("You (ID:", GetPlayerServerId(PlayerId()), ") have stopped carrying player ID:", carriedPlayer) -- Debug message
    end
    
    DetachEntity(playerPed, true, true)
    ClearPedTasksImmediately(playerPed)

    carrying = false
    carriedPlayer = nil
end)

-- Triggered when being carried
RegisterNetEvent('carry:client:beingCarried')
AddEventHandler('carry:client:beingCarried', function(carrierPlayerId)
    local playerPed = PlayerPedId()
    carrierPlayer = carrierPlayerId

    print("You (ID:", GetPlayerServerId(PlayerId()), ") are being carried by player ID:", carrierPlayerId) -- Debug message

    RequestAnimDict("nm")
    while not HasAnimDictLoaded("nm") do
        Citizen.Wait(100)
    end

    TaskPlayAnim(playerPed, "nm", "firemans_carry", 8.0, -8.0, -1, 33, 0, false, false, false)
    
    local carrierPed = GetPlayerPed(GetPlayerFromServerId(carrierPlayerId))
    AttachEntityToEntity(playerPed, carrierPed, 0, 0.26, 0.15, 0.63, 0.5, 0.5, 0.0, false, false, false, false, 2, false)
end)

-- Command to start carrying a player
RegisterCommand('carry', function()
    local closestPlayer = GetClosestPlayer()
    local playerPed = PlayerPedId()
    local vehicle = GetClosestVehicle(GetEntityCoords(playerPed), 5.0, 0, 70)

    if vehicle ~= 0 then
        -- Check if the trunk is open or destroyed
        local trunkDoorIndex = 5 -- The trunk door index
        if GetVehicleDoorAngleRatio(vehicle, trunkDoorIndex) > 0 or IsVehicleDoorDamaged(vehicle, trunkDoorIndex) then
            if closestPlayer then
                TriggerServerEvent('carry:server:startCarry', GetPlayerServerId(closestPlayer))
            else
                print("No player nearby to carry")
            end
        else
            print("The trunk is closed. You cannot carry anyone.")
        end
    else
        print("No vehicle nearby.")
    end
end)

-- Command to stop carrying
RegisterCommand('stopcarry', function()
    if carrying then
        TriggerServerEvent('carry:server:stopCarry', carriedPlayer)
    else
        print("You are not carrying anyone")
    end
end)

-- Utility function to get the closest player
function GetClosestPlayer()
    local players = GetActivePlayers()
    local closestDistance = -1
    local closestPlayer = -1
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)

    for _, player in ipairs(players) do
        local targetPed = GetPlayerPed(player)
        if targetPed ~= playerPed then
            local targetPos = GetEntityCoords(targetPed)
            local distance = #(playerPos - targetPos)
            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = player
                closestDistance = distance
            end
        end
    end

    if closestDistance ~= -1 and closestDistance <= 3.0 then
        return closestPlayer
    else
        return nil
    end
end

-- Thread to monitor proximity to the trunk and stop carrying if out of range
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100) -- Check every 100ms

        local playerPed = PlayerPedId()
        local vehicle = GetClosestVehicle(GetEntityCoords(playerPed), 5.0, 0, 70)

        if vehicle ~= 0 then
            -- Get the trunk bone index and position
            local trunkBoneIndex = GetEntityBoneIndexByName(vehicle, "boot")
            local trunkPos = GetWorldPositionOfEntityBone(vehicle, trunkBoneIndex)
            local playerPos = GetEntityCoords(playerPed)

            -- Calculate the distance between the player and the trunk
            local distance = #(playerPos - trunkPos)

            if distance <= 3.0 then
                isNearTrunk = true  -- Player is near the trunk
            else
                isNearTrunk = false -- Player is not near the trunk
            end
        else
            isNearTrunk = false -- No vehicle nearby
        end

        -- Check if the player was near the trunk and now is not, trigger the drop and debug
        if carrying and not isNearTrunk and wasNearTrunk then
            print("Player ID:", GetPlayerServerId(PlayerId()), "moved out of radius while carrying player ID:", carriedPlayer)
            TriggerServerEvent('carry:server:stopCarry', carriedPlayer) -- Drop the target player
        end

        -- Update the tracking variable
        wasNearTrunk = isNearTrunk
    end
end)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) -- Check every frame

        if isNearTrunk and carrying then
            -- Check if the player presses the "E" key
            if IsControlJustReleased(0, 38) then -- 38 is the default control ID for the "E" key
                local playerPed = PlayerPedId()
                local vehicle = GetClosestVehicle(GetEntityCoords(playerPed), 5.0, 0, 70)
                
                if vehicle ~= 0 then
                    -- Check if the trunk is open
                    if GetVehicleDoorAngleRatio(vehicle, 5) > 0 then
                        -- Get the trunk bone index
                        local trunkBoneIndex = GetEntityBoneIndexByName(vehicle, "bodyshell")

                        -- Get the network ID of the vehicle to pass to the server
                        local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)

                        -- Trigger the server event to handle the attachment
                        TriggerServerEvent('carry:server:attachToTrunk', GetPlayerServerId(PlayerId()), carriedPlayer, vehicleNetId, trunkBoneIndex)

                        -- Reset carrying state on the client
                        carrying = false
                    else
                        -- Optionally, notify the player that the trunk is closed
                        print("Trunk is closed. Open it before placing the body.")
                    end
                end
            end
        end
    end
end)



-- Listen for the server's response with the carry status
RegisterNetEvent('carry:client:sendCarryStatus')
AddEventHandler('carry:client:sendCarryStatus', function(isCarrying, carriedPlayerId)
    if isCarrying then
        local message = "You are carrying player ID: " .. tostring(carriedPlayerId)
        TriggerEvent('chat:addMessage', { args = {"DEBUG", message} })
    else
        local message = "You are not carrying anyone."
        TriggerEvent('chat:addMessage', { args = {"DEBUG", message} })
    end
end)

RegisterNetEvent('carry:client:attachToTrunk')
AddEventHandler('carry:client:attachToTrunk', function(carrierPlayerId, targetPlayerId, vehicleNetId, trunkBoneIndex)
    local carrierPed = GetPlayerPed(GetPlayerFromServerId(carrierPlayerId))
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetPlayerId))
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)

    -- Detach the carried player from the carrier
    DetachEntity(targetPed, true, true)
    ClearPedTasksImmediately(targetPed)

    -- Attach the carried player to the trunk's bone
    AttachEntityToEntity(targetPed, vehicle, trunkBoneIndex,  0.15, -1.75, 0.96, 0.0, 0.0, 104.0, false, false, false, false, 2, false)

    -- Stop the carrying animation for the carrying player
    ClearPedTasksImmediately(carrierPed)

    print("Carried player has been detached from carrier and attached to the trunk.")
end)



Citizen.CreateThread(function()
    local trunkDestroyed = false  -- Flag to track if the trunk has been destroyed

    while true do
        Citizen.Wait(100)  -- Check every 100 milliseconds; adjust this value as needed

        -- Get the vehicle the player is currently driving
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)

        -- Check if the player is in a vehicle
        if vehicle ~= 0 then
            local trunkDoorIndex = 5  -- Trunk/boot door index

            -- Check if the trunk is destroyed
            if IsVehicleDoorDamaged(vehicle, trunkDoorIndex) then
                if not trunkDestroyed then
                    -- Trunk is destroyed and this is the first time detecting it
                    print("The trunk/boot of the vehicle you are driving is destroyed.")
                    trunkDestroyed = true  -- Set the flag to true
                    -- Additional logic can be added here (e.g., notify server, detach entities)
                end
            else
                -- Reset the flag if the trunk is repaired or the player changes vehicles
                trunkDestroyed = false
            end
        else
            -- Reset the flag if the player is not in a vehicle
            trunkDestroyed = false
        end
    end
end)


-- USE THIS WHEN YOU WANT TO ADD NEW GROUND HASH TYPES TO THE CONFIG KEEP CONFIG AND THIS UP TO DATE WITH EACH OTHER AS THAT WILL HELP YOU KNOW IF YOU HAVE THAT ALREADY IN THE CONFIG OR NOT 


-- -- Control variable to determine if checks should be performed
-- local shouldCheck = false

-- -- Predefined mapping of hash values to readable surface types
-- local groundHashes = {
--     [-1885547121] = "Dirt",
--     [282940568] = "Road",
--     [510490462] = "Sand",
--     [951832588] = "Sand 2",
--     [2128369009] = "Grass and Dirt Combined",
--     [-840216541] = "Rock Surface",
--     [-1286696947] = "Grass and Dirt Combined 2",
--     [1333033863] = "Grass",
--     [1187676648] = "Concrete",
--     [1144315879] = "Grass 2",
--     [-1942898710] = "Gravel, Dirt, and Cobblestone",
--     [560985072] = "Sand Grass",
--     [-1775485061] = "Cement",
--     [581794674] = "Grass 3",
--     [1993976879] = "Cement 2",
--     [-1084640111] = "Cement 3",
--     [-700658213] = "Dirt with Grass",
--     [0] = "Air",
--     [-124769592] = "Dirt with Grass 4",
--     [-461750719] = "Dirt with Grass 5",
--     [-1595148316] = "Concrete 4", 
--     [1288448767] = "Water",
--     [765206029] = "Marble Tiles",
--     [-1186320715] = "Pool Water",
--     [1639053622] = "Concrete 3",  
-- }

-- function GetGroundHash(entity)
--     local coords = GetEntityCoords(entity)
--     local num = StartShapeTestCapsule(coords.x, coords.y, coords.z + 4, coords.x, coords.y, coords.z - 2.0, 1, 1, entity, 7)
--     local _, _, _, _, groundHash = GetShapeTestResultEx(num)
--     return groundHash
-- end

-- function TranslateGroundHash(hash)
--     return groundHashes[hash] or "Unknown Surface"
-- end

-- -- Conditionally run the loop only if shouldCheck is true
-- if shouldCheck then
--     Citizen.CreateThread(function()
--         while true do
--             local entity = PlayerPedId() -- Use PlayerPedId as the default entity, which represents the player character
--             local groundHash = GetGroundHash(entity)
--             local surfaceType = TranslateGroundHash(groundHash)
--             print("Ground Surface Type: " .. surfaceType .. " (Hash: " .. groundHash .. ")")
--             Citizen.Wait(5000) -- Wait for 5 seconds
--         end
--     end)
-- end
