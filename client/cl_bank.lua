local ESX = nil
TriggerEvent(Config.Param.ESX .. 'esx:getSharedObject', function(obj)
    ESX = obj
end)

argentsolde = 0

function verifmoney()
    TriggerServerEvent("refresh:solde", action)
end

RegisterNetEvent("solderefresh")
AddEventHandler("solderefresh", function(money, cash)
    argentsolde = tonumber(money)
end)

argentbank = 0

function verifbank()
    TriggerServerEvent("refresh:soldebank", action)
end

RegisterNetEvent("soldebank")
AddEventHandler("soldebank", function(money, cash)
    argentbank = tonumber(money)
end)

argentsale = 0

function verifsale()
    TriggerServerEvent("refresh:argentsale", action)
end

RegisterNetEvent("soldesale")
AddEventHandler("soldesale", function(money, cash)
    argentsale = tonumber(money)
end)

function notify(title, msg)
    return ESX.ShowAdvancedNotification('Banque', title, msg, 'CHAR_BANK_FLEECA', 9);
end

function verifsolde()
    verifbank()
    verifsale()
    verifmoney()
end

Citizen.CreateThread(function()
    for k, v in pairs(Config.Bank.Position) do
        local blip = AddBlipForCoord(v)
        SetBlipSprite(blip, 207)
        SetBlipScale(blip, 0.7)
        SetBlipColour(blip, 69)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('Banque')
        EndTextCommandSetBlipName(blip)
    end
end)

Citizen.CreateThread(function()
    for k, v in pairs(Config.Bank.Position_Central) do
        local blip = AddBlipForCoord(v)
        SetBlipSprite(blip, 207)
        SetBlipScale(blip, 0.7)
        SetBlipColour(blip, 69)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('Banque - Central')
        EndTextCommandSetBlipName(blip)
    end
end)

local historyTable = {}
local transactionClick = false

