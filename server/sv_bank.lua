local ESX = nil
TriggerEvent(Config.Param.ESX..'esx:getSharedObject', function(obj) ESX = obj end)




local ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

playerCardNumber          = ""
playerCardName            = ""

function getNumberCardSource(sourceIdentifier)
    MySQL.Async.fetchAll('SELECT * FROM bank_account WHERE identifier = @identifier', { 
        ['@identifier'] = sourceIdentifier,
    }, function(result)
        for _,v in pairs(result) do
            playerCardNumber = v.cardnumber
            playerCardName   = v.cardname
        end
    end)
end

RegisterServerEvent('esx_bank:addCreditCard')
AddEventHandler('esx_bank:addCreditCard', function(accountName)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local pName = GetPlayerName(_src)
    local cardNumber = "5413 "..math.random(1000,8000).." "..math.random(1000,8000).." "..math.random(1000,8000)
    MySQL.Async.execute('INSERT INTO bank_account (identifier,cardname,cardnumber,creationdate) VALUES(@identifier,@cardname,@cardnumber,@creationdate)', {
        ['identifier'] = xPlayer.identifier,
        ['cardname']   = accountName,
        ['cardnumber'] = cardNumber,
        ['creationdate'] = os.date("%d/%m/%Y | %X"),
    });
    xPlayer.addInventoryItem('carte', 1)
    TriggerClientEvent('esx:showAdvancedNotification', _src, 'Banque', 'Création de Compte', "Votre compte a été créé avec succès. ~s~Une carte bancaire vous a été donné, conservez-là.", 'CHAR_BANK_FLEECA', 9)
    TriggerClientEvent('esx:showAdvancedNotification', _src, 'Banque', 'Création de Compte', "Nom de compte : ~b~"..accountName.."\n~s~Numéro de carte : ~b~"..cardNumber, 'CHAR_BANK_FLEECA', 9)
    Wait(5000)
    
end)

ESX.RegisterServerCallback('esx_bank:checkInformations', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    getNumberCardSource(xPlayer.identifier)
    Wait(10)
    MySQL.Async.fetchAll('SELECT * FROM bank_account WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier,
    }, function(result)
        local data = {
            cardName = result[1]['cardname']
        }
        cb(data)
    end)
end)

ESX.RegisterServerCallback('esx_bank:checkTransactionsHistory', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    getNumberCardSource(xPlayer.identifier)
    Wait(10)
    MySQL.Async.fetchAll('SELECT * FROM bank_transactions WHERE cardnumber = @cardnumber', {
        ['cardnumber'] = playerCardNumber,
    }, function(result)
        cb(result)
    end)
end)

RegisterServerEvent('esx_bank:putMoney')
AddEventHandler('esx_bank:putMoney', function(quantity)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local pMoney  = xPlayer.getAccount('money').money
    local pName = GetPlayerName(_src)
    if pMoney >= quantity then
        xPlayer.removeAccountMoney('money', quantity)
        xPlayer.addAccountMoney('bank', quantity)
        TriggerClientEvent('esx:showAdvancedNotification', _src, 'Banque', 'Dépôt', "Vous venez de déposer ~g~"..quantity.."$ ~s~dans votre banque.", 'CHAR_BANK_FLEECA', 9)
        getNumberCardSource(xPlayer.identifier)
        Wait(10)
        MySQL.Async.execute('INSERT INTO bank_transactions (cardnumber,cardname,transactiontype,quantity,transactiondate,ingame) VALUES(@cardnumber,@cardname,@transactiontype,@quantity,@transactiondate,@ingame)', {
            ['cardnumber'] = playerCardNumber,
            ['cardname'] = playerCardName,
            ['transactiontype'] = "Dépôt",
            ['quantity'] = "+ "..quantity.." $",
            ['transactiondate'] = os.date("%d/%m/%Y | %X"),
            ['ingame'] = os.date("%d/%m/%Y | %X").." : ~g~+ "..quantity.."$"
        });

    else
        TriggerClientEvent('esx:showAdvancedNotification', _src, 'Banque', 'Dépôt', "~r~Action impossible, vous n'avez pas ~g~"..quantity.."$~r~ sur vous !", 'CHAR_BANK_FLEECA', 9)
    end
end)

