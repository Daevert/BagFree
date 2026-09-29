-- BagFree
-- Copyright (C) 2026 Kaegan
-- SPDX-License-Identifier: GPL-3.0-only

local addonName, BagFree = ...

--------------------------------------------------
-- 1. Constants and configuration
--------------------------------------------------
local LABEL_X = 20
local CONTROL_X = 180
local CONTROL_WIDTH = 220
local ROW_POSITION_Y = -90
local ROW_FONT_Y = -140
local ROW_MODE_Y = -190
local ROW_DEFAULTS_Y = -240

local POSITION_OPTIONS = {
    { text = "Center", value = "CENTER" },
    { text = "Top left", value = "TOPLEFT" },
    { text = "Top", value = "TOP" },
    { text = "Top right", value = "TOPRIGHT" },
    { text = "Left", value = "LEFT" },
    { text = "Right", value = "RIGHT" },
    { text = "Bottom left", value = "BOTTOMLEFT" },
    { text = "Bottom", value = "BOTTOM" },
    { text = "Bottom right", value = "BOTTOMRIGHT" },
}

local FONT_SIZE_OPTIONS = {
    { text = "10", value = 10 },
    { text = "12", value = 12 },
    { text = "14", value = 14 },
    { text = "16", value = 16 },
    { text = "18", value = 18 },
    { text = "20", value = 20 },
    { text = "22", value = 22 },
    { text = "24", value = 24 }
}

local MODE_OPTIONS = {
    { text = "Separate regular and reagent counters", value = "SEPARATE" },
    { text = "Hide free reagent slots", value = "HIDE" },
    { text = "Combine regular and reagent slots", value = "COMBINED" },
}

--------------------------------------------------
-- 2. Local variables
--------------------------------------------------
local panel = CreateFrame("Frame", "BagFreeOptionsPanel")
local positionMenu, modeMenu, fontSizeMenu
local updating = false

--------------------------------------------------
-- 3. Functions
--------------------------------------------------
local function SetDropdownSelection(menu, options, value)
    UIDropDownMenu_SetSelectedValue(menu, value)
    for _, option in ipairs(options) do
        if option.value == value then
            UIDropDownMenu_SetText(menu, option.text)
            return
        end
    end
end

local function CreateLabel(text, y)
    local label = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", panel, "TOPLEFT", LABEL_X, y)
    label:SetText(text)
    return label
end

local function MakeDropdown(y, width, options, key)
    local menu = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
    -- Blizzard's dropdown template has a built-in left inset (~16px).
    -- Offset its frame so the visible control begins at CONTROL_X.
    menu:SetPoint("TOPLEFT", panel, "TOPLEFT", CONTROL_X + 16, y + 12)
    UIDropDownMenu_SetWidth(menu, width)

    UIDropDownMenu_Initialize(menu, function(self, level)
        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.value = option.value
            info.checked = BagFreeDB and BagFreeDB[key] == option.value
            info.func = function(button)
                BagFreeDB[key] = button.value
                SetDropdownSelection(menu, options, button.value)
                BagFree.Refresh()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    return menu
end

local function RefreshControls()
    if not BagFreeDB then return end
    updating = true
    SetDropdownSelection(positionMenu, POSITION_OPTIONS, BagFreeDB.position)
    SetDropdownSelection(fontSizeMenu, FONT_SIZE_OPTIONS, BagFreeDB.fontSize)
    SetDropdownSelection(modeMenu, MODE_OPTIONS, BagFreeDB.displayMode)
    updating = false
end

local function ResetDefaults()
    for key, value in pairs(BagFree.defaults) do
        BagFreeDB[key] = value
    end
    RefreshControls()
    BagFree.Refresh()
end

--------------------------------------------------
-- 4. Initialization
--------------------------------------------------
panel.name = "BagFree"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", panel, "TOPLEFT", LABEL_X, -20)
title:SetText("BagFree")

local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
subtitle:SetText("Customize the free-slot counters on your bag bar.")

CreateLabel("Counter position", ROW_POSITION_Y)
positionMenu = MakeDropdown(ROW_POSITION_Y, CONTROL_WIDTH, POSITION_OPTIONS, "position")

CreateLabel("Font size", ROW_FONT_Y)
fontSizeMenu = MakeDropdown(ROW_FONT_Y, CONTROL_WIDTH, FONT_SIZE_OPTIONS, "fontSize")

CreateLabel("Reagent slot display", ROW_MODE_Y)
modeMenu = MakeDropdown(ROW_MODE_Y, CONTROL_WIDTH, MODE_OPTIONS, "displayMode")

local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
reset:SetSize(CONTROL_X, 24)
reset:SetPoint("TOPLEFT", panel, "TOPLEFT", LABEL_X, ROW_DEFAULTS_Y)
reset:SetText("Reset to defaults")
reset:SetScript("OnClick", ResetDefaults)

panel:SetScript("OnShow", RefreshControls)

if Settings and Settings.RegisterCanvasLayoutCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, "BagFree")
    Settings.RegisterAddOnCategory(category)
else
    InterfaceOptions_AddCategory(panel)
end
