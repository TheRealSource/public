-- Change autoUpdate to false if you wish to not receive auto updates.
-- Change silentUpdate to true if you wish not to receive any message regarding updates
local autoUpdate   = true
local silentUpdate = false

local version = 0.001

--[[

    Nidalee - a champoin script by team TheSource
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

]]

if player.charName ~= "Nidalee" then return end

-- Globals
local menu = nil

local drawManager = nil
local damageLib   = nil

local STS = nil

local VP = nil
local OW = nil

-- Spells
local spellQ  = nil
local spellW = nil
local spellE = nil

-- Code
function OnLoad()

    -- Load requirements
    require "SourceLib"
    require "VPrediction"
    require "SOW"

    -- AutoUpdate
    if autoUpdate then LazyUpdater("[Source] " .. player.charName, version, "bitbucket.org", "/TheRealSource/public/raw/master/Nidalee.lua", SCRIPT_PATH .. GetCurrentEnv().FILE_NAME):SetSilent(silentUpdate):CheckUpdate() end

    -- Initialize classes
    drawManager = DrawManager()
    damageLib   = DamageLib()

    STS = SimpleTS()

    VP = VPrediction()
    OW = SOW(VP)

    -- Initicalize drawing
    rangeCircleQ = drawManager:CreateCircle(player, 1500)
    rangeCircleW = drawManager:CreateCircle(player, 900)
    rangeCircleE = drawManager:CreateCircle(player, 600)

    -- Initialize menu
    menu = scriptConfig("[Source] " .. player.charName, "source" .. player.charName)

    menu:addSubMenu("Target Selector", "ts")
        STS:AddToMenu(menu.ts)

    menu:addSubMenu("Orbwalking", "orbwalk")
        OW:LoadToMenu(menu.orbwalk)

    menu:addSubMenu("Combo", "combo")
        menu.combo:addParam("active", "Combo active", SCRIPT_PARAM_ONKEYDOWN, false, 32)
        menu.combo:addParam("sep",    "",             SCRIPT_PARAM_INFO,      "")
        menu.combo:addParam("useQ",   "UseQ",         SCRIPT_PARAM_ONOFF,     true)
        menu.combo:addParam("useE",   "UseE",         SCRIPT_PARAM_ONOFF,     true)

    menu:addSubMenu("Harass", "harass")
        menu.harass:addParam("active", "Harass active",        SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))
        menu.harass:addParam("toggle", "Harass toggle",        SCRIPT_PARAM_ONOFF,     false, string.byte("Z"))
        menu.harass:addParam("sep",    "",                     SCRIPT_PARAM_INFO,      "")
        menu.harass:addParam("useQ",   "UseQ",                 SCRIPT_PARAM_ONOFF,     true)
        menu.harass:addParam("sep",    "",                     SCRIPT_PARAM_INFO,      "")
        menu.harass:addParam("mana",   "Min % mana to harass", SCRIPT_PARAM_SLICE,     30, 0, 100, 0)

    menu:addSubMenu("AutoHeal", "heal")
        menu.heal:addParam("self",   "Heal self",          SCRIPT_PARAM_ONOFF, true)
        menu.heal:addParam("others", "Heal allies",        SCRIPT_PARAM_ONOFF, true)
        menu.heal:addParam("sep",    "",                   SCRIPT_PARAM_INFO,  "")
        menu.heal:addParam("mana",   "Min % mana to heal", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)

    menu:addSubMenu("Drawing", "drawing")
        rangeCircleQ:AddToMenu(menu.drawing, "Q Range", true, true, true)
        rangeCircleW:AddToMenu(menu.drawing, "W Range", true, true, true)
        rangeCircleE:AddToMenu(menu.drawing, "E Range", true, true, true)

    -- Initialize spells
    spellQ = Spell(_Q, 1500):SetSkillshot(VP, SKILLSHOT_LINEAR, 60, 0, 1300, true)
    spellW = Spell(_W, 900)
    spellE = Spell(_E, 600)

    -- Set spell automations
    spellQ:AddAutomation("Combo",
    function()
        return menu.combo.useQ and menu.combo.active and STS:GetTarget(spellQ.range) ~= nil, STS:GetTarget(spellQ.range)
    end)

    spellE:AddAutomation("Combo",
    function()
        return menu.combo.useE and menu.combo.active and CountEnemyHeroInRange(525) > 0
    end)

    spellQ:AddAutomation("Harass",
    function()
        if menu.harass.useQ and not menu.combo.active and (menu.harass.active or menu.harass.toggle) then
            if player.mana / player.maxMana > menu.harass.mana / 100 then
                local target = STS:GetTarget(spellQ.range)
                return ValidTarget(target), target
            end
        end
    end)

    spellE:AddAutomation("Heal",
    function()
        if menu.heal.self or menu.heal.others then
            if player.mana / player.maxMana > menu.heal.mana / 100 then
                if menu.heal.self then
                    -- Heal self
                    return player.health < player.maxHealth, player
                else
                    -- Get allied with lowest percentage health in range
                    local validTargets = {}
                    for _, allied in ipairs(GetAllyHeroes()) do
                        if GetDistanceSqr(allied) <= spellE.rangeSqr then
                            table.insert(validTargets, allied)
                        end
                    end
                    local bestTarget = nil
                    local bestTargetHealth = nil
                    for _, allied in ipairs(validTargets) do
                        local currentHealth = allied.health / allied.maxHealth
                        if bestTarget == nil or bestTargetHealth > currentHealth then
                            bestTarget = allied
                            bestTargetHealth = currentHealth
                        end
                    end
                    return bestTarget ~= nil, bestTarget
                end
            end
        end
    end)

end
