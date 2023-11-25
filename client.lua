--------------------------------
--- RP Revive, Made by FAXES ---
--------------------------------

--- Config ---
local Config = {
    reviveTimer = 10,  -- Time to wait before allowing revive (in seconds)
    respawnTimer = 5,  -- Time to wait before allowing respawn (in seconds)
    reviveColor = "~y~",
    respawnColor = "~r~",
    chatColor = "~b~",
    spawnPoints = {
        {x = 1828.44, y = 3692.32, z = 34.22, heading = 37.12} -- Back of Sandy Shores Hospital
    }
}

--- Variables ---
local timerCount1, timerCount2, isDead, cHavePerms = Config.reviveTimer, Config.respawnTimer, false, false

--- Event Handlers ---
AddEventHandler('playerSpawned', function()
    TriggerServerEvent("RPRevive:CheckPermission", source)
end)

AddEventHandler("RPRevive:CheckPermission:Return", function(havePerms)
    cHavePerms = havePerms
end)

AddEventHandler('onClientMapStart', function()
    Citizen.Trace("RPRevive: Disabling the autospawn.")
    exports.spawnmanager:spawnPlayer()
    Citizen.Wait(2500)
    exports.spawnmanager:setAutoSpawn(false)
    Citizen.Trace("RPRevive: Autospawn is disabled.")
end)

--- Functions ---
local function respawnPed(ped, coords)
    resetTimers()
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false, true)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, coords.heading, true, false) 
    SetPlayerInvincible(ped, false) 
    TriggerEvent('playerSpawned', coords.x, coords.y, coords.z, coords.heading)
    ClearPedBloodDamage(ped)
end

local function revivePed(ped)
    resetTimers()
    local playerPos = GetEntityCoords(ped, true)
    NetworkResurrectLocalPlayer(playerPos, true, true, false)
    SetPlayerInvincible(ped, false)
    ClearPedBloodDamage(ped)
end

local function ShowInfoRevive(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentSubstringPlayerName(text)
    DrawNotification(true, true)
end

local function resetTimers()
    isDead = false
    timerCount1 = Config.reviveTimer
    timerCount2 = Config.respawnTimer
end

--- Threads ---
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = GetPlayerPed(-1)
        if IsEntityDead(ped) and not isDead then
            isDead = true
            SetPlayerInvincible(ped, true)
            SetEntityHealth(ped, 1)
            ShowInfoRevive(Config.chatColor .. 'You are dead. Use ' .. Config.reviveColor .. 'E ' .. Config.chatColor ..'to revive or ' .. Config.respawnColor .. 'R ' .. Config.chatColor .. 'to respawn.')
        end

        if isDead then
            if IsControlJustReleased(0, 38) and GetLastInputMethod(0) then -- E key
                if timerCount1 == 0 or cHavePerms then
                    revivePed(ped)
                else
                    TriggerEvent('chat:addMessage', {args = {'^1^*Wait ' .. timerCount1 .. ' more seconds before reviving'}})
                end 
            elseif IsControlJustReleased(0, 45) and GetLastInputMethod(0) then -- R key
                if timerCount2 == 0 or cHavePerms then
                    local coords = Config.spawnPoints[math.random(#Config.spawnPoints)]
                    respawnPed(ped, coords)
                else
                    TriggerEvent('chat:addMessage', {args = {'^1^*Wait ' .. timerCount2 .. ' more seconds before respawning'}})
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if isDead then
            if timerCount1 > 0 then
                timerCount1 = timerCount1 - 1
            end

            if timerCount2 > 0 then
                timerCount2 = timerCount2 - 1
            end
        end
    end
end)
