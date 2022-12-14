local function ActivatePedTarget(ped, k)
    if Config.FrameWork == "QB" or "qb" then
        exports['qb-target']:AddTargetEntity(ped, {
            options = {
                {
                    type = "client",
                    event = "777-talktolamar:client:NPC",
                    icon = "fas fa-comments",
                    label = "Speak with "..Config.Peds[k].PedName,
                    entity = ped,
                    ped = k

                },
                { 
                    type = "client",
                    event = "qb-menu:client:lamarweedMenu",
                    icon = "fa-solid fa-cannabis",
                    label = "Work Options",
                    canInteract = function()
                        return not Hired
                    end,
                },
            },
            distance = 3.0
        })
    end
end

RegisterCommand('dontworryaboutthis', function()
    exports['qb-menu']:openMenu({
        {
            header = 'Lamars Work',
            icon = 'fa-solid fa-cannabis',
            isMenuHeader = true, -- Set to true to make a nonclickable title
        },
        {
            header = 'Start Work',
            txt = 'Take the keys, watch out for feds!',
            icon = 'fa-solid fa-cannabis',
            params = {
                event = '777-doobiedelivery:client:startJob',
                args = {
		    message = 'Take the keys, watch out for feds!'
                }
            }
        },  
        {
            header = 'Collect Paycheck',
            txt = 'Good work bro, take this cash and get out of here!',
            icon = 'fa-solid fa-cannabis',
            params = {
                event = '777-doobiedelivery:client:finishWork',
                args = {
                    number = 2,
                }
            }
        },
    })
end)

RegisterNetEvent('qb-menu:client:lamarweedMenu', function()
    ExecuteCommand('dontworryaboutthis')
end)


function LoadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

Citizen.CreateThread(function()
    while true do
        for k, v in pairs(Config.Peds) do
            RequestModel(v.ped)
            while not HasModelLoaded(v.ped) do
                Wait(20)
            end
            local spawned = v.spawned
            if not spawned then
                local ped = PlayerPedId()
                local pedCoords = GetEntityCoords(ped)
                local dist = #(pedCoords - v.coords)
        
                if dist <= 200 then
                    TriggerEvent("777-talktolamar:client:SpawnPed", k)
                    break
                end
            end
        end
        Wait(2000)
    end
end)

