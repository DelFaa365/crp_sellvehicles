ESX = nil

PlayerData = {}
local IsInShopMenu            = false
local Categories              = {}
local Vehicles                = {}
local LastVehicles            = {}
local CurrentVehicleData      = nil

local vmenu = false 

Citizen.CreateThread(function()
    while ESX == nil do
        Citizen.Wait(10)

        TriggerEvent("esx:getSharedObject", function(response)
            ESX = response
        end)
    end

    if ESX.IsPlayerLoaded() then
		PlayerData = ESX.GetPlayerData()


		Citizen.Wait(500)

		LoadSellPlace()

    end
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
	
	Citizen.Wait(5000)
end)

function initESX()
	while ESX == nil do
		TriggerEvent('esx:getShAhojJsemGayTesiMearedObjAhojJsemGayTesiMeect', function(obj) ESX = obj end)
		Citizen.Wait(1);
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(100);
	end

	PlayerLoaded	= true;
	ESX.PlayerData	= ESX.GetPlayerData();
end


Citizen.CreateThread(function()
	initESX();
end)

RegisterNetEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function(response)
	PlayerData = response
	
	LoadSellPlace()

end)

RegisterNetEvent("crp_sellvehicles:refreshVehicles")
AddEventHandler("crp_sellvehicles:refreshVehicles", function()

end)

function LoadSellPlace()
	Citizen.CreateThread(function()

		local SellPos = Config.SellPosition

		local Blip = AddBlipForCoord(SellPos["x"], SellPos["y"], SellPos["z"])
		SetBlipSprite (Blip, 147)
		SetBlipDisplay(Blip, 4)
		SetBlipScale  (Blip, 1.2)
		SetBlipColour (Blip, 1)
		SetBlipAsShortRange(Blip, true)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString("AUTOBAZAR")
		EndTextCommandSetBlipName(Blip)

		while true do
			local sleepThread = 500

			local ped = PlayerPedId()
			local pedCoords = GetEntityCoords(ped)

			local dstCheck = GetDistanceBetweenCoords(pedCoords, SellPos["x"], SellPos["y"], SellPos["z"], true)

			if dstCheck <= 10.0 then
				sleepThread = 5
				

				if dstCheck <= 4.2 then
					DrawText3D(SellPos["x"], SellPos["y"], SellPos["z"], "Otevřít menu")
					if IsControlJustPressed(0, 38) then
						if IsPedInAnyVehicle(ped, false) and PlayerData.job.name == 'bazar' then
							OpenSellMenu(GetVehiclePedIsUsing(ped))
						else
						    ListAuticekNaProdej()
						end
					end
				end
			end
			Citizen.Wait(sleepThread)
		end
	end)
end

function DrawText3D(x,y,z, text)
	local onScreen, _x, _y = World3dToScreen2d(x, y, z)
	local p = GetGameplayCamCoords()
	RegisterFontFile('out')
	fontId = RegisterFontId('CoreRPFont')
	local font = fontId
	local distance = GetDistanceBetweenCoords(p.x, p.y, p.z, x, y, z, 1)
	local scale = (1 / distance) * 2
	local fov = (1 / GetGameplayCamFov()) * 100
	local scale = scale * fov
	if onScreen then
		  SetTextScale(0.35, 0.35)
		  SetTextFont(font)
		  SetTextProportional(1)
		  SetTextOutline()
          SetTextColour(255, 255, 255, 255 )
		  SetTextDropshadow(10, 100, 100, 100, 255)
		  SetTextEntry("STRING")
		  SetTextCentre(1)
		  AddTextComponentString(text)
		  DrawText(_x,_y)
		  local factor = (string.len(text)) / 370
		  DrawRect(_x,_y+0.012, 0.012+ factor, 0.030, 66, 66, 66, 150)
	  end
end

