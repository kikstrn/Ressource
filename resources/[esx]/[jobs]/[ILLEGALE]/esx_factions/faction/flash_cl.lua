local GUI = {}
GUI.Time = 0
local CurrentAction = nil
local CurrentActionMsg = ''
local CurrentActionData = {}
local HasAlreadyEnteredMarker = false
local LastStation = nil
local LastPart = nil
local LastPartNum = nil
local LastEntity = nil
local hintIsShowed = false
local hintToDisplay = "no hint to display"
local PlayerData = {}

ESX = nil
Citizen.CreateThread(function()
  while ESX == nil do
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    Citizen.Wait(0)
  end

  while ESX.GetPlayerData().faction == nil do
		Citizen.Wait(100)
	end

	ESX.PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  ESX.PlayerData = xPlayer
end)

RegisterNetEvent('esx:setFaction')
AddEventHandler('esx:setFaction', function(faction)
	ESX.PlayerData.faction = faction
end)

function SetVehicleMaxMods(vehicle)
  local props = {
    modEngine = 2,
    modBrakes = 2,
    modTransmission = 2,
    modSuspension = 3,
    modTurbo = true,
  }

  ESX.Game.SetVehicleProperties(vehicle, props)
end

function OpenFlashActionsMenu()
  local elements = {
    {label = 'Déposer Stock', value = 'put_stock'},
    {label = 'Prendre Stock', value = 'get_stock'},
    {label = '-------------', value = nil},
    {label = 'Déposer Armes', value = 'put_weapons'},
    {label = 'Prendre Armes', value = 'get_weapons'},
    {label = '-------------', value = nil},
    {label = 'Déposer Argent Sale', value = 'get_black_money'},
    {label = 'Prendre Argent Sale', value = 'put_black_money'}
  }
  if Config.EnablePlayerManagement and ESX.PlayerData.faction ~= nil and ESX.PlayerData.faction.grade_name == 'boss' then
    table.insert(elements, {label = '-------------', value = nil})
    table.insert(elements, {label = 'Actions Boss', value = 'faction_actions'})
  end

  ESX.UI.Menu.CloseAll()

  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'flash_actions',
    {
      title = 'Flash',
      elements = elements
    },
    function(data, menu)
      if data.current.value == 'put_stock' then
        OpenPutStocksFlashMenu()
      elseif data.current.value == 'get_stock' then
        OpenGetStocksFlashMenu()
      elseif data.current.value == 'get_weapons' then
        OpenGetWeaponsFlash()
      elseif data.current.value == 'put_weapons' then
        OpenPutWeaponsFlash()
      elseif data.current.value == 'get_black_money' then
        OpenGetBlackMoneyFlash()
      elseif data.current.value == 'put_black_money' then
        OpenPutBlackMoneyFlash()
      elseif data.current.value == 'faction_actions' then
        TriggerEvent('esx_societyfaction:openBossMenuFaction', 'flash', function(data, menu)
          menu.close()
        end)
      end
    end,
    function(data, menu)
      menu.close()
      CurrentAction = 'flash_actions_menu'
      CurrentActionMsg = 'Appuyez sur ~INPUT_CONTEXT~ pour accéder au menu.'
      CurrentActionData = {}
    end
  )
end

function OpenFlashCloakroomMenu()
  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'cloakroom_flash',
    {
      css = 'vestiaire',
      title = 'Vestiaire',
      align = 'top-left',
      elements = {
        {label = 'Tenue Civil', value = 'citizen_wear'},
        {label = 'Tenue Flash', value = 'flash_wear'}
      },
    },
    function(data, menu)
      menu.close()
      if data.current.value == 'citizen_wear' then
        ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, factionSkin)
          TriggerEvent('skinchanger:loadSkin', skin)
        end)
      end

      if data.current.value == 'flash_wear' then
        ESX.TriggerServerCallback('esx_skin:getPlayerSkinFaction', function(skin, factionSkin)

          if skin.sex == 0 then
            TriggerEvent('skinchanger:loadClothes', skin, factionSkin.skin_male)
          else
            TriggerEvent('skinchanger:loadClothes', skin, factionSkin.skin_female)
          end

        end)
      end

      CurrentAction = 'flash_cloakroom_menu'
      CurrentActionMsg = 'Appuyez sur ~INPUT_CONTEXT~ pour accéder au vestiaire.'
      CurrentActionData = {}
    end,
    function(data, menu)
      menu.close()
    end
  )
