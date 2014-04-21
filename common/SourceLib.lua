-- Change autoUpdate to false if you wish to not receive auto updates.
-- Change silentUpdate to true if you wish not to receive any message regarding updates
local autoUpdate   = true
local silentUpdate = false

local version = 1.054

--[[

      _________                                 .____    ._____.    
     /   _____/ ____  __ _________   ____  ____ |    |   |__\_ |__  
     \_____  \ /  _ \|  |  \_  __ \_/ ___\/ __ \|    |   |  || __ \ 
     /        (  <_> )  |  /|  | \/\  \__\  ___/|    |___|  || \_\ \
    /_______  /\____/|____/ |__|    \___  >___  >_______ \__||___  /
            \/                          \/    \/        \/       \/ 

    SourceLib - a common library by Team TheSource
    Copyright (C) 2014  Team TheSource

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


    Introduction:
        We were tired of updating every single script we developed so far so we decided to have it a little bit
        more dynamic with a custom library which we can update instead and every script using it will automatically
        be updated (of course only the parts which are in this lib). So let's say packet casting get's fucked up
        or we want to change the way some drawing is done, we just need to update it here and all scripts will have
        the same tweaks then.

    Contents:
        Require         -- A basic but powerful library downloader
        SourceUpdater   -- One of the most basic functions for every script we use
        Spell           -- Spells handled the way they should be handled
        DrawManager     -- Easy drawing of all kind of things, comes along with some other classes such as Circle
        DamageLib       -- Calculate the damage done do others and even print it on their healthbar
        STS             -- SimpleTargetSelector is a simple and yet powerful target selector to provide very basic target selecting
        MenuWrapper     -- Easy menu creation with only a few lines
        Interrupter     -- Easy way to handle interruptable spells
        AntiGetcloser   -- Never let them get close to you

]]

-- Temporary here until it's included in BoL itself
if VIP_USER then
    AddBugsplatCallback(function()
        local p = CLoLPacket(0x9B)
        p.dwArg1 = 1
        p.dwArg2 = 0
        p:Encode4(0)
        SendPacket(p)
    end)
end

