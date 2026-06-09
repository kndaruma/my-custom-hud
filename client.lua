-- ====================================================================================
-- [ CACHING NATIVE FUNCTIONS ]
-- ====================================================================================
local PlayerPedId, PlayerId, GetEntityHealth, GetPedArmour = PlayerPedId, PlayerId, GetEntityHealth, GetPedArmour
local GetPlayerSprintStaminaRemaining, GetPlayerUnderwaterTimeRemaining = GetPlayerSprintStaminaRemaining, GetPlayerUnderwaterTimeRemaining
local GetEntityCoords, GetStreetNameAtCoord, GetStreetNameFromHashKey = GetEntityCoords, GetStreetNameAtCoord, GetStreetNameFromHashKey
local GetNameOfZone, GetLabelText, GetEntityHeading = GetNameOfZone, GetLabelText, GetEntityHeading
local SendNUIMessage, DisplayRadar, HideHudComponentThisFrame = SendNUIMessage, DisplayRadar, HideHudComponentThisFrame
local SetRadarBigmapEnabled, GetClockHours, GetClockMinutes, GetActivePlayers = SetRadarBigmapEnabled, GetClockHours, GetClockMinutes, GetActivePlayers
local SetMinimapComponentPosition, IsPauseMenuActive = SetMinimapComponentPosition, IsPauseMenuActive
local SetMinimapClipType = SetMinimapClipType 
local RequestScaleformMovie, HasScaleformMovieLoaded = RequestScaleformMovie, HasScaleformMovieLoaded
local BeginScaleformMovieMethod, ScaleformMovieMethodAddParamInt, EndScaleformMovieMethod = BeginScaleformMovieMethod, ScaleformMovieMethodAddParamInt, EndScaleformMovieMethod
local IsBigmapActive = IsBigmapActive -- ✅ แก้ไขเป็น IsBigmapActive ที่ถูกต้องแล้ว

-- ====================================================================================
-- [ CONFIG & VARIABLES ]
-- ====================================================================================
local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData, isLoggedIn, hudShown = {}, false, false
local hunger, thirst = 100, 100
local minimapScaleform = nil

-- 📍 พิกัดมาตรฐานสำหรับมินิแมพสี่เหลี่ยมผืนผ้า
local function ApplyMinimapLayout()
    SetMinimapClipType(0)
    SetMinimapComponentPosition('minimap', 'L', 'B', -0.0045, 0.002, 0.150, 0.188888)
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.020, 0.032, 0.111, 0.159)
    -- ✅ ขยายกล่องดำรองหลังแผนที่ เพื่อแก้ปัญหาแมพจางโปร่งแสง
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.03, 0.022, 0.266, 0.237)
    SetMinimapComponentPosition('minimap_blips', 'L', 'B', -0.0045, 0.002, 0.150, 0.188888)
end

local function formatMoney(amount)
    local formatted = tostring(amount)
    while true do  
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k == 0) then break end
    end
    return formatted
end

-- ====================================================================================
-- [ INITIALIZE HUD ]
-- ====================================================================================
local function InitHUD()
    Wait(500)
    SetRadarBigmapEnabled(true, false)
    Wait(100)
    SetRadarBigmapEnabled(false, false)
    ApplyMinimapLayout()
end

-- ⚡ ลูปความเร็วสูง (Wait 0) : ควบคุมเอนจิ้นเกมแบบ Real-time
CreateThread(function()
    DisplayRadar(false) -- ✅ ซ่อนแมพตั้งแต่เริ่ม (แก้บั๊กแมพโผล่หน้าเลือกตัวละคร)

    minimapScaleform = RequestScaleformMovie("minimap")
    while not HasScaleformMovieLoaded(minimapScaleform) do
        Wait(0)
    end

    while true do
        if isLoggedIn then
            HideHudComponentThisFrame(3)
            HideHudComponentThisFrame(4)
            HideHudComponentThisFrame(13)
            
            -- 🔒 สั่งบล็อกหลอดเลือดและเกราะดั้งเดิมทุกเฟรม
            BeginScaleformMovieMethod(minimapScaleform, "SETUP_HEALTH_ARMOUR")
            ScaleformMovieMethodAddParamInt(3)
            EndScaleformMovieMethod()
            
            -- ✅ ใช้ IsBigmapActive() เช็กสถานะการขยายแมพ
            if IsBigmapActive() then
                SetRadarBigmapEnabled(false, false)
                ApplyMinimapLayout()
            end
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

-- 🔄 ลูปคุมการแสดงผลแผนที่ (ESC และตอนเลือกตัวละคร)
CreateThread(function()
    local wasPauseMenuOpen = false
    while true do
        if isLoggedIn then
            local isPauseOpen = IsPauseMenuActive()
            
            if isPauseOpen then
                wasPauseMenuOpen = true
                DisplayRadar(false) -- ✅ ซ่อนมินิแมพเนียนๆ ตอนกด ESC
            elseif wasPauseMenuOpen and not isPauseOpen then
                wasPauseMenuOpen = false
                Wait(500) 
                
                SetRadarBigmapEnabled(true, false)
                Wait(50)
                SetRadarBigmapEnabled(false, false)
                
                ApplyMinimapLayout()
            end
            
            if not isPauseOpen then
                ApplyMinimapLayout()
                DisplayRadar(true) -- ✅ เปิดแมพเฉพาะตอนเดินเล่นปกติ
            end
            Wait(500) 
        else
            DisplayRadar(false) -- ✅ บังคับซ่อนแมพ 100% ถ้ายังไม่ล็อกอิน
            Wait(1000)
        end
    end
end)

-- ====================================================================================
-- [ CORE HUD LOOPS ]
-- ====================================================================================
CreateThread(function()
    while true do
        if isLoggedIn then
            local ped, playerId = PlayerPedId(), PlayerId()
            local health = math.max(0, GetEntityHealth(ped) - 100)
            local armor = GetPedArmour(ped)
            local stamina = math.max(0, 100.0 - GetPlayerSprintStaminaRemaining(playerId))
            local oxygen = math.min(100, GetPlayerUnderwaterTimeRemaining(playerId) * 10.0)

            SendNUIMessage({
                action = "updateStatus",
                health = health, food = hunger, stamina = stamina,
                water = thirst, armor = armor, oxygen = oxygen
            })

            local coords = GetEntityCoords(ped)
            local streetName = GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z))
            local zoneName = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))
            local heading = GetEntityHeading(ped)
            
            local directions = {"N", "NE", "E", "SE", "S", "SW", "W", "NW"}
            local headingTxt = directions[math.floor((heading + 22.5) / 45) % 8 + 1]

            SendNUIMessage({
                action = "updateLocation",
                street = streetName, zone = zoneName,
                headingTxt = headingTxt, headingDeg = math.floor(heading)
            })
            
            -- ✅ ระบบเช็กเมนู ESC เพื่อซ่อน/โชว์ HUD ตัวเลขและหลอดสถานะ
            local isPauseOpen = IsPauseMenuActive()
            if isPauseOpen and hudShown then
                SendNUIMessage({action = "hideHUD"})
                hudShown = false
            elseif not isPauseOpen and not hudShown then
                SendNUIMessage({action = "showHUD"})
                hudShown = true
            end
            
            Wait(200)
        else
            Wait(1000)
        end
    end