end

function OpenFlashGarageMenu()
  local elements = {
    {label = 'Liste Véhicules', value = 'vehicle_list'}
  }
  ESX.UI.Menu.CloseAll()
  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'flash_garage',
    {
      css = 'vehicle',
      title = 'Flash',
      elements = elements
    },
    function(data, menu)
      if data.current.value == 'vehicle_list' then

        if Config.EnableSocietyOwnedVehicles then

          local elements = {}

          ESX.TriggerServerCallback('esx_societyfaction:getVehiclesInGarage', function(vehicles)

            for i=1, #vehicles, 1 do
              table.insert(elements, {label = GetDisplayNameFromVehicleModel(vehicles[i].model) .. ' [' .. vehicles[i].plate .. ']', value = vehicles[i]})
            end

            ESX.UI.Menu.Open(
              'default', GetCurrentResourceName(), 'vehicle_spawner',
              {
                css = 'vehicle',
                title = 'Véhicule Flash',
                align = 'top-left',
                elements = elements,
              },
              function(data, menu)

                menu.close()

                local playerPed = GetPlayerPed(-1)
                local vehicleProps = data.current.value
                local platenum = math.random(10, 90)

                ESX.Game.SpawnVehicle(vehicleProps.model, Config.Flash.VehicleFlashSpawnPoint.Pos, 321.105, function(vehicle)
                  ESX.Game.SetVehicleProperties(vehicle, vehicleProps)
                  SetVehicleNumberPlateText(vehicle, "FLASH" .. platenum)
                  TaskWarpPedIntoVehicle(playerPed,  vehicle,  -1)
                  local plate = GetVehicleNumberPlateText(vehicle)
                  plate = string.gsub(plate, " ", "")
                  TriggerServerEvent('esx_vehiclelock:givekey', 'no', plate) -- vehicle lock
                end)

                TriggerServerEvent('esx_societyfaction:removeVehicleFromGarage', 'flash', vehicleProps)

              end,
              function(data, menu)
                menu.close()
              end
            )

          end, 'flash')

        else

          local elements = {
            {label = 'Schafter V12', value = 'schafter4'},
            {label = 'BF400', value = 'bf400'},
            {label = 'Sultan RS', value = 'sultanrs'}
          }

          if Config.EnablePlayerManagement and ESX.PlayerData.faction ~= nil and ESX.PlayerData.faction.grade_name == 'boss' then
            table.insert(elements, {label = 'Sultan', value = 'sultan'})
            table.insert(elements, {label = 'Granger', value = 'granger'})
          end

          ESX.UI.Menu.CloseAll()

          ESX.UI.Menu.Open(
            'default', GetCurrentResourceName(), 'spawn_vehicle',
            {
              css = 'vehicle',
              title = 'Véhicule Flash',
              elements = elements
            },
            function(data, menu)

              for i=1, #elements, 1 do

                local model = data.current.value
                local platenum = math.random(10, 90)
                local playerPed = GetPlayerPed(-1)

                if Config.MaxInService == -1 then

                  ESX.Game.SpawnVehicle(data.current.value, Config.Flash.VehicleFlashSpawnPoint.Pos, 321.105, function(vehicle)
                    SetVehicleNumberPlateText(vehicle, "FLASH" .. platenum)
                    SetVehicleColours(vehicle, 12, 12)
                    SetVehicleWindowTint(vehicle, 1)
                    SetVehicleMaxMods(vehicle)
                    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
                    local plate = GetVehicleNumberPlateText(vehicle)
                    plate = string.gsub(plate, " ", "")
                    TriggerServerEvent('esx_vehiclelock:givekey', 'no', plate) -- vehicle lock
                  end)

                  break

                else

                  ESX.TriggerServerCallback('esx_service:enableService', function(canTakeService, maxInService, inServiceCount)

                    if canTakeService then

                      ESX.Game.SpawnVehicle(data.current.value, Config.Flash.VehicleFlashSpawnPoint.Pos, 321.105, function(vehicle)
                        SetVehicleNumberPlateText(vehicle, "FLASH" .. platenum)
                        SetVehicleColours(vehicle, 12, 12)
                        SetVehicleWindowTint(vehicle, 1)
                        SetVehicleMaxMods(vehicle)
                        TaskWarpPedIntoVehicle(playerPed,  vehicle, -1)
                      end)

                    else

                      ESX.ShowNotification('service_full' .. inServiceCount .. '/' .. maxInService)

                    end
                  end, 'flash')

                  break

                end
              end
              menu.close()
            end,

            function(data, menu)
              menu.close()
              OpenFlashActionsMenu()
            end
          )

        end
    end
    end,
    function(data, menu)
      menu.close()

      CurrentAction = 'flash_garage_menu'
      CurrentActionMsg = 'Appuyez sur ~INPUT_CONTEXT~ pour accéder au garage.'
      CurrentActionData = {}
    end
  )