RegisterNetEvent('777-talktolamar:client:SpawnPed', function(SpawnedPed)
    if Config.DebugPrints then
        print("Spawning Ped #"..SpawnedPed.." at "..Config.Peds[SpawnedPed].coords.." ~ Model : "..Config.Peds[SpawnedPed].ped.." | Name : "..Config.Peds[SpawnedPed].PedName)
    end
    local npc = CreatePed(0, Config.Peds[SpawnedPed].ped, Config.Peds[SpawnedPed].coords['x'], Config.Peds[SpawnedPed].coords['y'], Config.Peds[SpawnedPed].coords['z']-1, Config.Peds[SpawnedPed].heading, false, 1)
    SetEntityAsMissionEntity(npc, true, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    LoadAnimDict(Config.Peds[SpawnedPed].LoopedAnim.Dict)
    TaskPlayAnim(npc, Config.Peds[SpawnedPed].LoopedAnim.Dict, Config.Peds[SpawnedPed].LoopedAnim.Anim,  8.0, 8.0, -1, 1, 0, 0, 0, 0)
    ActivatePedTarget(npc, SpawnedPed)
    Config.Peds[SpawnedPed].spawned = true
end)

RegisterNetEvent('777-talktolamar:client:NPC')
AddEventHandler('777-talktolamar:client:NPC', function(data, hook, pline, oline)
    local myMenu
    local Name
    local msg
    local ped
    local playerLine
    local oldLine
    local line = 1
    if type(data) == "table" then
        Name = Config.Peds[data.ped].PedName
        msg = Config.Peds[data.ped].Lines[line].npc
        ped = data.ped
        playerLine = data.playerLine
        oldLine = data.oldLine
        if data.hookto then
            line = data.hookto
        end
    else
        Name = Config.Peds[data].PedName
        ped = data
        playerLine = pline
        oldLine = oline
        if hook then
            if hook ~= 0 then
                line = hook
                msg = Config.Peds[data].Lines[hook].npc
            else
                line = 0
            end
        end
    end
    if line ~= 0 then
        if playerLine then
            if Config.DebugPrints then
                print("Just Pressed : Ped #"..ped..", Line "..oldLine..", Player Line "..playerLine.." | NPC is talking now.")
            end
            if Config.Peds[ped].Lines[oldLine].player[playerLine].Triggers then
                TalkToLamarEvents(Config.Peds[ped].Lines[oldLine].player[playerLine].Triggers)
            end
        else
            if Config.DebugPrints then
                print("Started Conversation with : Ped #"..ped.." | NPC is talking now.")
            end
        end
        if Config.Menu == "qb" then
            Name = Config.Peds[ped].PedName
            msg = Config.Peds[ped].Lines[line].npc
            myMenu = {
                {
                    header = Name,
                    isMenuHeader = true
                },
            }
            myMenu[#myMenu+1] = {
                    header = msg,
                    params = {
                    event = "777-talktolamar:client:Talk",
                    args = {
                        ped = ped,
                        hookto = line
                    }
                }
            }
            exports['qb-menu']:openMenu(myMenu)
        elseif Config.Menu == "nh" then
            myMenu = {
                {
                    header = Name,
                    disabled = true
                },
            }
            if hook then
                line = hook
            end
            myMenu[#myMenu+1] = {
                header = msg,
                event = "777-talktolamar:client:Talk",
                args = {
                    ped,
                    line
                }
            }
            TriggerEvent('nh-context:createMenu', myMenu)
        end
    else
        if playerLine then
            if Config.DebugPrints then
                print("Just Pressed : Ped #"..ped..", Line "..oldLine..", Player Line "..playerLine.." | Conversation is over.")
            end
            if Config.Peds[ped].Lines[oldLine].player[playerLine].Triggers then
                local event = Config.Peds[ped].Lines[oldLine].player[playerLine].Triggers
                TalkToLamarEvents(event)
            end
        end
    end
end)

RegisterNetEvent('777-talktolamar:client:Talk')
AddEventHandler('777-talktolamar:client:Talk', function(data, hook)
    local myMenu
    local line = 1
    local msg
    local ped
    if Config.Menu == "qb" then
        ped = data.ped
        if data.hookto ~= nil then
            line = data.hookto
        end
        if Config.DebugPrints then
            print("Just pressed : Ped #"..ped..", Line "..line.." | Player is talking now")
        end
        if Config.Peds[ped].Lines[line].npcEventTrigger then
            TalkToLamarEvents(Config.Peds[ped].Lines[line].npcEventTrigger)
        end
        myMenu = {
            {
                header = "You",
                isMenuHeader = true
            },
        }
        for k, v in pairs (Config.Peds[ped].Lines[line].player) do
            msg = v.text
            myMenu[#myMenu+1] = {
                header = msg,
                params = {
                    event = "777-talktolamar:client:NPC",
                    args = {
                        ped = data.ped,
                        hookto = v.LineHook,
                        playerLine = k,
                        oldLine = line
                    }
                }
            }
        end
        exports['qb-menu']:openMenu(myMenu)
    elseif Config.Menu == "nh" then
        line = hook
        if data ~= nil then
            ped = data
        end
        if Config.DebugPrints then
            print("Just pressed : Ped #"..ped..", Line "..line.." | Player is talking now")
        end
        if Config.Peds[ped].Lines[line].npcEventTrigger then
            TalkToLamarEvents(Config.Peds[ped].Lines[line].npcEventTrigger)
        end
        myMenu = {
            {
                header = "You",
                disabled = true
            },
        }
        for k, v in pairs (Config.Peds[ped].Lines[line].player) do
            msg = v.text
            myMenu[#myMenu+1] = {
                header = msg,
                event = "777-talktolamar:client:NPC",
                args = {
                    ped,
                    v.LineHook,
                    k,
                    line
                }
            }
        end
        TriggerEvent('nh-context:createMenu', myMenu)
    end
end)