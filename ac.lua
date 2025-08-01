-- hub name
getgenv().namehub = 'Example'

local ui = loadstring(game:HttpGet("https://raw.githubusercontent.com/wzaxk/check/refs/heads/main/uiloader"))()

local main = ui.new()
local tabAuto = main:create_tab("Auto", "7734051454")

-- auto harvest toggle
tabAuto.create_toggle({
    name = 'Auto Harvest V1',
    flag = 'autoharvestv1',
    section = 'left',
    enabled = false,
    callback = function(state)
        if state then
            task.spawn(function()
                local players = game:GetService("Players")
                local player = players.LocalPlayer
                local replicatedStorage = game:GetService("ReplicatedStorage")
                local byteNetReliable = replicatedStorage:WaitForChild("ByteNetReliable")
                local buffer = buffer.fromstring("\1\1\0\1")

                -- find player farm
                local farm = nil
                for _, f in ipairs(workspace.Farm:GetChildren()) do
                    if f:FindFirstChild("Important") and f.Important:FindFirstChild("Data") and f.Important.Data:FindFirstChild("Owner") then
                        if f.Important.Data.Owner.Value == player.Name then
                            farm = f
                            break
                        end
                    end
                end

                if not farm then
                    warn("Could not find your farm.")
                    ui.Flags['autoharvestv1'] = false
                    return
                end

                local plantsPhysical = farm.Important:FindFirstChild("Plants_Physical")
                if not plantsPhysical then
                    warn("Could not find Plants_Physical.")
                    ui.Flags['autoharvestv1'] = false
                    return
                end

                -- get unique plant names
                local plantNames = {}
                local seenPlants = {}
                for _, plant in ipairs(plantsPhysical:GetChildren()) do
                    if not seenPlants[plant.Name] then
                        table.insert(plantNames, plant.Name)
                        seenPlants[plant.Name] = true
                    end
                end
                ui.Flags['plantnames'] = plantNames

                -- get one fruit to read possible attributes for mutations
                local firstFruit = nil
                for _, plant in ipairs(plantsPhysical:GetChildren()) do
                    local fruitsFolder = plant:FindFirstChild("Fruits")
                    if fruitsFolder then
                        if #fruitsFolder:GetChildren() > 0 then
                            firstFruit = fruitsFolder:GetChildren()[1]
                            break
                        end
                    else
                        firstFruit = plant
                        break
                    end
                end

                if not firstFruit then
                    warn("Could not find any fruit to detect mutations.")
                    ui.Flags['autoharvestv1'] = false
                    return
                end

                local ignoredAttrs = {
                    Inspected = true,
                    MaxFruits = true,
                    IgnoreFruitDistance = true,
                    FruitVariantLuck = true,
                    OfflineGrowthTarget = true,
                    WeightMulti = true,
                    MaxAge = true,
                    GrowRateMulti = true,
                    DoneGrowTime = true
                }

                local mutationList = {}
                for _, attrName in ipairs(firstFruit:GetAttributes() and firstFruit:GetAttributes() or {}) do
                    -- skip: GetAttributes returns a table of key-values, so we check keys
                    if not ignoredAttrs[attrName] then
                        table.insert(mutationList, attrName)
                    end
                end

                -- fix: sometimes GetAttributes() is empty, so use GetAttributeNames()
                if firstFruit.GetAttributeNames then
                    mutationList = {}
                    for _, attrName in ipairs(firstFruit:GetAttributeNames()) do
                        if not ignoredAttrs[attrName] then
                            table.insert(mutationList, attrName)
                        end
                    end
                end

                ui.Flags['mutationlist'] = mutationList

                while ui.Flags['autoharvestv1'] do
                    local selectedMutations = ui.Flags['mutationselect'] or {}
                    local selectedVariants = ui.Flags['variantselect'] or {}
                    local selectedPlants = ui.Flags['plantselect'] or {}
                    local mode = ui.Flags['filtermode'] or 'Whitelist'
                    local weightMode = ui.Flags['weightmode'] or 'Below'
                    local weightValue = ui.Flags['weightslider'] or 0
                    local speedMode = ui.Flags['speedmode'] or 'Normal'

                    local speed = 0.5
                    if speedMode == 'Slow' then speed = 1
                    elseif speedMode == 'Normal' then speed = 0.5
                    elseif speedMode == 'Fast' then speed = 0.3
                    elseif speedMode == 'Super' then speed = 0.1
                    elseif speedMode == 'Hyper' then speed = 0 end

                    for _, plant in ipairs(plantsPhysical:GetChildren()) do
                        if not ui.Flags['autoharvestv1'] then break end

                        local plantNameMatches = true
                        if #selectedPlants > 0 then
                            if mode == 'Whitelist' then
                                plantNameMatches = table.find(selectedPlants, plant.Name) ~= nil
                            elseif mode == 'Blacklist' then
                                plantNameMatches = table.find(selectedPlants, plant.Name) == nil
                            end
                        end
                        if not plantNameMatches then continue end

                        local fruits = {}
                        local fruitsFolder = plant:FindFirstChild("Fruits")
                        if fruitsFolder then
                            fruits = fruitsFolder:GetChildren()
                        else
                            table.insert(fruits, plant)
                        end

                        for _, fruit in ipairs(fruits) do
                            if not ui.Flags['autoharvestv1'] then break end

                            local variant = fruit:FindFirstChild("Variant") and fruit.Variant.Value or "Normal"
                            local variantMatches = true
                            if #selectedVariants > 0 then
                                if mode == 'Whitelist' then
                                    variantMatches = table.find(selectedVariants, variant) ~= nil
                                elseif mode == 'Blacklist' then
                                    variantMatches = table.find(selectedVariants, variant) == nil
                                end
                            end
                            if not variantMatches then continue end

                            local matchesMutation = false
                            if #selectedMutations > 0 then
                                for _, mutation in ipairs(selectedMutations) do
                                    if fruit:GetAttribute(mutation) == true then
                                        matchesMutation = true
                                        break
                                    end
                                end
                                if mode == 'Whitelist' then
                                    if not matchesMutation then continue end
                                elseif mode == 'Blacklist' then
                                    if matchesMutation then continue end
                                end
                            end

                            local w = fruit:FindFirstChild("Weight")
                            local weight = (w and tonumber(w.Value)) or 0
                            if weightMode == 'Below' then
                                if weight > weightValue then continue end
                            else
                                if weight < weightValue then continue end
                            end

                            byteNetReliable:FireServer(buffer, { fruit })
                            task.wait(math.max(0.01, speed))
                        end
                    end

                    task.wait(speed)
                end
            end)
        end
    end
})