end

-- Stock Items Flash
function OpenGetStocksFlashMenu()
	ESX.TriggerServerCallback('esx_flash:getStockItemsFlash', function(items)
		local elements = {}

		for i=1, #items, 1 do
			table.insert(elements, {
				label = 'x' .. items[i].count .. ' ' .. items[i].label,
				value = items[i].name
			})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_flash_menu', {
			title = 'Flash',
			align = 'top-left',
			elements = elements
		}, function(data, menu)
			local itemName = data.current.value

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_flash_menu_get_item_count', {
				title = 'Quantité'
			}, function(data2, menu2)
				local count = tonumber(data2.value)

				if count == nil then
					ESX.ShowNotification('Quantité invalide')
				else
					menu2.close()
					menu.close()
					TriggerServerEvent('esx_flash:getStockItemsFlash', itemName, count)

					Citizen.Wait(1000)
					OpenGetStocksFlashMenu()
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)
	end)
end

function OpenPutStocksFlashMenu()
	ESX.TriggerServerCallback('esx_faction:getPlayerInventory', function(inventory)
		local elements = {}

		for i=1, #inventory.items, 1 do
			local item = inventory.items[i]

			if item.count > 0 then
				table.insert(elements, {
					label = item.label .. ' x' .. item.count,
					type = 'item_standard',
					value = item.name
				})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_flash_menu', {
			css = 'Inventaire',
			title = 'Inventaire',
			align = 'top-left',
			elements = elements
		}, function(data, menu)
			local itemName = data.current.value

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_flash_menu_put_item_count', {
				title = 'Quantité'
			}, function(data2, menu2)
				local count = tonumber(data2.value)

				if count == nil then
					ESX.ShowNotification('Quantité invalide')
				else
					menu2.close()
					menu.close()
					TriggerServerEvent('esx_flash:putStockItemsFlash', itemName, count)

					Citizen.Wait(1000)
					OpenPutStocksFlashMenu()
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)
	end)
end

AddEventHandler('esx_flash:hasEnteredMarkerFlash', function(zone, station, part, partNum)

  if zone == 'FlashActions' then
    CurrentAction = 'flash_actions_menu'
    CurrentActionMsg = 'Appuyez sur ~INPUT_CONTEXT~ pour accéder au menu.'
    CurrentActionData = {}
  elseif zone == 'CloakroomFlash' then
      CurrentAction = 'flash_cloakroom_menu'
      CurrentActionMsg = 'Appuyez sur ~INPUT_CONTEXT~ pour accéder au vestiaire.'
      CurrentActionData = {} 
  elseif zone == 'GarageFlash' then
      CurrentAction = 'flash_garage_menu'
      CurrentActionMsg = 'Appuyez sur ~INPUT_CONTEXT~ pour accéder au garage.'
      CurrentActionData = {} 
  elseif zone == 'VehicleFlashDeleter' then
    local playerPed = GetPlayerPed(-1)
    if IsPedInAnyVehicle(playerPed,  false) then
      CurrentAction = 'delete_flash_vehicle'
      CurrentActionMsg = 'Appuyez sur ~INPUT_CONTEXT~ pour ranger le véhicule.'
      CurrentActionData = {}
    end
  end
end)