function OpenBankCentral()

    local main_bank = RageUI.CreateMenu("Banque", "Interaction")
    local bank_info = RageUI.CreateSubMenu(main_bank, "Informations", "Interaction")

    RageUI.Visible(main_bank, not RageUI.Visible(main_bank))
    while main_bank do
        Wait(0)
        RageUI.IsVisible(main_bank, true, false, true, function()

            if Config.Param.hasCreditCard then
                RageUI.ButtonWithStyle("Effectuer un dépôt", "Effectuez un dêpot d'argent sur votre banque.", { RightLabel = "→→" }, true, function(_, _, s)
                    if s then
                        local quantityInput = KeyboardInput("Quantité d'argent à déposer (ex : 1000) :", "", 50)
                        if quantityInput ~= nil then
                            if tonumber(quantityInput) then
                                TriggerServerEvent('esx_bank:putMoney', tonumber(quantityInput))
                            else
                                return notify("Dépôt", "~r~Merci de bien renseigner une somme à déposer dans votre banque !")
                            end
                        end
                    end
                end)
                RageUI.ButtonWithStyle("Effectuer un retrait", "Effectuez un retrait d'argent de votre banque.", { RightLabel = "→→" }, true, function(_, _, s)
                    if s then
                        local quantityTake = KeyboardInput("Quantité d'argent à retirer (ex : 2000) :", "", 50)
                        if quantityTake ~= nil then
                            if tonumber(quantityTake) then
                                TriggerServerEvent('esx_bank:takeMoney', tonumber(quantityTake))
                            else
                                return notify("Dépôt", "~r~Merci de bien renseigner une somme à retirer de votre banque !")
                            end
                        end
                    end
                end)

                RageUI.ButtonWithStyle("Effectuer un transfère", "Effectuez un transfére d'argent de votre banque.", { RightLabel = "→→" }, true, function(_, _, s)
                    if s then
                        local to = KeyboardInput("Quelle est l'ID de la personne", "", 5)
                        local amountt = KeyboardInput("Combien d'argent vous voulez lui donner", "", 30)
                        TriggerServerEvent('gBank:transfer', to, amountt)
                    end
                end)

                RageUI.ButtonWithStyle("Ma Banque", "Accèdez aux actions sur votre banque, et tout ce qu'elle contient.", { RightLabel = "→→" }, true, function(_, _, s)
                    if s then
                        ESX.TriggerServerCallback('esx_bank:checkInformations', function(data)
                            Config.Param.playerName = data.cardName
                        end)

                    end
                end, bank_info)


            else
                RageUI.Separator("BIENVENUE")
                RageUI.Separator("~r~Aucune carte détectée")
                RageUI.ButtonWithStyle("Créer ma carte", "Vous n'avez pas de carte bancaire ? Pas de problème, en un clic elle peut être crée.", { RightLabel = "→→" }, not createCard, function(_, _, s)
                    if s then
                        accountName = KeyboardInput("Entrez votre nom prénom pour votre compte :", "", 30)
                        if accountName ~= nil and accountName ~= "" then
                            if tostring(accountName) then
                                createCard = true
                                notify("Compte", "Création de compte pour : ~b~" .. accountName)
                            else
                                return notify("Compte", "~r~Le nom de compte renseigné est invalide !")
                            end
                        end
                    end
                end)
                if createCard then
                    RageUI.PercentagePanel(Config.Param.cardLoad, "Création du compte en cours (~b~" .. math.floor(Config.Param.cardLoad * 100) .. "%~s~)", "", "", function(_, a_, percent)
                        if Config.Param.cardLoad < 1.0 then
                            Config.Param.cardLoad = Config.Param.cardLoad + 0.0006
                        else
                            Config.Param.cardLoad = 0
                        end
                    end)
                end
                if Config.Param.cardLoad >= 1.0 then
                    TriggerServerEvent('esx_bank:addCreditCard', accountName)
                    Config.Param.cardLoad = 0
                    Config.Param.hasCreditCard = true
                end
            end
        end, function()
        end)

        RageUI.IsVisible(bank_info, true, false, true, function()

            RageUI.ButtonWithStyle("~r~Détruire la carte", "Actualiser les transactions liés à votre compte bancaire.", { RightLabel = "→→" }, true, function(_, _, s)
                if s then
                    isMenuOpen = false
                    ESX.ShowNotification("Suppression en cours...")
                    Wait(3000)
                    FreezeEntityPosition(PlayerPedId(), false)
                    TriggerServerEvent('esx_bank:destroyCard')
                    RageUI.CloseAll()
                end
            end)
            RageUI.Separator("↓ ~y~Historique des transactions~s~ ↓")
            RageUI.ButtonWithStyle("Voir mes transactions", "Actualiser les transactions liés à votre compte bancaire.", { RightLabel = "→→" }, true, function(_, _, s)
                if s then
                    transactionClick = true
                    ESX.TriggerServerCallback('esx_bank:checkTransactionsHistory', function(history)
                        historyTable = history
                    end)
                end
            end)
            if #historyTable < 1 then
                RageUI.Separator("")
                RageUI.Separator("~r~Aucune transaction trouvée")
                RageUI.Separator("")
            end
            for i = 1, #historyTable, 1 do
                RageUI.ButtonWithStyle(historyTable[i].ingame, "Vous avez la date de transaction, et aussi si c'est un retrait ou un dépot.", {}, true, function(_, _, s)
                end)
            end


        end, function()
        end)
        if not RageUI.Visible(main_bank) and not RageUI.Visible(bank_info) then
            main_bank = RMenu:DeleteType("main_bank", true)
        end
    end
end