--[[

'||''|.                              ||                  
 ||   ||    ....    ... .  ... ...  ...  ... ..    ....  
 ||''|'   .|...|| .'   ||   ||  ||   ||   ||' '' .|...|| 
 ||   |.  ||      |.   ||   ||  ||   ||   ||     ||      
.||.  '|'  '|...' '|..'||   '|..'|. .||. .||.     '|...' 
                       ||                                
                      ''''                               

    Require - A simple library downloader

    Introduction:
        If you want to use this class you need to put this at the beginning of you script.
        Example:
            -------------------------------------
            if player.charName ~= "Brand" then return end
            require "SourceLib"

            local libDownloader = Require("Brand script")
            libDownloader:Add("VPrediction", "https://bitbucket.org/honda7/bol/raw/master/Common/VPrediction.lua")
            libDownloader:Add("SOW",         "https://bitbucket.org/honda7/bol/raw/master/Common/SOW.lua")
            libDownloader:Check()

            if libDownloader.downloadNeeded then return end
            -------------------------------------

    Functions:
        Require(myName)

    Members:
        Require.downloadNeeded

    Methods:
        Require:Add(name, url)
        Require:Check()
]]
class 'Require'

function __require_afterDownload(requireInstance)

    requireInstance.downloadCount = requireInstance.downloadCount - 1
    if requireInstance.downloadCount == 0 then
        print("<font color=\"#6699ff\"><b>" .. requireInstance.myName .. ":</b></font> <font color=\"#FFFFFF\">Required libraries downloaded! Please reload!</font>")
    end

end

function Require:__init(myName)

    self.myName = myName or GetCurrentEnv().FILE_NAME
    self.downloadNeeded = false

    self.requirements = {}

end

function Require:Add(name, url)

    assert(name and type(name) == "string" and url and type(url) == "string", "Require:Add(): Some or all arguments are invalid.")
    
    self.requirements[name] = url

    return self

end

function Require:Check()

    for scriptName, scriptUrl in pairs(self.requirements) do
        local scriptFile = LIB_PATH .. scriptName .. ".lua"
        if FileExist(scriptFile) then
            require(scriptName)
        else
            self.downloadNeeded = true
            self.downloadCount = self.downloadCount and self.downloadCount + 1 or 1
            DownloadFile(scriptUrl, scriptFile, function() __require_afterDownload(self) end)
        end
    end

    return self

end


--[[

 .|'''.|                                           '||'  '|'               '||            .                   
 ||..  '    ...   ... ...  ... ..    ....    ....   ||    |  ... ...     .. ||   ....   .||.    ....  ... ..  
  ''|||.  .|  '|.  ||  ||   ||' '' .|   '' .|...||  ||    |   ||'  ||  .'  '||  '' .||   ||   .|...||  ||' '' 
.     '|| ||   ||  ||  ||   ||     ||      ||       ||    |   ||    |  |.   ||  .|' ||   ||   ||       ||     
|'....|'   '|..|'  '|..'|. .||.     '|...'  '|...'   '|..'    ||...'   '|..'||. '|..'|'  '|.'  '|...' .||.    
                                                              ||                                              
                                                             ''''                                             


    SourceUpdater - a simple updater class

    Introduction:
        Scripts that want to use this class need to have a version field at the beginning of the script, like this:
            local version = YOUR_VERSION (YOUR_VERSION can either be a string a a numeric value!)
        It does not need to be exactly at the beginning, like in this script, but it has to be within the first 100
        chars of the file, otherwise the webresult won't see the field, as it gathers only about 100 chars

    Functions:
        SourceUpdater(scriptName, version, host, updatePath, filePath, versionPath)

    Members:
        SourceUpdater.silent | bool | Defines wheather to print notifications or not

    Methods:
        SourceUpdater:SetSilent(silent)
        SourceUpdater:CheckUpdate()

]]
class 'SourceUpdater'

-- Deprecated LazyUpdater
class 'LazyUpdater'
function LazyUpdater:__init(scriptName, version, host, updatePath, filePath, versionPath)
    DelayAction(print(GetCurrentEnv().FILE_NAME .. ": LazyUpdater is deprecated and will be removed soon! Use SourceUpdater instead!"), 10)
    self.updater = SourceUpdater(scriptName, version, host, updatePath, filePath, versionPath)
end
function LazyUpdater:SetSilent(silent)
    self.updater.silent = silent
    return self
end
function LazyUpdater:CheckUpdate()
    self.updater.silent = self.silent
    self.updater:CheckUpdate()
end

--[[
    Create a new instance of SourceUpdater

    @param scriptName  | string        | Name of the script which should be used when printed in chat
    @param version     | float/string  | Current version of the script
    @param host        | string        | Host, for example "bitbucket.org" or "raw.github.com"
    @param updatePath  | string        | Raw path to the script which should be updated
    @param filePath    | string        | Path to the file which should be replaced when updating the script
    @param versionPath | string        | (optional) Path to a version file to check against. The version file may only contain the version.
]]
function SourceUpdater:__init(scriptName, version, host, updatePath, filePath, versionPath)

    self.printMessage = function(message) if not self.silent then print("<font color=\"#6699ff\"><b>" .. self.UPDATE_SCRIPT_NAME .. ":</b></font> <font color=\"#FFFFFF\">" .. message .. "</font>") end end
    self.getVersion = function(version) return tonumber(string.match(version, "%d+%.?%d*")) end

    self.UPDATE_SCRIPT_NAME = scriptName
    self.UPDATE_HOST = host
    self.UPDATE_PATH = updatePath .. "?rand="..math.random(1,10000)
    self.UPDATE_URL = "https://"..self.UPDATE_HOST..self.UPDATE_PATH

    -- Used for version files
    self.VERSION_PATH = versionPath and versionPath .. "?rand="..math.random(1,10000)
    self.VERSION_URL = versionPath and "https://"..self.UPDATE_HOST..self.VERSION_PATH

    self.UPDATE_FILE_PATH = filePath

    self.FILE_VERSION = self.getVersion(version)
    self.SERVER_VERSION = nil

    self.silent = false

end

--[[
    Allows or disallows the updater to print info about updating

    @param  | bool   | Message output or not
    @return | class  | The current instance
]]
function SourceUpdater:SetSilent(silent)

    self.silent = silent
    return self

end

--[[
    Check for an update and downloads it when available
]]
function SourceUpdater:CheckUpdate()

    local webResult = GetWebResult(self.UPDATE_HOST, self.VERSION_PATH or self.UPDATE_PATH)
    if webResult then
        if self.VERSION_PATH then
            self.SERVER_VERSION = webResult
        else
            self.SERVER_VERSION = string.match(webResult, "%s*local%s+version%s+=%s+.*%d+%.%d+")
        end
        if self.SERVER_VERSION then
            self.SERVER_VERSION = self.getVersion(self.SERVER_VERSION)
            if self.FILE_VERSION < self.SERVER_VERSION then
                self.printMessage("New version available: v" .. self.SERVER_VERSION)
                self.printMessage("Updating, please don't press F9")
                DelayAction(function () DownloadFile(self.UPDATE_URL, self.UPDATE_FILE_PATH, function () self.printMessage("Successfully updated, please reload!") end) end, 2)
            else
                self.printMessage("You've got the latest version: v" .. self.SERVER_VERSION)
            end
        else
            self.printMessage("Something went wrong! Please manually update the script!")
        end
    else
        self.printMessage("Error downloading version info!")
    end

end


--[[

 .|'''.|                   '||  '||  
 ||..  '  ... ...    ....   ||   ||  
  ''|||.   ||'  || .|...||  ||   ||  
.     '||  ||    | ||       ||   ||  
|'....|'   ||...'   '|...' .||. .||. 
           ||                        
          ''''                       

    Spell - Handled with ease!

    Functions:
        Spell(spellId, range, packetCast)

    Members:
        Spell.range          | float  | Range of the spell, please do NOT change this value, use Spell:SetRange() instead
        Spell.rangeSqr       | float  | Squared range of the spell, please do NOT change this value, use Spell:SetRange() instead
        Spell.packetCast     | bool   | Set packet cast state
        -- This only applies for skillshots
        Spell.sourcePosition | vector | From where the spell is casted, default: player
        Spell.sourceRange    | vector | From where the range should be calculated, default: player
        -- This only applies for AOE skillshots
        Spell.minTargetsAoe  | int    | Set minimum targets for AOE damage

    Methods:
        Spell:SetRange(range)
        Spell:SetSource(source)
        Spell:SetSourcePosition(source)
        Spell:SetSourceRange(source)

        Spell:SetSkillshot(VP, skillshotType, width, delay, speed, collision)
        Spell:SetAOE(useAoe, radius, minTargetsAoe)

        Spell:SetCharged(spellName, chargeDuration, maxRange, timeToMaxRange, abortCondition)
        Spell:IsCharging()
        Spell:Charge()

        Spell:SetHitChance(hitChance)
        Spell:ValidTarget(target)

        Spell:GetPrediction(target)
        Spell:CastIfDashing(target)
        Spell:CastIfImmobile(target)
        Spell:Cast(param1, param2)

        Spell:AddAutomation(automationId, func)
        Spell:RemoveAutomation(automationId)
        Spell:ClearAutomations()

        Spell:TrackCasting(spellName)
        Spell:WillHitTarget()
        Spell:RegisterCastCallback(func)

        Spell:GetLastCastTime()

        Spell:IsInRange(target, from)
        Spell:IsReady()
        Spell:GetManaUsage()
        Spell:GetCooldown()
        Spell:GetLevel()
        Spell:GetName()

]]
class 'Spell'

-- Class related constants
SKILLSHOT_LINEAR   = 0
SKILLSHOT_CIRCULAR = 1
SKILLSHOT_CONE     = 2

-- Different SpellStates returned when Spell:Cast() is called
SPELLSTATE_TRIGGERED          = 0
SPELLSTATE_OUT_OF_RANGE       = 1
SPELLSTATE_LOWER_HITCHANCE    = 2
SPELLSTATE_COLLISION          = 3
SPELLSTATE_NOT_ENOUGH_TARGETS = 4
SPELLSTATE_NOT_DASHING        = 5
SPELLSTATE_DASHING_CANT_HIT   = 6
SPELLSTATE_NOT_IMMOBILE       = 7
SPELLSTATE_INVALID_TARGET     = 8
SPELLSTATE_NOT_TRIGGERED      = 9

-- Spell identifier number used for comparing spells
local spellNum = 1

--[[
    New instance of Spell

    @param spellId    | int   | Spell ID (_Q, _W, _E, _R)
    @param range      | float | Range of the spell
    @param packetCast | bool  | (optional) Enable packet casting
]]
function Spell:__init(spellId, range, packetCast)

    assert(spellId ~= nil and range ~= nil and type(spellId) == "number" and type(range) == "number", "Spell: Can't initialize Spell without valid arguments.")

    self.spellId = spellId
    self:SetRange(range)
    self.packetCast = packetCast or false

    self:SetSource(player)

    self._automations = {}

    self._spellNum = spellNum
    spellNum = spellNum + 1

end

--[[
    Update the spell range with the new given value

    @param range | float | Range of the spell
    @return      | class | The current instance
]]
function Spell:SetRange(range)

    assert(range and type(range) == "number", "Spell: range is invalid")

    self.range = range
    self.rangeSqr = math.pow(range, 2)

    return self

end

--[[
    Update both the sourcePosition and sourceRange from where everything will be calculated

    @param source | Cunit | Source position, for example player
    @return       | class | The current instance
]]
function Spell:SetSource(source)

    assert(source, "Spell: source can't be nil!")

    self.sourcePosition = source
    self.sourceRange    = source

    return self

end

--[[
    Update the source posotion from where the spell will be shot

    @param source | Cunit | Source position from where the spell will be shot, player by default
    @ return      | class | The current instance
]]
function Spell:SetSourcePosition(source)

    assert(source, "Spell: source can't be nil!")

    self.sourcePosition = source

    return self

end

--[[
    Update the source unit from where the range will be calculated

    @param source | Cunit | Source object unit from where the range should be calculed
    @return       | class | The current instance
]]
function Spell:SetSourceRange(source)

    assert(source, "Spell: source can't be nil!")

    self.sourceRange = source

    return self

end

--[[
    Define this spell as skillshot (can't be reversed)

    @param VP            | class | Instance of VPrediction
    @param skillshotType | int   | Type of this skillshot
    @param width         | float | Width of the skillshot
    @param delay         | float | (optional) Delay in seconds
    @param speed         | float | (optional) Speed in units per second
    @param collision     | bool  | (optional) Respect unit collision when casting
    @rerurn              | class | The current instance
]]
function Spell:SetSkillshot(VP, skillshotType, width, delay, speed, collision)

    assert(skillshotType ~= nil, "Spell: Need at least the skillshot type!")

    self.VP = VP
    self.skillshotType = skillshotType
    self.width = width or 0
    self.delay = delay or 0
    self.speed = speed
    self.collision = collision

    if not self.hitChance then self.hitChance = 2 end

    return self

end

--[[
    Set the AOE status of this spell, this can be changed later

    @param useAoe        | bool  | New AOE state
    @param radius        | float | Radius of the AOE damage
    @param minTargetsAoe | int   | Minimum targets to be hitted by the AOE damage
    @rerurn              | class | The current instance
]]
function Spell:SetAOE(useAoe, radius, minTargetsAoe)

    self.useAoe = useAoe or false
    self.radius = radius or self.width
    self.minTargetsAoe = minTargetsAoe or 0

    return self

end

--[[
    Define this spell as charged spell

    @param spellName      | string   | Name of the spell, example: VarusQ
    @param chargeDuration | float    | Seconds of the spell to charge, after the time the charge expires
    @param maxRage        | float    | Max range the spell will have after fully charging
    @param timeToMaxRange | float    | Time in seconds to reach max range after casting the spell
    @param abortCondition | function | (optional) A function which returns true when the charge process should be stopped.
]]
function Spell:SetCharged(spellName, chargeDuration, maxRange, timeToMaxRange, abortCondition)

    assert(self.skillshotType, "Spell:SetCharged(): Only skillshots can be defined as charged spells!")
    assert(spellName and type(spellName) == "string" and chargeDuration and type(chargeDuration) == "number", "Spell:SetCharged(): Some or all arguments are invalid!")
    assert(self.__charged == nil, "Spell:SetCharged(): Already marked as charged spell!")

    self.__charged           = true
    self.__charged_aborted   = true
    self.__charged_spellName = spellName
    self.__charged_duration  = chargeDuration

    self.__charged_maxRange       = maxRange
    self.__charged_chargeTime     = timeToMaxRange
    self.__charged_abortCondition = abortCondition or function () return false end

    self.__charged_active   = false
    self.__charged_castTime = 0

    -- Register callbacks
    if not self.__tickCallback then
        AddTickCallback(function() self:OnTick() end)
        self.__tickCallback = true
    end

    if not self.__sendPacketCallback then
        AddSendPacketCallback(function(p) self:OnSendPacket(p) end)
        self.__sendPacketCallback = true
    end

    if not self.__processSpellCallback then
        AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
        self.__processSpellCallback = true
    end

    return self

end

--[[
    Returns whether the spell is currently charging or not

    @return | bool | Spell charging or not
]]
function Spell:IsCharging()
    return self.__charged_abortCondition() == false and self.__charged_active
end

--[[
    Charges the spell
]]
function Spell:Charge()

    assert(self.__charged, "Spell:Charge(): Spell is not defined as chargeable spell!")

    if not self:IsCharging() then
        Packet("S_CAST", {spellId = self.spellId}):send()
    end

end

-- Internal function, do not use!
function Spell:_AbortCharge()
    if self.__charged and self.__charged_active then
        self.__charged_aborted = true
        self.__charged_active  = false
        self:SetRange(self.__charged_initialRange)
    end
end

--[[
    Set the hitChance of the predicted target position when to cast

    @param hitChance | int   | New hitChance for predicted positions
    @rerurn          | class | The current instance
]]
function Spell:SetHitChance(hitChance)

    self.hitChance = hitChance or 2

    return self

end

--[[
    Checks if the given target is valid for the spell

    @param target | userdata | Target to be checked if valid
    @return       | bool     | Valid target or not
]]
function Spell:ValidTarget(target, range)

    return ValidTarget(target, range or self.range)

end

--[[
    Returns the prediction results from VPrediction to use for custom reasons

    @return | various data | The original result from VPrediction
]]
function Spell:GetPrediction(target)

    if self.skillshotType ~= nil then
        if self.skillshotType == SKILLSHOT_LINEAR then
            if self.useAoe then
                return self.VP:GetLineAOECastPosition(target, self.delay, self.radius, self.range, self.speed, self.sourcePosition)
            else
                return self.VP:GetLineCastPosition(target, self.delay, self.width, self.range, self.speed, self.sourcePosition, self.collision)
            end
        elseif self.skillshotType == SKILLSHOT_CIRCULAR then
            if self.useAoe then
                return self.VP:GetCircularAOECastPosition(target, self.delay, self.radius, self.range, self.speed, self.sourcePosition)
            else
                return self.VP:GetCircularCastPosition(target, self.delay, self.width, self.range, self.speed, self.sourcePosition, self.collision)
            end
         elseif self.skillshotType == SKILLSHOT_CONE then
            if self.useAoe then
                return self.VP:GetConeAOECastPosition(target, self.delay, self.radius, self.range, self.speed, self.sourcePosition)
            else
                return self.VP:GetLineCastPosition(target, self.delay, self.width, self.range, self.speed, self.sourcePosition, self.collision)
            end
        end
    end

end

--[[
    Tries to cast the spell when the target is dashing

    @param target | Cunit | Dashing target to attack
    @param return | int   | SpellState of the current spell
]]
function Spell:CastIfDashing(target)

    -- Don't calculate stuff when target is invalid
    if not ValidTarget(target) then return SPELLSTATE_INVALID_TARGET end

    if self.skillshotType ~= nil then
        local isDashing, canHit, position = self.VP:IsDashing(target, self.delay + 0.07 + GetLatency() / 2000, self.width, self.speed, self.sourcePosition)

        -- Out of range
        if self.rangeSqr < _GetDistanceSqr(self.sourceRange, position) then return SPELLSTATE_OUT_OF_RANGE end

        if isDashing and canHit then

            -- Collision
            if not self.collision or self.collision and not self.VP:CheckMinionCollision(target, position, self.delay + 0.07 + GetLatency() / 2000, self.width, self.range, self.speed, self.sourcePosition, false, true) then
                return self:__Cast(self.spellId, position.x, position.z)
            else
                return SPELLSTATE_COLLISION
            end

        elseif not isDashing then return SPELLSTATE_NOT_DASHING
        else return SPELLSTATE_DASHING_CANT_HIT end
    else
        local isDashing, canHit, position = self.VP:IsDashing(target, 0.25 + 0.07 + GetLatency() / 2000, 1, math.huge, self.sourcePosition)

        -- Out of range
        if self.rangeSqr < _GetDistanceSqr(self.sourceRange, position) then return SPELLSTATE_OUT_OF_RANGE end

        if isDashing and canHit then
            return self:__Cast(position.x, position.z)
        elseif not isDashing then return SPELLSTATE_NOT_DASHING
        else return SPELLSTATE_DASHING_CANT_HIT end
    end

    return SPELLSTATE_NOT_TRIGGERED

end

--[[
    Tries to cast the spell when the target is immobile

    @param target | Cunit | Immobile target to attack
    @param return | int   | SpellState of the current spell
]]
function Spell:CastIfImmobile(target)

    -- Don't calculate stuff when target is invalid
    if not ValidTarget(target) then return SPELLSTATE_INVALID_TARGET end

    if self.skillshotType ~= nil then
        local isImmobile, position = self.VP:IsImmobile(target, self.delay + 0.07 + GetLatency() / 2000, self.width, self.speed, self.sourcePosition)

        -- Out of range
        if self.rangeSqr < _GetDistanceSqr(self.sourceRange, position) then return SPELLSTATE_OUT_OF_RANGE end

        if isImmobile then

            -- Collision
            if not self.collision or (self.collision and not self.VP:CheckMinionCollision(target, position, self.delay + 0.07 + GetLatency() / 2000, self.width, self.range, self.speed, self.sourcePosition, false, true)) then
                return self:__Cast(position.x, position.z)
            else
                return SPELLSTATE_COLLISION
            end

        else return SPELLSTATE_NOT_IMMOBILE end
    else
        local isImmobile, position = self.VP:IsImmobile(target, 0.25 + 0.07 + GetLatency() / 2000, 1, math.huge, self.sourcePosition)

        -- Out of range
        if self.rangeSqr < _GetDistanceSqr(self.sourceRange, target) then return SPELLSTATE_OUT_OF_RANGE end

        if isImmobile then
            return self:__Cast(target)
        else
            return SPELLSTATE_NOT_IMMOBILE
        end
    end

    return SPELLSTATE_NOT_TRIGGERED

end

--[[
    Cast the spell, respecting previously made decisions about skillshots and AOE stuff

    @param param1 | userdata/float | When param2 is nil then this can be the target object, otherwise this is the X coordinate of the skillshot position
    @param param2 | float          | Z coordinate of the skillshot position
    @param return | int            | SpellState of the current spell
]]
function Spell:Cast(param1, param2)

    if self.skillshotType ~= nil and param1 ~= nil and param2 == nil then

        -- Don't calculate stuff when target is invalid
        if not ValidTarget(param1) then return SPELLSTATE_INVALID_TARGET end

        local castPosition, hitChance, position, nTargets
        if self.skillshotType == SKILLSHOT_LINEAR or self.skillshotType == SKILLSHOT_CONE then
            if self.useAoe then
                castPosition, hitChance, nTargets = self:GetPrediction(param1)
            else
                castPosition, hitChance, position = self:GetPrediction(param1)
                -- Out of range
                if self.rangeSqr < _GetDistanceSqr(self.sourceRange, position) then return SPELLSTATE_OUT_OF_RANGE end
            end
        elseif self.skillshotType == SKILLSHOT_CIRCULAR then
            if self.useAoe then
                castPosition, hitChance, nTargets = self:GetPrediction(param1)
            else
                castPosition, hitChance, position = self:GetPrediction(param1)
                -- Out of range
                if math.pow(self.range + self.width + self.VP:GetHitBox(param1), 2) < _GetDistanceSqr(self.sourceRange, position) then return SPELLSTATE_OUT_OF_RANGE end
            end
        end

        -- AOE not enough targets
        if nTargets and nTargets < self.minTargetsAoe then return SPELLSTATE_NOT_ENOUGH_TARGETS end

        -- Collision detected
        if hitChance == -1 then return SPELLSTATE_COLLISION end

        -- Hitchance too low
        if hitChance and hitChance < self.hitChance then return SPELLSTATE_LOWER_HITCHANCE end

        -- Out of range
        if self.rangeSqr < _GetDistanceSqr(self.sourceRange, castPosition) then return SPELLSTATE_OUT_OF_RANGE end

        param1 = castPosition.x
        param2 = castPosition.z
    end

    -- Cast the spell
    return self:__Cast(param1, param2)

end

--[[
    Internal function, do not use this!
]]
function Spell:__Cast(param1, param2)

    if self.packetCast then
        if param1 ~= nil and param2 ~= nil then
            Packet("S_CAST", {spellId = self.spellId, toX = param1, toY = param2, fromX = param1, fromY = param2}):send()
        elseif param1 ~= nil then
            Packet("S_CAST", {spellId = self.spellId, toX = param1.x, toY = param1.z, fromX = param1.x, fromY = param1.z, targetNetworkId = param1.networkID}):send()
        else
            Packet("S_CAST", {spellId = self.spellId, toX = player.x, toY = player.z, fromX = player.x, fromY = player.z, targetNetworkId = player.networkID}):send()
        end
    else
        if param1 ~= nil and param2 ~= nil then
            CastSpell(self.spellId, param1, param2)
        elseif param1 ~= nil then
            CastSpell(self.spellId, param1)
        else
            CastSpell(self.spellId)
        end
    end

    return SPELLSTATE_TRIGGERED

end

--[[
    Add an automation to the spell to let it cast itself when a certain condition is met

    @param automationId | string/int | The ID of the automation, example "AntiGapCloser"
    @param func         | function   | Function to be called when checking, should return a bool value indicating if it should be casted and optionally the cast params (ex: target or x and z)
]]
function Spell:AddAutomation(automationId, func)

    assert(automationId, "Spell: automationId is invalid!")
    assert(func and type(func) == "function", "Spell: func is invalid!")

    for index, automation in ipairs(self._automations) do
        if automation.id == automationId then return end
    end

    table.insert(self._automations, { id == automationId, func = func })

    -- Register callbacks
    if not self.__tickCallback then
        AddTickCallback(function() self:OnTick() end)
        self.__tickCallback = true
    end

end

--[[
    Remove and automation by it's id

    @param automationId | string/int | The ID of the automation, example "AntiGapCloser"
]]
function Spell:RemoveAutomation(automationId)

    assert(automationId, "Spell: automationId is invalid!")

    for index, automation in ipairs(self._automations) do
        if automation.id == automationId then
            table.remove(self._automations, index)
            break
        end
    end

end

--[[
    Clear all automations assinged to this spell
]]
function Spell:ClearAutomations()
    self._automations = {}
end

--[[
    Track the spell like in OnProcessSpell to add more features to this Spell instance

    @param spellName | string/table | Case insensitive name(s) of the spell
    @return          | class        | The current instance
]]
function Spell:TrackCasting(spellName)

    assert(spellName, "Spell:TrackCasting(): spellName is invalid!")
    assert(self.__tracked_spellNames == nil, "Spell:TrackCasting(): This spell is already tracked!")
    assert(type(spellName) == "string" or type(spellName) == "table", "Spell:TrackCasting(): Type of spellName is invalid: " .. type(spellName))

    self.__tracked_spellNames = type(spellName) == "table" and spellName or { spellName }

    -- Register callbacks
    if not self.__processSpellCallback then
        AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
        self.__processSpellCallback = true
    end

    return self

end

--[[
    When the spell is casted and about to hit a target, this will return the following

    @return | CUnit,float | The target unit, the remaining time in seconds it will take to hit the target, otherwise nil
]]
function Spell:WillHitTarget()

    -- TODO: VPrediction expert's work ;D

end

--[[
    Register a function which will be triggered when the spell is being casted the function will be given the spell object as parameter

    @param func | function | Function to be called when the spell is being processed (casted)
]]
function Spell:RegisterCastCallback(func)

    assert(func and type(func) == "function" and self.__tracked_castCallback == nil, "Spell:RegisterCastCallback(): func is either invalid or a callback is already registered!")

    self.__tracked_castCallback = func

end

--[[
    Returns the os.clock() time when the spell was last casted

    @return | float | Time in seconds when the spell was last casted or nil if the spell was never casted or spell is not tracked
]]
function Spell:GetLastCastTime()
    return self.__tracked_lastCastTime or 0
end

--[[
    Get if the target is in range

    @return | bool | In range or not
]]
function Spell:IsInRange(target, from)
    return self.rangeSqr >= _GetDistanceSqr(target, from or self.sourcePosition)
end

--[[
    Get if the spell is ready or not

    @return | bool | Spell state ready or not
]]
function Spell:IsReady()
    return player:CanUseSpell(self.spellId) == READY
end

--[[
    Get the mana usage of the spell

    @return | float | Mana usage of the spell
]]
function Spell:GetManaUsage()
    return player:GetSpellData(self.spellId).mana
end

--[[
    Get the CURRENT cooldown of the spell

    @return | float | Current cooldown of the spell
]]
function Spell:GetCooldown(current)
    return current and player:GetSpellData(self.spellId).currentCd or player:GetSpellData(self.spellId).totalCooldown
end

--[[
    Get the stat points assinged to this spell (level)

    @return | int | Stat points assinged to this spell (level)
]]
function Spell:GetLevel()
    return player:GetSpellData(self.spellId).level
end

--[[
    Get the name of the spell

    @return | string | Name of the the spell
]]
function Spell:GetName()
    return player:GetSpellData(self.spellId).name
end

--[[
    Internal callback, don't use this!
]]
function Spell:OnTick()

    -- Automations
    if self._automations and #self._automations > 0 then
        for _, automation in ipairs(self._automations) do
            local doCast, param1, param2 = automation.func()
            if doCast == true then
                self:Cast(param1, param2)
            end
        end
    end

    -- Charged spells
    if self.__charged then
        if self:IsCharging() then
            self:SetRange(math.min(self.__charged_initialRange + (self.__charged_maxRange - self.__charged_initialRange) * ((os.clock() - self.__charged_castTime) / self.__charged_chargeTime), self.__charged_maxRange))
        elseif not self.__charged_aborted and os.clock() - self.__charged_castTime > 0.1 then
            self:_AbortCharge()
        end
    end

end

--[[
    Internal callback, don't use this!
]]
function Spell:OnProcessSpell(unit, spell)

    if unit and unit.valid and unit.isMe and spell and spell.name then

        -- Tracked spells
        if self.__tracked_spellNames then
            for _, trackedSpell in ipairs(self.__tracked_spellNames) do
                if trackedSpell:lower() == spell.name:lower() then
                    self.__tracked_lastCastTime = os.clock()
                    self.__tracked_castCallback(spell)
                end
            end
        end

        -- Charged spells
        if self.__charged and self.__charged_spellName:lower() == spell.name:lower() then
            self.__charged_active       = true
            self.__charged_aborted      = false
            self.__charged_initialRange = self.range
            self.__charged_castTime     = os.clock()
            self.__charged_count        = self.__charged_count and self.__charged_count + 1 or 1
            DelayAction(function(chargeCount)
                if self.__charged_count == chargeCount then
                    self:_AbortCharge()
                end
            end, self.__charged_duration, { self.__charged_count })
        end

    end

end

--[[
    Internal callback, don't use this!
]]
function Spell:OnSendPacket(p)

    -- Charged spells
    if self.__charged then
        if p.header == 229 then
            if os.clock() - self.__charged_castTime <= 0.1 then
                p:Block()
            end
        elseif p.header == Packet.headers.S_CAST then
            local packet = Packet(p)
            if packet:get("spellId") == self.spellId then
                if os.clock() - self.__charged_castTime <= self.__charged_duration then
                    self:_AbortCharge()
                    local newPacket = CLoLPacket(229)
                    newPacket:EncodeF(player.networkID)
                    newPacket:Encode1(0x80)
                    newPacket:EncodeF(mousePos.x)
                    newPacket:EncodeF(mousePos.y)
                    newPacket:EncodeF(mousePos.z)
                    SendPacket(newPacket)
                    p:Block()
                end
            end
        end
    end

end

function Spell:__eq(other)

    return other and other._spellNum and other._spellNum == self._spellNum or false

end


--[[

'||''|.                               '||    ||'                                                  
 ||   ||  ... ..   ....   ... ... ...  |||  |||   ....   .. ...    ....     ... .   ....  ... ..  
 ||    ||  ||' '' '' .||   ||  ||  |   |'|..'||  '' .||   ||  ||  '' .||   || ||  .|...||  ||' '' 
 ||    ||  ||     .|' ||    ||| |||    | '|' ||  .|' ||   ||  ||  .|' ||    |''   ||       ||     
.||...|'  .||.    '|..'|'    |   |    .|. | .||. '|..'|' .||. ||. '|..'|'  '||||.  '|...' .||.    
                                                                          .|....'                 

    DrawManager - Tired of having to draw everything over and over again? Then use this!

    Functions:
        DrawManager()

    Methods:
        DrawManager:AddCircle(circle)
        DrawManager:RemoveCircle(circle)
        DrawManager:CreateCircle(position, radius, width, color)
        DrawManager:OnDraw()

]]
class 'DrawManager'

--[[
    New instance of DrawManager
]]
function DrawManager:__init()

    self.objects = {}

    AddDrawCallback(function() self:OnDraw() end)

end

--[[
    Add an existing circle to the draw manager

    @param circle | class | _Circle instance
]]
function DrawManager:AddCircle(circle)

    assert(circle, "DrawManager: circle is invalid!")

    for _, object in ipairs(self.objects) do
        assert(object ~= circle, "DrawManager: object was already in DrawManager")
    end

    table.insert(self.objects, circle)

end

--[[
    Removes a circle from the draw manager

    @param circle | class | _Circle instance
]]
function DrawManager:RemoveCircle(circle)

    assert(circle, "DrawManager:RemoveCircle(): circle is invalid!")

    for index, object in ipairs(self.objects) do
        if object == circle then
            table.remove(self.objects, index)
        end
    end

end

--[[
    Create a new circle and add it aswell to the DrawManager instance

    @param position | vector | Center of the circle
    @param radius   | float  | Radius of the circle
    @param width    | int    | Width of the circle outline
    @param color    | table  | Color of the circle in a tale format { a, r, g, b }
    @return         | class  | Instance of the newly create Circle class
]]
function DrawManager:CreateCircle(position, radius, width, color)

    local circle = _Circle(position, radius, width, color)
    self:AddCircle(circle)
    return circle

end

--[[
    DO NOT CALL THIS MANUALLY! This will be called automatically.
]]
function DrawManager:OnDraw()

    for _, object in ipairs(self.objects) do
        if object.enabled then
            object:Draw()
        end
    end

end

--[[

                  ..|'''.|  ||                  '||          
                .|'     '  ...  ... ..    ....   ||    ....  
                ||          ||   ||' '' .|   ''  ||  .|...|| 
                '|.      .  ||   ||     ||       ||  ||      
                 ''|....'  .||. .||.     '|...' .||.  '|...' 

    Functions:
        _Circle(position, radius, width, color)

    Members:
        _Circle.enabled  | bool   | Enable or diable the circle (displayed)
        _Circle.mode     | int    | See circle modes below
        _Circle.position | vector | Center of the circle
        _Circle.radius   | float  | Radius of the circle
        -- These are not changeable when a menu is set
        _Circle.width    | int    | Width of the circle outline
        _Circle.color    | table  | Color of the circle in a tale format { a, r, g, b }
        _Circle.quality  | float  | Quality of the circle, the higher the smoother the circle

    Methods:
        _Circle:AddToMenu(menu, paramText, addColor, addWidth, addQuality)
        _Circle:SetEnabled(enabled)
        _Circle:Set2D()
        _Circle:Set3D()
        _Circle:SetMinimap()
        _Circle:SetQuality(qualtiy)
        _Circle:SetDrawCondition(condition)
        _Circle:LinkWithSpell(spell, drawWhenReady)
        _Circle:Draw()

]]
class '_Circle'

