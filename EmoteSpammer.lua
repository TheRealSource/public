-- Change autoUpdate to false if you wish to not receive auto updates.
-- Change silentUpdate to true if you wish not to receive any message regarding updates
local autoUpdate   = true
local silentUpdate = false

local version = 0.001

--[[

    EmoteSpammer - by TheSource
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

local scriptName = "EmoteSpammer"

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
    SourceUpdater(scriptName, version, "raw.github.com", "/TheRealSource/public/master/EmoteSpammer.lua", SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, "/TheRealSource/public/master/EmoteSpammer.version"):SetSilent(silentUpdate):CheckUpdate()
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
local lastEmote = 0

function OnLoad()

    menu = scriptConfig("EmoteSpammer", "emote_spammer")

    menu:addParam("enabled",  "Enabled",             SCRIPT_PARAM_ONOFF, false)
    menu:addParam("sep",      "",                    SCRIPT_PARAM_INFO,  "")
    menu:addParam("mode",     "Spam emotion:",       SCRIPT_PARAM_LIST,  3, { "Taunt", "Joke", "Laugh" })
    menu:addParam("interval", "Interval per second", SCRIPT_PARAM_SLICE, 1, 1, 10, 1)

end

function SendEmote()

    local p = CLoLPacket(71)
    p.pos = 1
    p:EncodeF(player.networkID)
    p:Encode1(menu.mode - 1)
    p:Encode1(0)
    SendPacket(p)

end

function OnSendPacket(p)

    if menu.enabled and p.header == Packet.headers.S_MOVE and os.clock() - lastEmote >= menu.interval then
        lastEmote = os.clock()
        SendEmote()
    end

end

function OnRecvPacket(p)

    if p.header == 65 then
        p.pos = 1
        if p:DecodeF() == player.networkID then
            p:Replace1(255,5)
        end
    end

end
