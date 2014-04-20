-- Change autoUpdate to false if you wish to not receive auto updates.
-- Change silentUpdate to true if you wish not to receive any message regarding updates
local autoUpdate   = true
local silentUpdate = false

local version = 0.005

--[[

    SafeMovement - by TheSource
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

if not VIP_USER then return end

local scriptName = "SafeMovement"

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
    SourceUpdater(scriptName, version, "raw.github.com", "/TheRealSource/public/master/SafeMovement.lua", SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, "/TheRealSource/public/master/SafeMovement.version"):SetSilent(silentUpdate):CheckUpdate()
end


--[[
_________            .___      
\_   ___ \  ____   __| _/____  
/    \  \/ /  _ \ / __ |/ __ \ 
\     \___(  <_> ) /_/ \  ___/ 
 \______  /\____/\____ |\___  >
        \/            \/    \/ 
]]

-- Register advanced callback
AdvancedCallback:register('OnPacketMove')

local menu = nil
local lastSend = 0
local menuText = nil

function OnLoad()

    if not _G.sourceMenu then
        _G.sourceMenu = scriptConfig("[Source] Tools", "sourceTools")
    end
    _G.sourceMenu:addSubMenu(scriptName, scriptName)
    menu = _G.sourceMenu[scriptName]

    menu:addParam("enabled",  "Enabled",                        SCRIPT_PARAM_ONOFF, false)
    menu:addParam("sep",      "",                               SCRIPT_PARAM_INFO,  "")
    menu:addParam("interval", "Movement every x milliseconds",  SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
    menu:addParam("text",     "",                               SCRIPT_PARAM_INFO,  "")

    menuText = menu._param[#menu._param]

    AdvancedCallback:bind("OnPacketMove", OnPacketMove)

    DelayAction(delayedOverride, 2)

end

function OnTick()

    -- Update menu text
    local clicksPerSecond = menu.interval > 0 and math.round(1000 / menu.interval) or "Uncapped"
    menuText.text = " = " .. clicksPerSecond .. " clicks per second"

end

function OnSendPacket(p)

    if p.header == Packet.headers.S_MOVE then
        local packet = Packet(p)
        if packet:get("type") ~= 3 then
            OnPacketMove(p)
        end
    end

end

function OnPacketMove(p)

    if os.clock() * 1000 - lastSend < menu.interval then
        p:Block()
    else
        lastSend = os.clock() * 1000
    end

end

function delayedOverride()

    -- Saving the original SendPacket function for later usage
    _G.OldSendPacket = _G.SendPacket

    -- Overriden packet sending
    _G.SendPacket = function(p)
        if p.header == Packet.headers.S_MOVE then
            local packet = Packet(p)
            if packet:get("type") ~= 3 then
                AdvancedCallback:OnPacketMove(p)
            end
        end
        _G.OldSendPacket(p)
    end

    print("<font color=\"#6699ff\"><b>" .. scriptName .. ":</b></font> <font color=\"#FFFFFF\">SendPacket has beed overriden!</font>")

end