-- Circle modes
CIRCLE_2D      = 0
CIRCLE_3D      = 1
CIRCLE_MINIMAP = 2

-- Number of currently created circles
local circleCount = 1

--[[
    New instance of Circle

    @param position | vector | Center of the circle
    @param radius   | float  | Radius of the circle
    @param width    | int    | Width of the circle outline
    @param color    | table  | Color of the circle in a tale format { a, r, g, b }
]]
function _Circle:__init(position, radius, width, color)

    assert(position and position.x and (position.y and position.z or position.y), "_Circle: position is invalid!")
    assert(radius and type(radius) == "number", "_Circle: radius is invalid!")
    assert(not color or color and type(color) == "table" and #color == 4, "_Circle: color is invalid!")

    self.enabled   = true
    self.condition = nil

    self.menu        = nil
    self.menuEnabled = nil
    self.menuColor   = nil
    self.menuWidth   = nil
    self.menuQuality = nil

    self.mode = CIRCLE_3D

    self.position = position
    self.radius   = radius
    self.width    = width or 1
    self.color    = color or { 255, 255, 255, 255 }
    self.quality  = radius / 5

    self._circleId  = "circle" .. circleCount
    self._circleNum = circleCount

    circleCount = circleCount + 1

end

--[[
    Adds this circle to a given menu

    @param menu       | scriptConfig | Instance of script config to add this circle to
    @param paramText  | string       | Text for the menu entry
    @param addColor   | bool         | Add color option
    @param addWidth   | bool         | Add width option
    @param addQuality | bool         | Add quality option
    @return           | class        | The current instance
]]
function _Circle:AddToMenu(menu, paramText, addColor, addWidth, addQuality)

    assert(menu, "_Circle: menu is invalid!")
    assert(self.menu == nil, "_Circle: Already bound to a menu!")

    menu:addSubMenu(paramText or "Circle " .. self._circleNum, self._circleId)
    self.menu = menu[self._circleId]

    -- Enabled
    local paramId = self._circleId .. "enabled"
    self.menu:addParam(paramId, "Enabled", SCRIPT_PARAM_ONOFF, self.enabled)
    self.menuEnabled = self.menu._param[#self.menu._param]

    if addColor or addWidth or addQuality then

        -- Color
        if addColor then
            paramId = self._circleId .. "color"
            self.menu:addParam(paramId, "Color", SCRIPT_PARAM_COLOR, self.color)
            self.menuColor = self.menu._param[#self.menu._param]
        end

        -- Width
        if addWidth then
            paramId = self._circleId .. "width"
            self.menu:addParam(paramId, "Width", SCRIPT_PARAM_SLICE, self.width, 1, 5)
            self.menuWidth = self.menu._param[#self.menu._param]
        end

        -- Quality
        if addQuality then
            paramId = self._circleId .. "quality"
            self.menu:addParam(paramId, "Quality", SCRIPT_PARAM_SLICE, math.round(self.quality), 10, math.round(self.radius / 5))
            self.menuQuality = self.menu._param[#self.menu._param]
        end

    end

    return self

end

--[[
    Set the enable status of the circle

    @param enabled | bool  | Enable state of this circle
    @return        | class | The current instance
]]
function _Circle:SetEnabled(enabled)

    self.enabled = enabled
    return self

end

--[[
    Set this circle to be displayed 2D

    @return | class | The current instance
]]
function _Circle:Set2D()

    self.mode = CIRCLE_2D
    return self

end

--[[
    Set this circle to be displayed 3D

    @return | class | The current instance
]]
function _Circle:Set3D()

    self.mode = CIRCLE_3D
    return self

end

--[[
    Set this circle to be displayed on the minimap

    @return | class | The current instance
]]
function _Circle:SetMinimap()

    self.mode = CIRCLE_MINIMAP
    return self

end

--[[
    Set the display quality of this circle

    @return | class | The current instance
]]
function _Circle:SetQuality(qualtiy)

    assert(qualtiy and type(qualtiy) == "number", "_Circle: quality is invalid!")
    self.quality = quality
    return self

end

--[[
    Set the draw condition of this circle

    @return | class | The current instance
]]
function _Circle:SetDrawCondition(condition)

    assert(condition and type(condition) == "function", "_Circle: condition is invalid!")
    self.condition = condition
    return self

end

--[[
    Links the spell range with the circle radius

    @param spell         | class | Instance of Spell class
    @param drawWhenReady | bool  | Decides whether to draw the circle when the spell is ready or not
    @return              | class | The current instance
]]
function _Circle:LinkWithSpell(spell, drawWhenReady)

    assert(spell, "_Circle:LinkWithSpell(): spell is invalid")
    self._linkedSpell = spell
    self._linkedSpellReady = drawWhenReady or false
    return self

end

--[[
    Draw this circle, should only be called from OnDraw()
]]
function _Circle:Draw()

    -- Don't draw if condition is not met
    if self.condition ~= nil and self.condition() == false then return end

    -- Update values if linked spell is given
    if self._linkedSpell then
        if self._linkedSpellReady and not self._linkedSpell:IsReady() then return end
        -- Update the radius with the spell range
        self.radius = self._linkedSpell.range
    end

    -- Menu found
    if self.menu then 
        if self.menuEnabled ~= nil then
            if not self.menu[self.menuEnabled.var] then return end
        end
        if self.menuColor ~= nil then
            self.color = self.menu[self.menuColor.var]
        end
        if self.menuWidth ~= nil then
            self.width = self.menu[self.menuWidth.var]
        end
        if self.menuQuality ~= nil then
            self.quality = self.menu[self.menuQuality.var]
        end
    end

    local center = WorldToScreen(D3DXVECTOR3(self.position.x, self.position.y, self.position.z))
    if not self:PointOnScreen(center.x, center.y) and self.mode ~= CIRCLE_MINIMAP then
        return
    end

    if self.mode == CIRCLE_2D then
        DrawCircle2D(self.position.x, self.position.y, self.radius, self.width, TARGB(self.color), self.quality)
    elseif self.mode == CIRCLE_3D then
        DrawCircle3D(self.position.x, self.position.y, self.position.z, self.radius, self.width, TARGB(self.color), self.quality)
    elseif self.mode == CIRCLE_MINIMAP then
        DrawCircleMinimap(self.position.x, self.position.y, self.position.z, self.radius, self.width, TARGB(self.color), self.quality)
    else
        print("Circle: Something is wrong with the circle.mode!")
    end

end

function _Circle:PointOnScreen(x, y)
    return x <= WINDOW_W and x >= 0 and y >= 0 and y <= WINDOW_H
end

function _Circle:__eq(other)
    return other._circleId and other._circleId == self._circleId or false
end

--[[

'||''|.                                              '||'       ||  '||      
 ||   ||   ....   .. .. ..    ....     ... .   ....   ||       ...   || ...  
 ||    || '' .||   || || ||  '' .||   || ||  .|...||  ||        ||   ||'  || 
 ||    || .|' ||   || || ||  .|' ||    |''   ||       ||        ||   ||    | 
.||...|'  '|..'|' .|| || ||. '|..'|'  '||||.  '|...' .||.....| .||.  '|...'  
                                     .|....'                                 

    DamageLib - Holy cow, so precise!

    Functions:
        DamageLib(source)

    Members:
        DamageLib.source | Cunit | Source unit for which the damage should be calculated

    Methods:
        DamageLib:RegisterDamageSource(spellId, damagetype, basedamage, perlevel, scalingtype, scalingstat, percentscaling, condition, extra)
        DamageLib:GetScalingDamage(target, scalingtype, scalingstat, percentscaling)
        DamageLib:GetTrueDamage(target, spell, damagetype, basedamage, perlevel, scalingtype, scalingstat, percentscaling, condition, extra)
        DamageLib:CalcSpellDamage(target, spell)
        DamageLib:CalcComboDamage(target, combo)
        DamageLib:IsKillable(target, combo)
        DamageLib:AddToMenu(menu, combo)

    -Available spells by default (not added yet):
        _AA: Returns the auto-attack damage.
        _IGNITE: Returns the ignite damage.
        _ITEMS: Returns the damage dealt by all the items actives.

    -Damage types:
        _M
