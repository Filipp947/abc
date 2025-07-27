-- hub name
getgenv().namehub = "Hyperlib Auto Script Hub"

-- load ui library (only once)
local ui = loadstring(game:HttpGet("https://raw.githubusercontent.com/wzaxk/check/refs/heads/main/uiloader"))()

local HYPERLIB_DATA_URL = "https://raw.githubusercontent.com/Fantemil/Hyperlib/refs/heads/main/scriptdata.json"

local function getCurrentPlaceId()
    return tostring(game.PlaceId)
end

local function fetchHyperlibData()
    local success, result = pcall(function()
        return game:HttpGet(HYPERLIB_DATA_URL)
    end)

    if not success then
        warn("Failed to fetch Hyperlib data: " .. tostring(result))
        return nil
    end

    local jsonSuccess, jsonData = pcall(function()
        return game:GetService("HttpService"):JSONDecode(result)
    end)

    if jsonSuccess then
        print("Successfully fetched Hyperlib data")
        return jsonData
    else
        warn("Failed to parse Hyperlib JSON data: " .. tostring(jsonData))
        return nil
    end
end

local function filterScriptsByPlaceId(scriptData, targetPlaceId)
    local matchingScripts = {}

    if not scriptData then
        return matchingScripts
    end

    print("Filtering scripts for PlaceId: " .. targetPlaceId)

    for scriptName, scriptInfo in pairs(scriptData) do
        if type(scriptInfo) == "table"
            and scriptInfo.universal == false
            and scriptInfo.gameid == targetPlaceId
            and scriptInfo.gitlink
            and scriptInfo.game == true then

            print("✅ Found matching script: " .. scriptName)
            matchingScripts[scriptName] = {
                gitlink = scriptInfo.gitlink,
                gameid = scriptInfo.gameid
            }
        end
    end

    return matchingScripts
end

local function getGameName()
    local success, gameInfo = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)

    if success and gameInfo then
        return gameInfo.Name
    else
        return "Game " .. tostring(game.PlaceId)
    end
end

local function createHyperlibHub()
    wait(1)

    local currentPlaceId = getCurrentPlaceId()
    print("Current PlaceId: " .. currentPlaceId)

    local scriptData = fetchHyperlibData()
    if not scriptData then
        warn("Could not fetch Hyperlib data")
        return
    end

    local matchingScripts = filterScriptsByPlaceId(scriptData, currentPlaceId)

    local main = ui.new()

    local scriptCount = 0
    for _ in pairs(matchingScripts) do
        scriptCount = scriptCount + 1
    end

    print("Found " .. scriptCount .. " matching scripts")

    if scriptCount > 0 then
        local gameName = getGameName()
        local gameTab = main:create_tab(gameName)
        local buttonIndex = 0
        for scriptName, scriptInfo in pairs(matchingScripts) do
            buttonIndex = buttonIndex + 1
            print("Creating button " .. buttonIndex .. ": " .. scriptName)

            gameTab:create_button({
                name = scriptName,
                flag = "btn_" .. tostring(buttonIndex),
                section = "left",
                enabled = false,
                callback = function()
                    print("🔄 Loading: " .. scriptName)
                    spawn(function()
                        local success, err = pcall(function()
                            local code = game:HttpGet(scriptInfo.gitlink)
                            loadstring(code)()
                        end)
                        if success then
                            print("✅ Loaded: " .. scriptName)
                        else
                            warn("❌ Error loading " .. scriptName .. ": " .. tostring(err))
                        end
                    end)
                end
            })
        end

        print("Created " .. buttonIndex .. " buttons successfully")

    else
        local unsupportedTab = main:create_tab("Game Unsupported")

        unsupportedTab:create_title({
            name = "No Scripts Found",
            section = "left"
        })

        unsupportedTab:create_button({
            name = "PlaceId: " .. currentPlaceId,
            flag = "placeid_btn",
            section = "left",
            enabled = false,
            callback = function()
                print("Current PlaceId: " .. currentPlaceId)
                if setclipboard then
                    setclipboard(currentPlaceId)
                end
            end
        })
    end

    local utilTab = main:create_tab("Utils")

    utilTab:create_button({
        name = "Refresh Scripts",
        flag = "refresh_btn",
        section = "left",
        enabled = false,
        callback = function()
            print("Refreshing...")
            createHyperlibHub()
        end
    })
end

createHyperlibHub()