function OpenSellMenu(veh, price, buyVehicle)
	local elements = {}

		if price ~= nil then
			table.insert(elements, { ["label"] = "Změna ceny - " .. price .. " :-", ["value"] = "price" })
			table.insert(elements, { ["label"] = "Vystavit na prodej", ["value"] = "sell" })
		else
			table.insert(elements, { ["label"] = "Cena - :-", ["value"] = "price" })
		end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'sell_veh',
		{
			title    = "Menu vozidla",
			align    = 'top-right',
			elements = elements
		},
	function(data, menu)
		local action = data.current.value

		if action == "price" then
			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'sell_veh_price',
				{
					title = "Cena"
				},
			function(data2, menu2)

				local vehPrice = tonumber(data2.value)

				menu2.close()
				menu.close()

				OpenSellMenu(veh, vehPrice)
			end, function(data2, menu2)
				menu2.close()
			end)
		elseif action == "sell" then
			local vehProps = ESX.Game.GetVehicleProperties(veh)

			ESX.TriggerServerCallback("crp_sellvehicles:isVehicleValid", function(valid)

				if valid then
					DeleteVehicle(veh)
					ESX.ShowNotification("Vystavil jsi vozidlo - " .. price .. " :-")
					menu.close()
				else
					ESX.ShowNotification("Musis vozidlo vlastnit / uz je vystavene" .. #Config.VehiclePositions .. " na prodej!")
				end
	
			end, vehProps, price)
		end
		
	end, function(data, menu)
		menu.close()
	end)
end

function ListAuticekNaProdej()
	local elements = {}

	ESX.TriggerServerCallback('esx_bazar:Auticka', function(auticka)
		if #auticka == 0 then
			ESX.ShowNotification('Nic na prodej')
		else
			for _,v in pairs(auticka) do
				local ModelVozu = v.vehicle.model
				local JmenoVozu  = GetDisplayNameFromVehicleModel(ModelVozu)			

				table.insert(elements, {label = ('<span style="color:white; margin-left:15px; text-transform: uppercase; ">%s</span> <span style="margin-left:150px; color:green; text-transform: uppercase; align:right; float:right">%s $</span>'):format(JmenoVozu, ESX.Math.GroupDigits(v.price)), value = v})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'dalsi_nabidka', {
			title    = 'Bazar',
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			local VehicleData = data.current.value.vehicle
			local vehProps = data.current.value.vehicle

			local elements = {
				{label = ('Koupit za <span style="color:green; text-transform: uppercase;">%s</span> $'):format(ESX.Math.GroupDigits(data.current.value.price)),			value = 'buy'},
				{label = ('<span style="color:cyan; text-transform: uppercase;">Vidět tuning</span>'),			value = 'tuning'},
			}
			
			
			if PlayerData.job.name == 'bazar' then 
				table.insert(elements, {label = ('<span style="color:red; text-transform: uppercase;">Odebrat ze seznamu</span>'), value = 'vratit'})
			end

			ESX.UI.Menu.Open(
				'default', GetCurrentResourceName(), 'stored_cars',
				{
					title    = 'Nabídka',
					align    = 'top-left',
					elements = elements
				}, function(data2, menu2)
					local VehicleData = data.current.value.vehicle
					action    = data2.current.value

					local price = data.current.value.price
			
					if action == 'buy'  then
						ESX.TriggerServerCallback("crp_sellvehicles:buyVehicle", function(isPurchasable, totalMoney)
							if isPurchasable then
								ESX.ShowNotification("Koupil jsi vozidlo za " .. price .. " :-")
								ESX.UI.Menu.CloseAll()
								DeleteShopInsideVehicles()

								ESX.Game.SpawnLocalVehicle(VehicleData.model, vector3(-44.89, -1681.46, 29.42), 164.51, function (vehicle)
									TaskWarpPedIntoVehicle(currentPed, vehicle, -1)	
									ESX.Game.SetVehicleProperties(vehicle, data.current.value.vehicle)		
								end)
							else
								ESX.ShowNotification("Nemas dostatek penez, chybi ti " .. price - totalMoney .. " :-")
							end
						end, data.current.value.vehicle, data.current.value.price)
					elseif action == 'vratit' then
						ESX.TriggerServerCallback("crp_sellvehicles:buyVehicle", function(isPurchasable, totalMoney)
							if isPurchasable then
								ESX.ShowNotification("Odstranil jsi vozidlo")
								DeleteShopInsideVehicles()
								ESX.UI.Menu.CloseAll()
							else
								ESX.ShowNotification('Nejsi zamestnan jako Prodejce u bazaru')
							end
						end, data.current.value.vehicle, 0)
					elseif action == 'tuning' then
						if vmenu == false then 
							vmenu = true 
							ESX.ShowNotification('~g~ Nyní vidis tuning na vozidle')
						elseif vmenu == true then 
							vmenu = false 
							ESX.ShowNotification('~r~ Tuning vypnut')
						end
					end
					
				end, function(data2, menu2)
					menu2.close()
					vmenu = false 
					ESX.Game.DeleteVehicle(data.current.value.vehicle.model)
				end)
		end, function (data, menu)
			menu.close()
			vmenu = false 
			DeleteShopInsideVehicles()
			local playerPed = PlayerPedId()
	
			CurrentAction     = 'shop_menu'
			CurrentActionMsg  = 'Shop'
			CurrentActionData = {}
	
			FreezeEntityPosition(playerPed, false)
			SetEntityVisible(playerPed, true)
	
			IsInShopMenu = false
		end, function (data, menu)
			local VehicleData = data.current.value.vehicle
			local playerPed   = PlayerPedId()
	
			DeleteShopInsideVehicles()
			WaitForVehicleToLoad(VehicleData.model)
	
			ESX.Game.SpawnLocalVehicle(VehicleData.model, vector3(-44.89, -1681.46, 29.42), 164.51, function (vehicle)
				table.insert(LastVehicles, vehicle)
				ESX.Game.SetVehicleProperties(vehicle, data.current.value.vehicle)
				TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
				FreezeEntityPosition(vehicle, true)
				SetModelAsNoLongerNeeded(VehicleData.model)
			end)
	    end)
	
		DeleteShopInsideVehicles()
		vmenu = false 
	
	
	end)
	