AddEventHandler('esx_flash:hasExitedMarkerFlash', function(zone, station, part, partNum)
  ESX.UI.Menu.CloseAll()
  CurrentAction = nil
end)

-- Display markers
Citizen.CreateThread(function()
  while true do

    Citizen.Wait(0)

    if ESX.PlayerData.faction ~= nil and ESX.PlayerData.faction.name == 'flash' then
        local playerPed = GetPlayerPed(-1)
        local coords = GetEntityCoords(GetPlayerPed(-1))

        for k,v in pairs(Config.Flash) do
          if(v.Type ~= -1 and GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < Config.DrawDistance) then
            DrawMarker(v.Type, v.Pos.x, v.Pos.y, v.Pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, v.Size.x, v.Size.y, v.Size.z, v.Color.r, v.Color.g, v.Color.b, 100, false, true, 2, false, false, false, false)
          end
        end
         
    end

  end
end)

-- Enter / Exit marker events
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)

    if ESX.PlayerData.faction ~= nil and ESX.PlayerData.faction.name == 'flash' then
      local coords = GetEntityCoords(GetPlayerPed(-1))
      local isInMarker = false
      local currentZone = nil
      local currentStation = nil
      local currentPart = nil
      local currentPartNum = nil

      for k,v in pairs(Config.Flash) do
        if(GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < 1) then
          isInMarker = true
          currentZone = k
        end
      end     

      local hasExited = false

      if isInMarker and not HasAlreadyEnteredMarker or (isInMarker and (LastZone ~= currentZone or LastStation ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum) ) then

        if
          (LastZone ~= nil and LastStation ~= nil and LastPart ~= nil and LastPartNum ~= nil) and
          (LastZone ~= currentZone or LastStation ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum)
        then
          TriggerEvent('esx_flash:hasExitedMarkerFlash', LastZone, LastStation, LastPart, LastPartNum)
          hasExited = true
        end

        HasAlreadyEnteredMarker = true
        LastZone = currentZone
        LastStation = currentStation
        LastPart = currentPart
        LastPartNum = currentPartNum

        TriggerEvent('esx_flash:hasEnteredMarkerFlash', currentZone, currentStation, currentPart, currentPartNum)
      end

      if not hasExited and not isInMarker and HasAlreadyEnteredMarker then
        HasAlreadyEnteredMarker = false
        TriggerEvent('esx_flash:hasExitedMarkerFlash', LastZone, LastStation, LastPart, LastPartNum)
      end  

    end

  end
end)

-- Key Controls
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)

    if CurrentAction ~= nil then

      SetTextComponentFormat('STRING')
      AddTextComponentString(CurrentActionMsg)
      DisplayHelpTextFromStringLabel(0, 0, 1, -1)

      if IsControlPressed(0, 38) and ESX.PlayerData.faction ~= nil and ESX.PlayerData.faction.name == 'flash' and (GetGameTimer() - GUI.Time) > 300 then

        if CurrentAction == 'flash_actions_menu' then
          OpenFlashActionsMenu()
        end

        if CurrentAction == 'flash_cloakroom_menu' then
          OpenFlashCloakroomMenu()
        end

        if CurrentAction == 'flash_garage_menu' then
          OpenFlashGarageMenu()
        end

        if CurrentAction == 'delete_flash_vehicle' then

          local playerPed = GetPlayerPed(-1)
          local vehicle = GetVehiclePedIsIn(playerPed,  false)
          local hash = GetEntityModel(vehicle)
          local plate = GetVehicleNumberPlateText(vehicle)
          if hash == GetHashKey('schafter4') or hash == GetHashKey('bf400') or hash == GetHashKey('sultanrs') or hash == GetHashKey('sultan') or hash == GetHashKey('granger') then
            if Config.MaxInService ~= -1 then
              TriggerServerEvent('esx_service:disableService', 'flash')
            end
            DeleteVehicle(vehicle)
            TriggerServerEvent('esx_vehiclelock:deletekeyjobs', 'no', plate) --vehicle lock
          else
            ESX.ShowNotification('Vous ne pouvez ranger que des ~b~véhicules de Faction~s~.')
          end

        end

        CurrentAction = nil
        GUI.Time = GetGameTimer()

      end

    end
  end
