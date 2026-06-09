local QBCore = exports['qb-core']:GetCoreObject()

-- ส่งจำนวนผู้เล่นออนไลน์ไปให้ Client ที่ร้องขอ
RegisterNetEvent('my-hud:server:requestUpdate', function()
    local src = source
    local totalPlayers = #GetPlayers()
    -- ฟอร์แมตให้เป็น 3 หลัก เช่น 080
    local formattedPlayers = string.format("%03d", totalPlayers)
    
    TriggerClientEvent('my-hud:client:updatePlayerCount', src, formattedPlayers)
end)

-- ====================================================================================
-- [ COMMANDS: /cash & /bank ]
-- ====================================================================================

-- คำสั่ง /cash เช็กเงินสด
QBCore.Commands.Add('cash', 'เช็กจำนวนเงินสดติดตัวของคุณ', {}, false, function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local cash = Player.Functions.GetMoney('cash')
        -- ใส่คอมม่าให้ตัวเลขเงินดูง่ายขึ้น
        local formattedCash = tostring(cash)
        while true do  
            local k
            formattedCash, k = string.gsub(formattedCash, "^(-?%d+)(%d%d%d)", '%1,%2')
            if (k == 0) then break end
        end
        
        TriggerClientEvent('chat:addMessage', src, {
            color = { 0, 255, 0 },
            multiline = true,
            args = { "Cash", "คุณมีเงินสดติดตัวอยู่: ^2$" .. formattedCash .. "^7" }
        })
    end
end)

-- คำสั่ง /bank เช็กเงินในธนาคาร
QBCore.Commands.Add('bank', 'เช็กจำนวนเงินในบัญชีธนาคารของคุณ', {}, false, function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local bank = Player.Functions.GetMoney('bank')
        -- ใส่คอมม่าให้ตัวเลขเงิน
        local formattedBank = tostring(bank)
        while true do  
            local k
            formattedBank, k = string.gsub(formattedBank, "^(-?%d+)(%d%d%d)", '%1,%2')
            if (k == 0) then break end
        end
        
        TriggerClientEvent('chat:addMessage', src, {
            color = { 0, 150, 255 },
            multiline = true,
            args = { "Bank", "คุณมีเงินในบัญชีธนาคารอยู่: ^4$" .. formattedBank .. "^7" }
        })
    end
end)