end

function WaitForVehicleToLoad(modelHash)
	modelHash = (type(modelHash) == 'number' and modelHash or GetHashKey(modelHash))

	if not HasModelLoaded(modelHash) then
		RequestModel(modelHash)

		BeginTextCommandBusyString('STRING')
		AddTextComponentSubstringPlayerName('Vozidlo se nacita')
		EndTextCommandBusyString(4)

		while not HasModelLoaded(modelHash) do
			Citizen.Wait(0)
			DisableAllControlActions(0)
		end

		RemoveLoadingPrompt()
	end
end

Citizen.CreateThread(function()
	while true do 
		Citizen.Wait(1)
		local ped = PlayerPedId()
		local coordynwm = vector3(-44.89, -1681.46, 29.42)
		local pedCoords = GetEntityCoords(ped)
		local dstCheck = GetDistanceBetweenCoords(pedCoords, coordynwm, true)

		if vmenu == true and dstCheck <= 2.0 then 
			local playerPed = PlayerPedId()
			local auto = GetVehiclePedIsIn(playerPed, false)
			local coords    = GetEntityCoords(playerPed)
			local turbs = 'Ne'
			local vehProps = ESX.Game.GetVehicleProperties(auto)

			if vehProps.modTurbo then turbs = 'Ano'; end
		
			
			drawTextB = "[Turbo : ~r~"..turbs.."~s~] [Motor : ~r~"..tostring(vehProps.modEngine).."~s~] [Převodovka : ~r~"..tostring(vehProps.modTransmission).."~s~]"
			drawTextC = "[Podvozek : ~r~"..tostring(vehProps.modSuspension).."~s~] [Armor : ~r~"..tostring(vehProps.modArmor).."~s~] [Brzdy : ~r~"..tostring(vehProps.modBrakes).."~s~]"
			DrawText3Ds(coords.x, coords.y, coords.z + 1.0, drawTextB)
			DrawText3Ds(coords.x, coords.y, coords.z + 0.9, drawTextC)
		end
	end
end)

function DrawText3Ds(x,y,z, text)
	local onScreen, _x, _y = World3dToScreen2d(x, y, z)
	local p = GetGameplayCamCoords()
	local distance = GetDistanceBetweenCoords(p.x, p.y, p.z, x, y, z, 1)
	local scale = (1 / distance) * 2
	RegisterFontFile('out')
	fontId = RegisterFontId('CoreRPFont')
	local font = fontId
	local fov = (1 / GetGameplayCamFov()) * 100
	local scale = scale * fov
	if onScreen then
		  SetTextScale(0.35, 0.35)
		  SetTextFont(font)
		  SetTextProportional(1)
		  SetTextColour(255, 255, 255, 215)
		  SetTextDropshadow(10, 100, 100, 100, 255)
		  SetTextEntry("STRING")
		  SetTextCentre(1)
		  AddTextComponentString(text)
		  DrawText(_x,_y)
		  local factor = (string.len(text)) / 420
		  DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 0, 0, 16, 200)
	  end