end)

-- ====================================================================================
-- [ HELPER FUNCTION: UPDATE INFO HUD ]
-- ====================================================================================
-- ฟังก์ชันกลางสำหรับสั่งรีเฟรชเงิน เวลา และจำนวนคนเล่น
local function UpdateInfoHUD()
    if not isLoggedIn then return end
    PlayerData = QBCore.Functions.GetPlayerData()
    
    local cash, bank = 0, 0
    if PlayerData and PlayerData.money then 
        cash = PlayerData.money['cash'] or 0
        bank = PlayerData.money['bank'] or 0 
    end
    
    local hours, minutes = GetClockHours(), GetClockMinutes()
    local timeStr = string.format("%02d:%02d %s", (hours % 12 == 0 and 12 or hours % 12), minutes, hours >= 12 and "pm" or "am")

    SendNUIMessage({
        action = "updateInfo",
        time = timeStr, temp = "30",
        cash = formatMoney(cash), bank = formatMoney(bank)
    })
    
    local players = #GetActivePlayers()
    SendNUIMessage({ action = "updatePlayerCount", players = string.format("%03d", players) })
end

CreateThread(function()
    while true do
        if isLoggedIn then
            UpdateInfoHUD()
            Wait(2000)
        else
            Wait(1000)
        end
    end
end)

-- ====================================================================================
-- [ EVENTS ]
-- ====================================================================================
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    isLoggedIn = true
    
    if PlayerData and PlayerData.metadata then
        hunger = PlayerData.metadata['hunger'] or 100
        thirst = PlayerData.metadata['thirst'] or 100
    end
    InitHUD()
    DisplayRadar(true) -- ✅ เปิดแมพเมื่อโหลดตัวละครเสร็จ
    UpdateInfoHUD() -- ✅ อัปเดตเงินทันทีเมื่อเข้าเกม
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
    hudShown = false
    PlayerData = {}
    SendNUIMessage({ action = "hideHUD" })
    DisplayRadar(false) -- ✅ ปิดแมพทันทีที่กดออกไปหน้าเลือกตัวละคร
end)

RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger, newThirst)
    hunger, thirst = newHunger, newThirst
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
    if val and val.metadata then
        hunger = val.metadata['hunger'] or 100
        thirst = val.metadata['thirst'] or 100
    end
    UpdateInfoHUD() -- ✅ บังคับให้ HUD อัปเดตตัวเลขเงินทันทีไม่ต้องรอลูป
end)

-- ✅ ดักจับ Event ตอนเงินเปลี่ยนโดยเฉพาะ (กันเหนียวสำหรับ QB-Core)
RegisterNetEvent('QBCore:Client:OnMoneyChange', function()
    Wait(100) -- รอระบบหลักบันทึกข้อมูลเสร็จ 0.1 วินาที
    UpdateInfoHUD() -- สั่งอัปเดตเงินบนหน้าจอทันที
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    Wait(1000)
    local data = QBCore.Functions.GetPlayerData()
    if data and data.citizenid then
        PlayerData = data
        isLoggedIn = true
        if PlayerData.metadata then
            hunger = PlayerData.metadata['hunger'] or 100
            thirst = PlayerData.metadata['thirst'] or 100
        end
        InitHUD()
        DisplayRadar(true)
        UpdateInfoHUD()
    end
end)