-- Change autoUpdate to false if you wish to not receive auto updates.
-- Change silentUpdate to true if you wish not to receive any message regarding updates
local autoUpdate   = true
local silentUpdate = false

local version = 0.001

--[[

    KnowYourEnemy - by TheSource
    Copyright (C) 2014 TheSource

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/.

]]

-- Not yet, but it will be after I add packets for wards and stuff :)
--if not VIP_USER then return end

local scriptName = "KnowYourEnemy"

--[[
.____    ._____.     ________                      .__                    .___            
|    |   |__\_ |__   \______ \   ______  _  ______ |  |   _________     __| _/___________ 
|    |   |  || __ \   |    |  \ /  _ \ \/ \/ /    \|  |  /  _ \__  \   / __ |/ __ \_  __ \
|    |___|  || \_\ \  |    `   (  <_> )     /   |  \  |_(  <_> ) __ \_/ /_/ \  ___/|  | \/
|_______ \__||___  / /_______  /\____/ \/\_/|___|  /____/\____(____  /\____ |\___  >__|   
        \/       \/          \/                  \/                \/      \/    \/       
]]

-- SourceLib auto download
local sourceLibFound = true
if FileExist(LIB_PATH .. "SourceLib.lua") then
    require "SourceLib"
else
    sourceLibFound = false
    DownloadFile("https://raw.github.com/TheRealSource/public/master/common/SourceLib.lua", LIB_PATH .. "SourceLib.lua", function() print("<font color=\"#6699ff\"><b>" .. scriptName .. ":</b></font> <font color=\"#FFFFFF\">SourceLib downloaded! Please reload!</font>") end)
end
-- Return if SourceLib has to be downloaded
if not sourceLibFound then return end

-- Updater
if autoUpdate then
    SourceUpdater(scriptName, version, "raw.github.com", "/TheRealSource/public/master/KnowYourEnemy.lua", SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, "/TheRealSource/public/master/KnowYourEnemy.version"):SetSilent(silentUpdate):CheckUpdate()
end


--[[
_________            .___      
\_   ___ \  ____   __| _/____  
/    \  \/ /  _ \ / __ |/ __ \ 
\     \___(  <_> ) /_/ \  ___/ 
 \______  /\____/\____ |\___  >
        \/            \/    \/ 
]]

local defaultColor = {100, 255, 0, 0}
local defaultWidth = 2
local defaultQuality = 30

local visionRadius = 1200
local cachedPoints = {}

local previousQuality = defaultQuality

function OnLoad()

    if not _G.sourceMenu then
        _G.sourceMenu = scriptConfig("[Source] Tools", "sourceTools")
    end
    _G.sourceMenu:addSubMenu(scriptName, scriptName)
    menu = _G.sourceMenu[scriptName]

    menu:addParam("enabled",  "Enabled",                           SCRIPT_PARAM_ONOFF, false)
    menu:addParam("sep",      "",                                  SCRIPT_PARAM_INFO,  "")
    menu:addParam("screen",   "Only draw when enemy on screen",    SCRIPT_PARAM_ONOFF, true)
    menu:addParam("sep",      "",                                  SCRIPT_PARAM_INFO,  "")
    menu:addParam("color",    "Color (also opacity)",              SCRIPT_PARAM_COLOR, defaultColor)
    menu:addParam("width",    "Line width",                        SCRIPT_PARAM_SLICE, defaultWidth, 1, 5, 0)
    menu:addParam("quality",  "Calculation quality",               SCRIPT_PARAM_SLICE, defaultQuality, 10, 100, 0)

end

function OnDraw()

    -- Don't draw when disabled
    if not menu.enabled then return end

    -- Check if quality changed
    if previousQuality ~= menu.quality then
        -- Reset cached points
        cachedPoints = {}
    end

    for _, enemy in ipairs(GetEnemyHeroes()) do
        if enemy.visible then

            -- Enemy on screen check
            if not menu.screen or champOnScreen(enemy) then

                local gridPos = GameHandler:GetGridGameCoordinates(enemy)
                local points = {}
                local pointsFound = false

                for key, value in pairs(cachedPoints) do
                    if key == gridPos then
                        points = value
                        pointsFound = true
                        break
                    end
                end

                if not pointsFound then
                    local x, y, z = gridPos.x, gridPos.y, gridPos.z
                    local quality = 2 * math.pi / menu.quality
                    for theta = 0, 2 * math.pi + quality, quality do
                        local point = D3DXVECTOR3(x + visionRadius * math.cos(theta), y, z - visionRadius * math.sin(theta))
                        for step = 0, visionRadius, 25 do
                            local gamePos = GameHandler:GetGridGameCoordinates(Vector(x + step * math.cos(theta), y, z - step * math.sin(theta)))
                            if isObstacle(gamePos) then                    
                                point = D3DXVECTOR3(gamePos.x, gamePos.y, gamePos.z)
                                break
                            end
                        end
                        points[#points + 1] = point
                    end
                    cachedPoints[gridPos] = points
                end

                -- Calculate world to screen
                local screenPoints = {}
                for _, point in ipairs(points) do
                    c = WorldToScreen(point)
                    screenPoints[#screenPoints + 1] = D3DXVECTOR2(c.x, c.y)
                end

                -- Draw the lines
                if screenPoints and #screenPoints > 0 then
                    DrawLines2(screenPoints, menu.width, TARGB(menu.color))
                end

            end

        end
    end

end

function isObstacle(vector, brush)

    if brush == nil then
        return IsWall(D3DXVECTOR3(vector.x, 0, vector.z)) or IsWallOfGrass(D3DXVECTOR3(vector.x, 0, vector.z))
    elseif brush == false then
        return IsWall(D3DXVECTOR3(vector.x, 0, vector.z))
    else
        return IsWallOfGrass(D3DXVECTOR3(vector.x, 0, vector.z))
    end

end

function champOnScreen(champ)
    local pos = WorldToScreen(D3DXVECTOR3(champ.x, champ.y, champ.z))
    return pos.x <= WINDOW_W and pos.x >= 0 and pos.y >= 0 and pos.y <= WINDOW_H
end