-- dynamic mutations multi-dropdown
tabAuto.create_multidropdown({
    name = 'Select Mutations',
    flag = 'mutationselect',
    section = 'left',
    option = '',
    options = ui.Flags['mutationlist'] or {},
    callback = function() end
})

-- variants multi-dropdown
tabAuto.create_multidropdown({
    name = 'Select Variants',
    flag = 'variantselect',
    section = 'left',
    option = '',
    options = {'Normal', 'Gold', 'Rainbow'},
    callback = function() end
})

-- plants multi-dropdown
tabAuto.create_multidropdown({
    name = 'Select Plants',
    flag = 'plantselect',
    section = 'left',
    option = '',
    options = ui.Flags['plantnames'] or {},
    callback = function() end
})

-- whitelist/blacklist mode
tabAuto.create_dropdown({
    name = 'Mode',
    flag = 'filtermode',
    section = 'left',
    option = 'Whitelist',
    options = {'Whitelist', 'Blacklist'},
    callback = function() end
})

-- weight mode
tabAuto.create_dropdown({
    name = 'Weight Mode',
    flag = 'weightmode',
    section = 'left',
    option = 'Below',
    options = {'Below', 'Above'},
    callback = function() end
})

-- weight slider
tabAuto.create_slider({
    name = 'Weight',
    flag = 'weightslider',
    section = 'left',
    value = 100,
    minimum_value = 0,
    maximum_value = 1000,
    callback = function(value) end
})

-- speed mode
tabAuto.create_dropdown({
    name = 'Speed Mode',
    flag = 'speedmode',
    section = 'left',
    option = 'Normal',
    options = {'Slow', 'Normal', 'Fast', 'Super', 'Hyper'},
    callback = function() end
})