end

function DeleteShopInsideVehicles()
	while #LastVehicles > 0 do
		local vehicle = LastVehicles[1]

		ESX.Game.DeleteVehicle(vehicle)
		table.remove(LastVehicles, 1)
	end
end

function StartShopRestriction()
	Citizen.CreateThread(function()
		while IsInShopMenu do
			Citizen.Wait(1)

			DisableControlAction(0, 75,  true) -- Disable exit vehicle
			DisableControlAction(27, 75, true) -- Disable exit vehicle
		end
	end)
end


function OpenSellMenu(veh, price, buyVehicle)
	local elements = {}

	if not buyVehicle then
		if price ~= nil then
			table.insert(elements, { ["label"] = "Změna ceny - " .. price .. " :-", ["value"] = "price" })
			table.insert(elements, { ["label"] = "Vystavit na prodej", ["value"] = "sell" })
		else
			table.insert(elements, { ["label"] = "Cena - :-", ["value"] = "price" })
		end
	else
		table.insert(elements, { ["label"] = "Koupit " .. price .. " - :-", ["value"] = "buy" })
		table.insert(elements, { ["label"] = "Dát pryč", ["value"] = "remove" })
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'sell_veh',
		{
			title    = "Menu vozidla",
			align    = 'top-right',
			elements = elements
		},
	function(data, menu)
		local action = data.current.value

		if action == "price" then
			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'sell_veh_price',
				{
					title = "Cena"
				},
			function(data2, menu2)

				local vehPrice = tonumber(data2.value)

				menu2.close()
				menu.close()

				OpenSellMenu(veh, vehPrice)
			end, function(data2, menu2)
				menu2.close()
			end)
		elseif action == "sell" then
			local vehProps = ESX.Game.GetVehicleProperties(veh)

			ESX.TriggerServerCallback("crp_sellvehicles:isVehicleValid", function(valid)

				if valid then
					DeleteVehicle(veh)
					ESX.ShowNotification("Vystavil jsi vozidlo - " .. price .. " :-")
					menu.close()
				else
					ESX.ShowNotification("Musis vozidlo vlastnit / uz je vystavene" .. #Config.VehiclePositions .. " na prodej!")
				end
	
			end, vehProps, price)
		elseif action == "buy" then
			ESX.TriggerServerCallback('kokotismus4', function(picus)
				cena = picus 
				ESX.TriggerServerCallback("crp_sellvehicles:buyVehicle", function(isPurchasable, totalMoney)
					if isPurchasable then
						DeleteVehicle(veh)
						ESX.ShowNotification("Koupil jsi vozidlo za " .. price .. " :-")
						menu.close()
					else
						ESX.ShowNotification("Nemas dostatek penez, chybi ti " .. price - totalMoney .. " :-")
					end
				end, ESX.Game.GetVehicleProperties(veh), 'debil', cena)
		end, ESX.Game.GetVehicleProperties(veh))
		elseif action == "remove" then
			ESX.TriggerServerCallback("crp_sellvehicles:buyVehicle", function(isPurchasable, totalMoney)
				if isPurchasable then
					DeleteVehicle(veh)
					ESX.ShowNotification("Odstranil jsi vozidlo")
					menu.close()
				else
					ESX.ShowNotification('Nejsi zamestnan jako Prodejce u bazaru')
				end
			end, ESX.Game.GetVehicleProperties(veh), 'kokot', 0)
		end
		
	end, function(data, menu)
		menu.close()
	end)
end

function RemoveVehicles()
	local VehPos = Config.VehiclePositions

	for i = 1, #VehPos, 1 do
		local veh, distance = ESX.Game.GetClosestVehicle(VehPos[i])

		if DoesEntityExist(veh) and distance <= 1.0 then
			DeleteEntity(veh)
		end
	end
end


LoadModel = function(model)
	while not HasModelLoaded(model) do
		RequestModel(model)

		Citizen.Wait(1)
	end
end
