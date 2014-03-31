-- Change autoUpdate to false if you wish to not receive auto updates.
-- Change silentUpdate to true if you wish not to receive any message regarding updates
local autoUpdate   = true
local silentUpdate = false

local version = 1.002

--[[

    LazyLib - a common library by Team TheSource
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
        LazyUpdater     -- One of the most basic functions for every script we use
        Spell           -- Spells handled the way they should be handled
        DrawManager     -- Easy drawing of all kind of things, comes along with some other classes such as Circle

]]

--[[

'||'                               '||'  '|'               '||            .                   
 ||        ....   ......  .... ...  ||    |  ... ...     .. ||   ....   .||.    ....  ... ..  
 ||       '' .||  '  .|'   '|.  |   ||    |   ||'  ||  .'  '||  '' .||   ||   .|...||  ||' '' 
 ||       .|' ||   .|'      '|.|    ||    |   ||    |  |.   ||  .|' ||   ||   ||       ||     
.||.....| '|..'|' ||....|    '|      '|..'    ||...'   '|..'||. '|..'|'  '|.'  '|...' .||.    
                          .. |                ||                                              
                           ''                ''''                                             

    LazyUpdater - a simple updater class

    Introduction:
        Scripts that want to use this class need to have a version field at the beginning of the script, like this:
            local version = YOUR_VERSION (YOUR_VERSION can either be a string a a numeric value!)
        It does not need to be exactly at the beginning, like in this script, but it has to be within the first 100
        chars of the file, otherwise the webresult won't see the field, as it gathers only about 100 chars

    Functions:
        LazyUpdater(scriptName, version, hostPath, filePath)

    Members:
        LazyUpdater.silent | bool | Defines wheather to print notifications or not

    Methods:
        LazyUpdater:SetSilent(silent)
        LazuUpdater:CheckUpdate()

]]
class 'LazyUpdater'

--[[
    Create a new instance of LazyUpdater

    @param scriptName | string | Name of the script which should be used when printed in chat
    @param version    | float  | Current version of the script
    @param host       | string | Host, for example "bitbucket.org" or "raw.github.com"
    @param hostPath   | string | Raw path to the script which should be updated
    @param filePath   | string | Path to the file which should be replaced when updating the script
]]
function LazyUpdater:__init(scriptName, version, host, hostPath, filePath)

    self.UPDATE_SCRIPT_NAME = scriptName
    self.UPDATE_HOST = host
    self.UPDATE_PATH = hostPath .. "?rand="..math.random(1,10000)
    self.UPDATE_FILE_PATH = filePath
    self.UPDATE_URL = "https://"..self.UPDATE_HOST..self.UPDATE_PATH

    self.FILE_VERSION = version
    self.SERVER_VERSION = nil

    self.printMessage = function(message) if not self.silent then print("<font color=\"#6699ff\"><b>" .. self.UPDATE_SCRIPT_NAME .. ":</b></font> <font color=\"#FFFFFF\">" .. message .. "</font>") end end
    self.getVersion = function(version) return tonumber(string.match(version, "%d+%.%d+")) end

    -- Members
    self.silent = false

end

--[[
    Allows or disallows the updater to print info about updating

    @param  | bool   | Message output or not
    @return | class  | The current instance
]]
function LazyUpdater:SetSilent(silent)

    self.silent = silent
    return self

end

--[[
    Check for an update and downloads it when available
]]
function LazyUpdater:CheckUpdate()

    -- Validate callback
    callback = callback and type(callback) == "function" and callback or nil

    local webResult = GetWebResult(self.UPDATE_HOST, self.UPDATE_PATH, "", 5)
    if webResult then
        self.SERVER_VERSION = string.match(webResult, "%s*local%s+version%s+=%s+.*%d+%.%d+")
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
        Spell.range         | float | Range of the spell, please do NOT change this value, use Spell:SetRange() instead
        Spell.rangeSqr      | float | Squared range of the spell, please do NOT change this value, use Spell:SetRange() instead
        Spell.packetCast    | bool  | Set packet cast state
        Spell.minTargetsAoe | int   | Set minimum targets for AOE damage

    Methods:
        Spell:SetRange(range)
        Spell:SetSkillshot(VP, skillshotType, width, delay, speed, collision)
        Spell:SetAOE(useAoe, radius, minTargetsAoe)
        Spell:SetHitChance(hitChance)
        Spell:ValidTarget(target)
        Spell:Cast(param1, param2)
        Spell:AddAutomation(automationId, func)
        Spell:RemoveAutomation(automationId)
        Spell:ClearAutomations()
        Spell:IsReady()
        Spell:GetManaUsage()
        Spell:GetCooldown()
        Spell:GetLevel()

]]
class 'Spell'

-- Class related constants
SKILLSHOT_LINEAR   = 0
SKILLSHOT_CIRCULAR = 1

SPELLSTATE_TRIGGERED          = 0
SPELLSTATE_OUT_OF_RANGE       = 1
SPELLSTATE_LOWER_HITCHANCE    = 2
SPELLSTATE_COLLISION          = 3
SPELLSTATE_NOT_ENOUGH_TARGETS = 4

-- Spell automations
local __spell_automations = nil
function __spell_OnTick()
    for index, spell in ipairs(__spell_automations) do
        if #spell._automations == 0 then
            table.remove(__spell_automations, index)
        else
            for _, automation in ipairs(spell._automations) do
                local doCast, param1, param2 = automation.func()
                if doCast == true then
                    spell:Cast(param1, param2)
                end
            end
        end
    end
end

-- Spell identifier number used for comparing spells
local spellNum = 1

--[[
    New instance of Spell

    @param spellId    | int   | Spell ID (_Q, _W, _E, _R)
    @param range      | float | Range of the spell
    @param packetCast | bool  | State of packet casting
]]
function Spell:__init(spellId, range, packetCast)

    assert(spellId ~= nil and range ~= nil and type(spellId) == "number" and type(range) == "number", "Spell: Can't initialize Spell without valid arguments.")

    self.spellId = spellId
    self:SetRange(range)
    self.packetCast = packetCast or false

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

    return ValidTarget(target, (range and range or self.range))

end

--[[
    Cast the spell, respecting previously made decisions about skillshots and AOE stuff

    @param param1 | userdata/float | When param2 is nil then this can be the target object, otherwise this is the X coordinate of the skillshot position
    @param param2 | float          | Z coordinate of the skillshot position
]]
function Spell:Cast(param1, param2)

    if self.skillshotType ~= nil and param1 ~= nil and param2 == nil then

        -- Don't calculate stuff when target is invalid
        if not ValidTarget(param1) then return end

        local castPosition, hitChance, nTargets
        if self.skillshotType == SKILLSHOT_LINEAR then
            if self.useAoe then
                castPosition, hitChance, nTargets = self.VP:GetLineAOECastPosition(param1, self.delay, self.radius, self.range, self.speed, player)
            else
                castPosition, hitChance = self.VP:GetLineCastPosition(param1, self.delay, self.width, self.range, self.speed, player, self.collision)
            end
        elseif self.skillshotType == SKILLSHOT_CIRCULAR then
            if self.useAoe then
                castPosition, hitChance, nTargets = self.VP:GetCircularAOECastPosition(param1, self.delay, self.radius, self.range, self.speed, player)
            else
                castPosition, hitChance = self.VP:GetCircularCastPosition(param1, self.delay, self.width, self.range, self.speed, player, self.collision)
            end
        end

        -- AOE not enough targets
        if nTargets and nTargets < self.minTargetsAoe then return SPELLSTATE_NOT_ENOUGH_TARGETS end

        -- Collision detected
        if hitChance == -1 then return SPELLSTATE_COLLISION end

        -- Hitchance too low
        if hitChance and hitChance < self.hitChance then return SPELLSTATE_LOWER_HITCHANCE end

        -- Out of range
        if self.rangeSqr < GetDistanceSqr(castPosition) then return SPELLSTATE_OUT_OF_RANGE end

        param1 = castPosition.x
        param2 = castPosition.z
    end

    if self.packetCast then
        if param1 ~= nil and param2 ~= nil then
            Packet("S_CAST", {spellId = self.spellId, toX = param1, toY = param2, fromX = param1, fromY = param2}):send()
        elseif param1 ~= nil then
            Packet("S_CAST", {spellId = self.spellId, toX = param1.x, toY = param1.z, fromX = param1.x, fromY = param1.z, targetNetworkId = param1.networkID}):send()
        else
            Packet("S_CAST", {spellId = self.spellId, toX = player.x, toY = player.z, fromX = player.x, fromY = player.z, targetNetworkId = player.networkID}):send()
        end
    else
        CastSpell(self.spellId, param1, param2)
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

    if not __spell_automations then
        __spell_automations = {}
        AddTickCallback(__spell_OnTick)
    end

    for index, spell in ipairs(__spell_automations) do
        if spell == self then return end
    end

    table.insert(__spell_automations, self)

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
]]
function DrawManager:AddCircle(circle)

    assert(circle, "DrawManager: circle is invalid!")

    for _, object in ipairs(self.objects) do
        assert(object ~= circle, "DrawManager: object was already in DrawManager")
    end

    table.insert(self.objects, circle)

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

    local circle = Circle(position, radius, width, color)
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
        Circle(position, radius, width, color)

    Members:
        Circle.enabled  | bool   | Enable or diable the circle (displayed)
        Circle.mode     | int    | See circle modes below
        Circle.position | vector | Center of the circle
        Circle.radius   | float  | Radius of the circle
        -- These are not changeable when a menu is set
        Circle.width    | int    | Width of the circle outline
        Circle.color    | table  | Color of the circle in a tale format { a, r, g, b }
        Circle.quality  | float  | Quality of the circle, the higher the smoother the circle

    Methods:
        Circle:AddToMenu(menu, paramText, addColor, addWidth, addQuality)
        Circle:SetEnabled(enabled)
        Circle:Set2D()
        Circle:Set3D()
        Circle:SetMinimap()
        Circle:SetQuality(qualtiy)
        Circle:SetDrawCondition(condition)
        Circle:Draw()

]]
class 'Circle'

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
function Circle:__init(position, radius, width, color)

    assert(position and position.x and (position.y and position.z or position.y), "Circle: position is invalid!")
    assert(radius and type(radius) == "number", "Circle: radius is invalid!")
    assert(not color or color and type(color) == "table" and #color == 4, "Circle: color is invalid!")

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
function Circle:AddToMenu(menu, paramText, addColor, addWidth, addQuality)

    assert(menu, "Circle: menu is invalid!")
    assert(self.menu == nil, "Circle: Already bound to a menu!")

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
function Circle:SetEnabled(enabled)

    self.enabled = enabled
    return self

end

--[[
    Set this circle to be displayed 2D

    @return | class | The current instance
]]
function Circle:Set2D()

    self.mode = CIRCLE_2D
    return self

end

--[[
    Set this circle to be displayed 3D

    @return | class | The current instance
]]
function Circle:Set3D()

    self.mode = CIRCLE_3D
    return self

end

--[[
    Set this circle to be displayed on the minimap

    @return | class | The current instance
]]
function Circle:SetMinimap()

    self.mode = CIRCLE_MINIMAP
    return self

end

--[[
    Set the display quality of this circle

    @return | class | The current instance
]]
function Circle:SetQuality(qualtiy)

    assert(qualtiy and type(qualtiy) == "number", "Circle: quality is invalid!")
    self.quality = quality
    return self

end

--[[
    Set the draw condition of this circle

    @return | class | The current instance
]]
function Circle:SetDrawCondition(condition)

    assert(condition and type(condition) == "function", "Circle: condition is invalid!")
    self.condition = condition
    return self

end

--[[
    Draw this circle, should only be called from OnDraw()
]]
function Circle:Draw()

    -- Don't draw if condition is not met
    if self.condition ~= nil and self.condition() == false then return end

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

function Circle:__eq(other)
    return other._circleId and other._circleId == self._circleId or false
end


--[[

'||'  '|'   .    ||  '||  
 ||    |  .||.  ...   ||  
 ||    |   ||    ||   ||  
 ||    |   ||    ||   ||  
  '|..'    '|.' .||. .||. 

    Util - Just utils.
]]

function spellToString(id)

    if id == _Q then return "Q" end
    if id == _W then return "W" end
    if id == _E then return "E" end
    if id == _R then return "R" end

end

function TARGB(colorTable)

    assert(colorTable and type(colorTable) == "table" and #colorTable == 4, "TARGB: colorTable is invalid!")
    return ARGB(colorTable[1], colorTable[2], colorTable[3], colorTable[4])

end

function pingClient(x, y, pingType)
    Packet("R_PING", {x = y, y = y, type = pingType and pingType or PING_FALLBACK}):receive()
end

local __util_autoAttack   = { "frostarrow" }
local __util_noAutoAttack = { "shyvanadoubleattackdragon",
                              "shyvanadoubleattack",
                              "monkeykingdoubleattack" }
function isAASpell(spell)

    if not spell or not spell.name then return end

    for _, spellName in ipairs(__util_autoAttack) do
        if spellName == spell.name:lower() then
            return true
        end
    end

    for _, spellName in ipairs(__util_noAutoAttack) do
        if spellName == spell.name:lower() then
            return false
        end
    end

    if spell.name:lower():find("attack") then
        return true
    end

    return false

end

-- Source: http://lua-users.org/wiki/CopyTable
function tableDeepCopy(orig)

    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy

end


--[[

'||'           ||    .    ||          '||   ||                    .    ||                   
 ||  .. ...   ...  .||.  ...   ....    ||  ...  ......   ....   .||.  ...    ...   .. ...   
 ||   ||  ||   ||   ||    ||  '' .||   ||   ||  '  .|'  '' .||   ||    ||  .|  '|.  ||  ||  
 ||   ||  ||   ||   ||    ||  .|' ||   ||   ||   .|'    .|' ||   ||    ||  ||   ||  ||  ||  
.||. .||. ||. .||.  '|.' .||. '|..'|' .||. .||. ||....| '|..'|'  '|.' .||.  '|..|' .||. ||. 

]]

-- Update script
if autoUpdate then
    LazyUpdater("SourceLib", version, "bitbucket.org", "/TheRealSource/public/raw/master/common/SourceLib.lua", LIB_PATH .. "SourceLib.lua"):SetSilent(silentUpdate):CheckUpdate()
end