RegisterServerEvent('esx_bank:takeMoney')
AddEventHandler('esx_bank:takeMoney', function(quantity)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local pName = GetPlayerName(_src)
    local pMoney  = xPlayer.getAccount('bank').money
    if pMoney >= quantity then
        xPlayer.removeAccountMoney('bank', quantity)
        xPlayer.addAccountMoney('money', quantity)
        TriggerClientEvent('esx:showAdvancedNotification', _src, 'Banque', 'Retrait', "Vous venez de retirer ~g~"..quantity.."$ ~s~de votre banque.", 'CHAR_BANK_FLEECA', 9)
        getNumberCardSource(xPlayer.identifier)
        Wait(10)
        MySQL.Async.execute('INSERT INTO bank_transactions (cardnumber,cardname,transactiontype,quantity,transactiondate,ingame) VALUES(@cardnumber,@cardname,@transactiontype,@quantity,@transactiondate,@ingame)', {
            ['cardnumber'] = playerCardNumber,
            ['cardname'] = playerCardName,
            ['transactiontype'] = "Retrait",
            ['quantity'] = "- "..quantity.." $",
            ['transactiondate'] = os.date("%d/%m/%Y | %X"),
            ['ingame'] = os.date("%d/%m/%Y | %X").." : ~r~- "..quantity.."$"
        });
    
    else
        TriggerClientEvent('esx:showAdvancedNotification', _src, 'Banque', 'Retrait', "~r~Action impossible, vous n'avez pas ~g~"..quantity.."$~r~ dans votre banque !", 'CHAR_BANK_FLEECA', 9)
    end
end)

RegisterServerEvent('esx_bank:destroyCard')
AddEventHandler('esx_bank:destroyCard', function()
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local pName = GetPlayerName(_src)
    getNumberCardSource(xPlayer.identifier)
    TriggerClientEvent('esx:showAdvancedNotification', _src, 'Banque', 'Suppression de Compte', "Votre compte et votre carte ont été supprimés avec succès.", 'CHAR_BANK_FLEECA', 1)
    Wait(100)
    MySQL.Async.execute('DELETE FROM bank_account WHERE identifier = @identifier', {
        ['identifier'] = xPlayer.identifier
    })
    MySQL.Async.execute('DELETE FROM bank_transactions WHERE cardnumber = @cardnumber', {
        ['cardnumber'] = playerCardNumber
    })
    xPlayer.removeInventoryItem('carte', 1)
    
end)


RegisterServerEvent('esx_bank:transfer')
AddEventHandler('esx_bank:transfer', function(to, amountt)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local zPlayer = ESX.GetPlayerFromId(to)
	local balance = 0

	if(zPlayer == nil or zPlayer == -1) then
		TriggerClientEvent('esx:showAdvancedNotification', _source, "Problème", 'Banque', "Ce destinataire n'existe pas.", 'CHAR_BANK', 10)
	else
		balance = xPlayer.getAccount('bank').money
		zbalance = zPlayer.getAccount('bank').money
		
		if tonumber(_source) == tonumber(to) then
			TriggerClientEvent('esx:showAdvancedNotification', _source, "Problème", 'Banque', "Vous ne pouvez pas transférer d'argent à vous-même.", 'CHAR_BANK', 10)
		else
			if balance <= 0 or balance < tonumber(amountt) or tonumber(amountt) <= 0 then
				TriggerClientEvent('esx:showAdvancedNotification', _source, 'Banque', "Problème", "Vous n'avez pas assez d'argent en banque.", 'CHAR_BANK', 10)
			else
				xPlayer.removeAccountMoney('bank', tonumber(amountt))
				zPlayer.addAccountMoney('bank', tonumber(amountt))
                    TriggerClientEvent('esx:showAdvancedNotification', _source, "Succès", 'Banque', "Transfert réussi vous avez envoyé "..tonumber(amountt).." $ à "..zPlayer.getName(), 'CHAR_BANK', 10)
                    TriggerClientEvent('esx:showAdvancedNotification', to, "Banque", 'Banque', "Vous avez recu "..tonumber(amountt).." $ de la part de "..xPlayer.getName(), 'CHAR_BANK', 10)
			end
		end
	end
end)


RegisterServerEvent("refresh:solde")
AddEventHandler("refresh:solde", function(action, amount)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local playerMoney = xPlayer.getAccount('money').money
    TriggerClientEvent("solderefresh", source, playerMoney)
end)

RegisterServerEvent("refresh:soldebank")
AddEventHandler("refresh:soldebank", function(action, amount)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local playerMoney = xPlayer.getAccount('bank').money
    TriggerClientEvent("soldebank", source, playerMoney)
end)

RegisterServerEvent("refresh:argentsale")
AddEventHandler("refresh:argentsale", function(action, amount)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local playerMoney = xPlayer.getAccount('black_money').money
    TriggerClientEvent("soldesale", source, playerMoney)
end)

ESX.RegisterServerCallback('checkPlayerHasCreditCard', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local creditCard = xPlayer.getInventoryItem('carte').count
    local hasCreditCard = false
    if creditCard == 1 then
        hasCreditCard = true
    else
        hasCreditCard = false
    end
    cb(hasCreditCard)
end)

ESX.RegisterServerCallback('checkAllCreditCard', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local creditCard = xPlayer.getInventoryItem('carte').count
    local hasCreditCard = false
    if creditCard > 1 then
        hasCreditCard = false
    else
        hasCreditCard = true
    end 
    cb(hasCreditCard)
end)