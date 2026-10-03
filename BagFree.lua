-- BagFree
-- Copyright (C) 2026 Kaegan
-- SPDX-License-Identifier: GPL-3.0-only

local addonName, BagFree = ...

--------------------------------------------------
-- 1. Constants and configuration
--------------------------------------------------
local FONT_PATH = "Fonts\\FRIZQT__.TTF"
local FIRST_BAG, LAST_BAG, REAGENT_BAG = 0, 4, 5
local QUIVER_FAMILY = 1
local AMMO_POUCH_FAMILY = 2
local SOUL_BAG_FAMILY = 4

local POSITIONS = {
    CENTER = { "CENTER", "CENTER", 0, 0 },
    TOPLEFT = { "TOPLEFT", "TOPLEFT", 3, -3 },
    TOP = { "TOP", "TOP", 0, -3 },
    TOPRIGHT = { "TOPRIGHT", "TOPRIGHT", -3, -3 },
    LEFT = { "LEFT", "LEFT", 3, 0 },
    RIGHT = { "RIGHT", "RIGHT", -3, 0 },
    BOTTOMLEFT = { "BOTTOMLEFT", "BOTTOMLEFT", 3, 3 },
    BOTTOM = { "BOTTOM", "BOTTOM", 0, 3 },
    BOTTOMRIGHT = { "BOTTOMRIGHT", "BOTTOMRIGHT", -3, 3 },
}

BagFree.defaults = {
    position = "CENTER",
    fontSize = 20,
    displayMode = "SEPARATE", -- SEPARATE, HIDE, COMBINED
}

--------------------------------------------------
-- 2. Local variables
--------------------------------------------------
local frame = CreateFrame("Frame")
local backpack = MainMenuBarBackpackButton
local reagentButton = CharacterReagentBag0Slot
local defaultCounter = MainMenuBarBackpackButtonCount
local bagText, reagentText
local regularFree, reagentFree = 0, 0


--------------------------------------------------
-- 3. Functions
--------------------------------------------------
local function HideDefaultCounter()
    if defaultCounter then
        defaultCounter:Hide()
    end
end

local function CreateCounter(parent)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetAllPoints(parent)
    holder:SetFrameLevel(parent:GetFrameLevel() + 5)

    local text = holder:CreateFontString(nil, "OVERLAY")
    text:SetTextColor(1, 1, 1, 1)
    text:SetShadowColor(0, 0, 0, 1)
    text:SetShadowOffset(2, -2)
    return text
end

local function ApplyCounterStyle(text, parent)
    local db = BagFreeDB
    local position = POSITIONS[db.position] or POSITIONS.CENTER
    text:SetFont(FONT_PATH, db.fontSize, "THICKOUTLINE")
    text:ClearAllPoints()
    text:SetPoint(position[1], parent, position[2], position[3], position[4])
end

function BagFree.Refresh()
    if not BagFreeDB or not bagText or not reagentText then return end

    ApplyCounterStyle(bagText, backpack)
    ApplyCounterStyle(reagentText, reagentButton)

    if BagFreeDB.displayMode == "COMBINED" then
        bagText:SetText(regularFree + reagentFree)
        reagentText:Hide()
    elseif BagFreeDB.displayMode == "HIDE" then
        bagText:SetText(regularFree)
        reagentText:Hide()
    else
        bagText:SetText(regularFree)
        reagentText:SetText(reagentFree)
        reagentText:Show()
    end
end

local function UpdateFreeSlots()
    regularFree, reagentFree = 0, 0

    -- Preserve Forever's existing specialized-bag counting behavior.
    for bag = FIRST_BAG, LAST_BAG do
        local free, bagFamily = C_Container.GetContainerNumFreeSlots(bag)
        free, bagFamily = free or 0, bagFamily or 0
        if bagFamily == 0 then
            regularFree = regularFree + free
        elseif bagFamily ~= QUIVER_FAMILY
            and bagFamily ~= AMMO_POUCH_FAMILY
            and bagFamily ~= SOUL_BAG_FAMILY then

            reagentFree = reagentFree + free
        end
    end

    reagentFree = reagentFree +
        (C_Container.GetContainerNumFreeSlots(REAGENT_BAG) or 0)
    BagFree.Refresh()
end

local function LoadSettings()
    BagFreeDB = type(BagFreeDB) == "table" and BagFreeDB or {}
    local defaults = BagFree.defaults
    if not POSITIONS[BagFreeDB.position] then
        BagFreeDB.position = defaults.position
    end
    if type(BagFreeDB.fontSize) ~= "number" then
        BagFreeDB.fontSize = defaults.fontSize
    end
    BagFreeDB.fontSize = math.floor(math.max(8, math.min(24, BagFreeDB.fontSize)))
    if BagFreeDB.displayMode ~= "SEPARATE" and
       BagFreeDB.displayMode ~= "HIDE" and
       BagFreeDB.displayMode ~= "COMBINED" then
        BagFreeDB.displayMode = defaults.displayMode
    end
end

local function OnEvent(self, event, name)
    if event == "ADDON_LOADED" then
        if name ~= addonName then return end
        self:UnregisterEvent("ADDON_LOADED")
        LoadSettings()
        BagFree.Refresh()
    elseif event == "PLAYER_ENTERING_WORLD" then
        HideDefaultCounter()
        UpdateFreeSlots()
        -- Forever initializes its bag UI asynchronously on login.
        C_Timer.After(1, function()
            HideDefaultCounter()
            UpdateFreeSlots()
        end)
    else
        UpdateFreeSlots()
    end
end

--------------------------------------------------
-- 4. Initialization
--------------------------------------------------
bagText = CreateCounter(backpack)
reagentText = CreateCounter(reagentButton)

if defaultCounter then
    hooksecurefunc(defaultCounter, "Show", HideDefaultCounter)
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("BAG_UPDATE")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:SetScript("OnEvent", OnEvent)
