-- Change autoUpdate to false if you wish to not receive auto updates.
-- Change silentUpdate to true if you wish not to receive any message regarding updates
local autoUpdate   = true
local silentUpdate = false

local version = 0.001

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

local menu = nil
local lastSend = 0

function OnLoad()

    if not _G.sourceMenu then
        _G.sourceMenu = scriptConfig("[Source] Tools", "sourceTools")
    end
    _G.sourceMenu:addSubMenu(scriptName, scriptName)
    menu = _G.sourceMenu[scriptName]

    menu:addParam("enabled",  "Enabled",                  SCRIPT_PARAM_ONOFF, false)
    menu:addParam("sep",      "",                         SCRIPT_PARAM_INFO,  "")
    menu:addParam("interval", "Movement every x seconds", SCRIPT_PARAM_SLICE, 0.2, 0, 1, 1)

end

function OnSendPacket(p)

    if menu.enabled and p.header == Packet.headers.S_MOVE and os.clock() - lastSend >= menu.interval then
        lastSend = os.clock()
    else
        p:Block()
    end

end
