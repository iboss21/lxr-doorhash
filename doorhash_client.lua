-- doorhash_client.lua
-- Script per visualizzare e copiare gli hash delle porte in RedM

-- Variabili di configurazione
local showDoorHashes = false
local drawDistance = 3.0  -- Distanza per visualizzare le porte
local copyDistance = 3.0  -- Distanza per copiare le porte

-- Registra il comando per mostrare/nascondere gli hash delle porte
RegisterCommand('doorhash', function()
    showDoorHashes = not showDoorHashes
    
    if showDoorHashes then
        TriggerEvent('chat:addMessage', {
            color = {0, 255, 0},
            args = {'SYSTEM', 'Door hashes visualization enabled'}
        })
    else
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            args = {'SYSTEM', 'Door hashes visualization disabled'}
        })
    end
end, false)

-- Registra il comando per copiare gli hash delle porte vicine negli appunti
RegisterCommand('copydoorhash', function()
    local pcoords = GetEntityCoords(PlayerPedId())
    local Doors = DoorSystemGetActive()
    local nearbyDoors = {}
    
    for i = 1, #Doors do
        local thisDoor = Doors[i]
        local coords = GetEntityCoords(thisDoor[2])
        local dist = #(pcoords - coords)
        
        if dist < copyDistance then
            local modelHash = GetEntityModel(thisDoor[2])
            table.insert(nearbyDoors, {
                hash = thisDoor[1],
                model = modelHash,
                modelName = tostring(modelHash),
                coords = coords
            })
        end
    end
    
    if #nearbyDoors > 0 then
        local doorStrings = {}
        
        for _, door in ipairs(nearbyDoors) do
            local doorString = string.format("[%d] = {%d,%d,\"%s\",%f,%f,%f},", 
                door.hash,
                door.hash,
                door.model,
                door.modelName,
                door.coords.x,
                door.coords.y,
                door.coords.z
            )
            table.insert(doorStrings, doorString)
        end
        
        -- Unisci tutte le stringhe con newline
        local clipboardText = table.concat(doorStrings, "\n")
        
        -- Invia il testo alla funzione di copia negli appunti
        CopyToClipboard(clipboardText)
        
        TriggerEvent('chat:addMessage', {
            color = {0, 255, 0},
            args = {'SYSTEM', 'Copied ' .. #nearbyDoors .. ' door hashes to clipboard'}
        })
    else
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            args = {'SYSTEM', 'No doors found within ' .. copyDistance .. ' meters'}
        })
    end
end, false)

-- Funzione per copiare negli appunti con clipboard universale
function CopyToClipboard(text)
    SendNUIMessage({
        type = "copy",
        text = text,
        source = "doorhash"
    })
end

-- Callback dalla NUI per il risultato della copia
RegisterNUICallback("doorhashResult", function(data, cb)
    if data.success then
        -- Notifica di successo
        print("Successfully copied door hashes to clipboard")
    else
        -- Notifica di errore
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            args = {'SYSTEM', 'Failed to copy door hashes: ' .. (data.error or "unknown error")}
        })
    end
    cb('ok')
end)

-- Thread per visualizzare le informazioni delle porte
Citizen.CreateThread(function()
    while true do
        -- Se la visualizzazione è disattivata, attendi più a lungo per risparmiare risorse
        if not showDoorHashes then
            Citizen.Wait(1000)
        else
            Citizen.Wait(0)
            local pcoords = GetEntityCoords(PlayerPedId())
            local Doors = DoorSystemGetActive()
            
            for i = 1, #Doors do
                local thisDoor = Doors[i]
                local coords = GetEntityCoords(thisDoor[2])
                local heading = GetEntityHeading(thisDoor[2])
                local dist = #(pcoords - coords)
                
                if dist < drawDistance then
                    local modelHash = GetEntityModel(thisDoor[2])
                    
                    -- APPROCCIO SEPARATO - ogni elemento con la sua dimensione e colore
                    -- Visualizza l'hash in alto
                    DrawDoorInfo("Hash: " .. thisDoor[1], coords.x, coords.y, coords.z + 0.15, 0.25, 255, 255, 0, 255)
                    
                    -- Visualizza il modello
                    DrawDoorInfo("Model: " .. modelHash, coords.x, coords.y, coords.z + 0.05, 0.25, 150, 255, 150, 255)
                    
                    -- Visualizza le coordinate formattate
                    local coordsStr = string.format("Coords: %.2f, %.2f, %.2f", coords.x, coords.y, coords.z)
                    DrawDoorInfo(coordsStr, coords.x, coords.y, coords.z - 0.05, 0.25, 150, 150, 255, 255)
                    
                    -- Visualizza l'heading
                    DrawDoorInfo("Heading: " .. string.format("%.1f", heading), coords.x, coords.y, coords.z - 0.15, 0.25, 255, 200, 150, 255)
                end
            end
        end
    end
end)

-- Funzione per disegnare le informazioni della porta con controllo dimensione
function DrawDoorInfo(text, x, y, z, scale, r, g, b, a)
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    
    if onScreen then
        SetTextScale(scale, scale)  -- Usa scala uguale per tutto il testo
        SetTextFontForCurrentCommand(7)
        SetTextColor(r, g, b, a)
        SetTextCentre(1)
        SetTextDropshadow(1, 0, 0, 0, 255)
        
        DisplayText(CreateVarString(10, "LITERAL_STRING", text), _x, _y)
    end
end

-- Funzione per convertire vector3 in stringa formattata
function vector3ToString(vector)
    return string.format("%.2f, %.2f, %.2f", vector.x, vector.y, vector.z)
end

-- Aggiunge suggerimenti per i comandi
TriggerEvent("chat:addSuggestion", "/doorhash", "Toggle door hash visualization")
TriggerEvent("chat:addSuggestion", "/copydoorhash", "Copy the hashes of nearby doors to clipboard")