function OpenBank()

    local main_bank = RageUI.CreateMenu("Banque", "Interaction")
    local bank_info = RageUI.CreateSubMenu(main_bank, "Informations", "Interaction")

    RageUI.Visible(main_bank, not RageUI.Visible(main_bank))
    while main_bank do
        Wait(0)
        RageUI.IsVisible(main_bank, true, false, true, function()

            if Config.Param.hasCreditCard then
                RageUI.ButtonWithStyle("Effectuer un dépôt", "Effectuez un dêpot d'argent sur votre banque.", { RightLabel = "→→" }, true, function(_, _, s)
                    if s then
                        local quantityInput = KeyboardInput("Quantité d'argent à déposer (ex : 1000) :", "", 50)
                        if quantityInput ~= nil then
                            if tonumber(quantityInput) then
                                TriggerServerEvent('esx_bank:putMoney', tonumber(quantityInput))
                            else
                                return notify("Dépôt", "~r~Merci de bien renseigner une somme à déposer dans votre banque !")
                            end
                        end
                    end
                end)
                RageUI.ButtonWithStyle("Effectuer un retrait", "Effectuez un retrait d'argent de votre banque.", { RightLabel = "→→" }, true, function(_, _, s)
                    if s then
                        local quantityTake = KeyboardInput("Quantité d'argent à retirer (ex : 2000) :", "", 50)
                        if quantityTake ~= nil then
                            if tonumber(quantityTake) then
                                TriggerServerEvent('esx_bank:takeMoney', tonumber(quantityTake))
                            else
                                return notify("Dépôt", "~r~Merci de bien renseigner une somme à retirer de votre banque !")
                            end
                        end
                    end
                end)

                RageUI.ButtonWithStyle("Effectuer un transfère", "Effectuez un transfére d'argent de votre banque.", { RightLabel = "→→" }, true, function(_, _, s)
                    if s then
                        local to = KeyboardInput("Quelle est l'ID de la personne", "", 5)
                        local amountt = KeyboardInput("Combien d'argent vous voulez lui donner", "", 30)
                        TriggerServerEvent('gBank:transfer', to, amountt)
                    end
                end)

                RageUI.ButtonWithStyle("Ma Banque", "Accèdez aux actions sur votre banque, et tout ce qu'elle contient.", { RightLabel = "→→" }, true, function(_, _, s)
                    if s then
                        ESX.TriggerServerCallback('esx_bank:checkInformations', function(data)
                            Config.Param.playerName = data.cardName
                        end)
                        ESX.TriggerServerCallback('esx_bank:checkTransactionsHistory', function(history)
                            historyTable = history
                        end)

                    end
                end, bank_info)


            else
                RageUI.Separator("BIENVENUE")
                RageUI.line()
                RageUI.Separator("~r~Aucune carte détectée")
                RageUI.Separator("Veuillez vous rendre a la banque central")
                RageUI.Separator("pour obtenir votre carte")
            end
        end, function()
        end)

        RageUI.IsVisible(bank_info, true, false, true, function()

            RageUI.ButtonWithStyle("~r~Détruire la carte", "Actualiser les transactions liés à votre compte bancaire.", { RightLabel = "→→" }, true, function(_, _, s)
                if s then
                    isMenuOpen = false
                    ESX.ShowNotification("Suppression en cours...")
                    Wait(3000)
                    FreezeEntityPosition(PlayerPedId(), false)
                    TriggerServerEvent('esx_bank:destroyCard')
                    RageUI.CloseAll()
                end
            end)
            RageUI.Separator("↓ ~y~Historique des transactions~s~ ↓")
            RageUI.ButtonWithStyle("Voir mes transactions", "Actualiser les transactions liés à votre compte bancaire.", { RightLabel = "→→" }, true, function(_, _, s)
                if s then
                    transactionClick = true

                    ESX.TriggerServerCallback('esx_bank:checkTransactionsHistory', function(history)
                        historyTable = history
                    end)
                end
            end)
            if #historyTable < 1 then
                RageUI.Separator("")
                RageUI.Separator("~r~Aucune transaction trouvée")
                RageUI.Separator("")
            end
            for i = 1, #historyTable, 1 do
                RageUI.ButtonWithStyle(historyTable[i].ingame, "Vous avez la date de transaction, et aussi si c'est un retrait ou un dépot.", {}, true, function(_, _, s)
                end)
            end


        end, function()
        end)
        if not RageUI.Visible(main_bank) and not RageUI.Visible(bank_info) then
            main_bank = RMenu:DeleteType("main_bank", true)
        end
    end