end)

function OpenGetWeaponsFlash()
  ESX.TriggerServerCallback('esx_flash:getFlashWeapons', function(weapons)
    local elements = {}

    for i=1, #weapons, 1 do
      if weapons[i].count > 0 then
        table.insert(elements, {
          label = 'x' .. weapons[i].count .. ' ' .. ESX.GetWeaponLabel(weapons[i].name),
          value = weapons[i].name
        })
      end
    end

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory_flash_get_weapon', {
      title = 'Prendre armes',
      align = 'top-left',
      elements = elements
    }, function(data, menu)
      menu.close()

      ESX.TriggerServerCallback('esx_flash:removeFlashWeapon', function()
        OpenGetWeaponsFlash()
      end, data.current.value)
    end, function(data, menu)
      menu.close()
    end)
  end)
end

function OpenPutWeaponsFlash()
  local elements = {}
  local playerPed = PlayerPedId()
  local weaponList = ESX.GetWeaponList()

  for i=1, #weaponList, 1 do
    local weaponHash = GetHashKey(weaponList[i].name)

    if HasPedGotWeapon(playerPed, weaponHash, false) and weaponList[i].name ~= 'WEAPON_UNARMED' then
      table.insert(elements, {
        label = weaponList[i].label,
        value = weaponList[i].name
      })
    end
  end

  ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory_flash_put_weapon', {
    title = 'Déposer armes',
    align = 'top-left',
    elements = elements
  }, function(data, menu)
    menu.close()
    ESX.TriggerServerCallback('esx_flash:addFlashWeapon', function()
      OpenPutWeaponsFlash()
    end, data.current.value, true)
  end, function(data, menu)
    menu.close()
  end)
end

function OpenGetBlackMoneyFlash()

  ESX.TriggerServerCallback('esx_faction:getPlayerInventory2', function(inventory)

    local elements = {}

    table.insert(elements, {label = 'Argent sale: ' .. inventory.blackMoney, type = 'item_account', value = 'black_money'})

    ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'put_black_money',
      {
        title = 'Inventaire',
        align = 'top-left',
        elements = elements,
      },
      function(data, menu)

        ESX.UI.Menu.Open(
          'dialog', GetCurrentResourceName(), 'put_item_count',
          {
            title = 'Montant',
          },
          function(data2, menu)

            menu.close()

            TriggerServerEvent('esx_flash:getBlackMoney', data.current.type, data.current.value, tonumber(data2.value))

            ESX.SetTimeout(300, function()
              OpenGetBlackMoneyFlash()
            end)

          end,
          function(data2,menu)
            menu.close()
          end
        )

      end,
      function(data, menu)
        menu.close()
      end
    )
  end)
end

function OpenPutBlackMoneyFlash()

  ESX.TriggerServerCallback('esx_flash:getBlackMoney', function(inventory)

    local elements = {}
    table.insert(elements, {label = 'Argent sale: ' .. inventory.blackMoney, type = 'item_account', value = 'black_money'})

    ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'get_black_money',
      {
        title = 'Inventaire',
        align = 'top-left',
        elements = elements,
      },
      function(data, menu)
        ESX.UI.Menu.Open(
          'dialog', GetCurrentResourceName(), 'get_item_count',
          {
            title = 'Montant',
          },
          function(data2, menu)

            local quantity = tonumber(data2.value)

            if quantity == nil then
              ESX.ShowNotification('Montant invalide')
            else
              menu.close()
              TriggerServerEvent('esx_flash:getPutMoney', data.current.type, data.current.value, quantity)
              ESX.SetTimeout(300, function()
                OpenPutBlackMoneyFlash()
              end)
            end
          end,
          function(data2,menu)
            menu.close()
          end
        )
      end,
      function(data, menu)
        menu.close()
      end
    )
  end)
end