end

Citizen.CreateThread(function()
    while true do
        local interval = 1000
        for k, v in pairs(Config.Bank.Position_Central) do
            local playerPos = GetEntityCoords(PlayerPedId())
            local distance = #(playerPos - v)
            if distance <= 9 then
                interval = 0
                DrawMarker(22, v.x, v.y, v.z - 1.0 + 0.98, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.45, 0.45, 0.45, 255, 0, 0, 150, 55555, false, true, 2, false, false, false, false)
                if distance <= 1.5 then
                    RageUI.Text({ message = "Appuyez sur ~b~[E]~s~ pour accéder a son compte", time_display = 1 })
                    if IsControlJustPressed(0, 51) then
                        ESX.TriggerServerCallback('checkPlayerHasCreditCard', function(creditCard)
                            Config.Param.hasCreditCard = creditCard
                        end)
                        OpenBankCentral()
                        verifsolde()
                    end
                end
            end
        end
        Wait(interval)
    end
end)

Citizen.CreateThread(function()
    while true do
        local interval = 1000
        for k, v in pairs(Config.Bank.Position) do
            local playerPos = GetEntityCoords(PlayerPedId())
            local distance = #(playerPos - v)
            if distance <= 9 then
                interval = 0
                DrawMarker(22, v.x, v.y, v.z - 1.0 + 0.98, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.45, 0.45, 0.45, 255, 0, 0, 150, 55555, false, true, 2, false, false, false, false)
                if distance <= 1.5 then
                    RageUI.Text({ message = "Appuyez sur ~b~[E]~s~ pour accéder a son compte", time_display = 1 })
                    if IsControlJustPressed(0, 51) then
                        ESX.TriggerServerCallback('checkPlayerHasCreditCard', function(creditCard)
                            Config.Param.hasCreditCard = creditCard
                        end)
                        OpenBank()
                        verifsolde()
                    end
                end
            end
        end
        Wait(interval)
    end
end)

Citizen.CreateThread(function()
    while true do
        local Interaction = 1000
        for index, objects in ipairs(Config.Bank.ATMObjects) do
            local myCoords = GetEntityCoords(PlayerPedId())
            local getClosestObjects = GetClosestObjectOfType(myCoords.x, myCoords.y, myCoords.z, 0.7, GetHashKey(objects), true, true, true)
            if getClosestObjects > 1.5 then
                local interval = 0
                RageUI.Text({ message = "Appuyez sur ~b~[E]~s~ pour accéder a son compte", time_display = 1 })
                if getClosestObjects ~= 0 then
                    if IsControlJustPressed(0, 51) then
                        playAnim('mp_common', 'givetake2_a', 2500)
                        Wait(1000)
                        ESX.TriggerServerCallback('checkPlayerHasCreditCard', function(creditCard)
                        Config.Param.hasCreditCard = creditCard
                        end)
                        OpenBank()
                        verifsolde()
                    end
                end
            end
        end
        Wait(interval)
    end
end)


function playAnim(animDict, animName, duration)
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(0)
    end
    TaskPlayAnim(PlayerPedId(), animDict, animName, 1.0, -1.0, duration, 49, 1, false, false, false)
    RemoveAnimDict(animDict)
end

function KeyboardInput(TextEntry, ExampleText, MaxStringLenght)
    AddTextEntry('FMMC_KEY_TIP1', TextEntry)
    blockinput = true
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLenght)
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Wait(0)
    end

    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Wait(500)
        blockinput = false
        return result
    else
        Wait(500)
        blockinput = false
        return nil
    end
end