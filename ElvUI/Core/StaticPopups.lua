local E, L, V, P, G = unpack(select(2, ...)); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local AB = E:GetModule("ActionBars")
local UF = E:GetModule("UnitFrames")
local Misc = E:GetModule("Misc")
local Bags = E:GetModule("Bags")
local Skins = E:GetModule("Skins")

--Lua functions
local _G = _G
local pairs, ipairs, type, unpack, assert = pairs, ipairs, type, unpack, assert
local tremove, tContains, tinsert, wipe = tremove, tContains, tinsert, wipe
local strlower, format = strlower, format
--WoW API / Variables
local CreateFrame = CreateFrame
local IsAddOnLoaded = IsAddOnLoaded
local UnitIsDeadOrGhost, InCinematic = UnitIsDeadOrGhost, InCinematic
local GetBindingFromClick, RunBinding = GetBindingFromClick, RunBinding
local PurchaseSlot, GetBankSlotCost = PurchaseSlot, GetBankSlotCost
local MoneyFrame_Update = MoneyFrame_Update
local SetCVar, DisableAddOn = SetCVar, DisableAddOn
local ReloadUI, PlaySound, StopMusic = ReloadUI, PlaySound, StopMusic
local StaticPopup_Resize = StaticPopup_Resize
local AutoCompleteEditBox_OnEnterPressed = AutoCompleteEditBox_OnEnterPressed
local AutoCompleteEditBox_OnTextChanged = AutoCompleteEditBox_OnTextChanged
local ChatEdit_FocusActiveWindow = ChatEdit_FocusActiveWindow
local STATICPOPUP_TEXTURE_ALERT = STATICPOPUP_TEXTURE_ALERT
local STATICPOPUP_TEXTURE_ALERTGEAR = STATICPOPUP_TEXTURE_ALERTGEAR
local YES, NO, OKAY, CANCEL, ACCEPT, DECLINE = YES, NO, OKAY, CANCEL, ACCEPT, DECLINE

E.PopupDialogs = {}
E.StaticPopup_DisplayedFrames = {}

E.PopupDialogs.ELVUI_UPDATED_WHILE_RUNNING = {
	text = L["ElvUI was updated while the game is still running. Please relaunch the game, as this is required for the files to be properly updated."],
	button1 = "|cffff0000"..QUIT,
	button2 = CANCEL,
	OnAccept = function()
		Quit()
	end,
	OnShow = function(self, data)
		self.button2:Disable()
	end,
	whileDead = 1,
}

E.PopupDialogs.ELVUI_UPDATE_AVAILABLE = {
	text = L["ElvUI is five or more revisions out of date. You can download the newest version from https://github.com/Ascension-Addons/ElvUI"],
	hasEditBox = 1,
	OnShow = function(self)
		self.editBox:SetAutoFocus(false)
		self.editBox.width = self.editBox:GetWidth()
		self.editBox:Width(220)
		self.editBox:SetText("https://github.com/Ascension-Addons/ElvUI")
		self.editBox:HighlightText()
		ChatEdit_FocusActiveWindow()
	end,
	OnHide = function(self)
		self.editBox:Width(self.editBox.width or 50)
		self.editBox.width = nil
	end,
	hideOnEscape = 1,
	button1 = OKAY,
	OnAccept = E.noop,
	EditBoxOnEnterPressed = function(self)
		ChatEdit_FocusActiveWindow()
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		ChatEdit_FocusActiveWindow()
		self:GetParent():Hide()
	end,
	EditBoxOnTextChanged = function(self)
		if self:GetText() ~= "https://github.com/Ascension-Addons/ElvUI" then
			self:SetText("https://github.com/Ascension-Addons/ElvUI")
		end
		self:HighlightText()
		self:ClearFocus()
		ChatEdit_FocusActiveWindow()
	end,
	OnEditFocusGained = function(self)
		self:HighlightText()
	end,
	showAlert = 1
}

E.PopupDialogs.ELVUI_EDITBOX = {
	text = E.title,
	button1 = OKAY,
	hasEditBox = 1,
	OnShow = function(self, data)
		self.editBox:SetAutoFocus(false)
		self.editBox.width = self.editBox:GetWidth()
		self.editBox:Width(280)
		self.editBox:AddHistoryLine("text")
		self.editBox.temptxt = data
		self.editBox:SetText(data)
		self.editBox:HighlightText()
		self.editBox:SetJustifyH("CENTER")
	end,
	OnHide = function(self)
		self.editBox:Width(self.editBox.width or 50)
		self.editBox.width = nil
		self.temptxt = nil
	end,
	EditBoxOnEnterPressed = function(self)
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	EditBoxOnTextChanged = function(self)
		if self:GetText() ~= self.temptxt then
			self:SetText(self.temptxt)
		end
		self:HighlightText()
		self:ClearFocus()
	end,
	OnAccept = E.noop,
	whileDead = 1,
	preferredIndex = 3,
	hideOnEscape = 1,
}

E.PopupDialogs.CLIENT_UPDATE_REQUEST = {
	text = L["Detected that your ElvUI OptionsUI addon is out of date. This may be a result of your Tukui Client being out of date. Please visit our download page and update your Tukui Client, then reinstall ElvUI. Not having your ElvUI OptionsUI addon up to date will result in missing options."],
	button1 = OKAY,
	OnAccept = E.noop,
	showAlert = 1
}

E.PopupDialogs.CONFIRM_LOSE_BINDING_CHANGES = {
	text = CONFIRM_LOSE_BINDING_CHANGES,
	button1 = OKAY,
	button2 = CANCEL,
	OnAccept = function()
		AB:ChangeBindingProfile()
		AB.bindingsChanged = nil
	end,
	OnCancel = function()
		local isChecked = ElvUIBindPopupWindowCheckButton:GetChecked()
		ElvUIBindPopupWindowCheckButton:SetChecked(not isChecked)
	end,
	whileDead = 1,
	showAlert = 1
}

E.PopupDialogs.TUKUI_ELVUI_INCOMPATIBLE = {
	text = L["Oh lord, you have got ElvUI and Tukui both enabled at the same time. Select an addon to disable."],
	OnAccept = function() DisableAddOn("ElvUI") ReloadUI() end,
	OnCancel = function() DisableAddOn("Tukui") ReloadUI() end,
	button1 = "ElvUI",
	button2 = "Tukui",
	whileDead = 1,
	hideOnEscape = false
}

E.PopupDialogs.DISABLE_INCOMPATIBLE_ADDON = {
	text = L["Do you swear not to post in technical support about something not working without first disabling the addon/module combination first?"],
	OnAccept = function() E.global.ignoreIncompatible = true end,
	OnCancel = function() E:StaticPopup_Hide("DISABLE_INCOMPATIBLE_ADDON") E:StaticPopup_Show("INCOMPATIBLE_ADDON", E.PopupDialogs.INCOMPATIBLE_ADDON.addon, E.PopupDialogs.INCOMPATIBLE_ADDON.module) end,
	button1 = L["I Swear"],
	button2 = DECLINE,
	whileDead = 1,
	hideOnEscape = false
}

E.PopupDialogs.INCOMPATIBLE_ADDON = {
	text = L["INCOMPATIBLE_ADDON"],
	OnAccept = function() DisableAddOn(E.PopupDialogs.INCOMPATIBLE_ADDON.addon) ReloadUI() end,
	OnCancel = function() E.private[strlower(E.PopupDialogs.INCOMPATIBLE_ADDON.module)].enable = false ReloadUI() end,
	button3 = L["Disable Warning"],
	OnAlt = function ()
		E:StaticPopup_Hide("INCOMPATIBLE_ADDON")
		E:StaticPopup_Show("DISABLE_INCOMPATIBLE_ADDON")
	end,
	whileDead = 1,
	hideOnEscape = false,
	noCancelOnReuse = true
}

E.PopupDialogs.UISCALE_CHANGE = {
	text = L["The UI Scale has been changed, if you would like to preview the change press the preview button. It is recommended that you reload your User Interface for the best appearance."],
	OnAccept = function() ReloadUI() end,
	button1 = ACCEPT,
	button2 = CANCEL,
	button3 = L["Preview Changes"],
	OnAlt = function() E:PixelScaleChanged("UISCALE_CHANGE") end,
	whileDead = 1,
	hideOnEscape = false,
	noCancelOnReuse = true
}

E.PopupDialogs.CONFIG_RL = {
	text = L["One or more of the changes you have made require a ReloadUI."],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = ReloadUI,
	whileDead = 1,
	hideOnEscape = false
}

E.PopupDialogs.GLOBAL_RL = {
	text = L["One or more of the changes you have made will effect all characters using this addon. You will have to reload the user interface to see the changes you have made."],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = ReloadUI,
	whileDead = 1,
	hideOnEscape = false
}

E.PopupDialogs.PRIVATE_RL = {
	text = L["A setting you have changed will change an option for this character only. This setting that you have changed will be uneffected by changing user profiles. Changing this setting requires that you reload your User Interface."],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = ReloadUI,
	whileDead = 1,
	hideOnEscape = false
}

E.PopupDialogs.RESET_UF_UNIT = {
	text = L["Accepting this will reset the UnitFrame settings for %s. Are you sure?"],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(self)
		if self.data and self.data.unit then
			UF:ResetUnitSettings(self.data.unit)
			if self.data.mover then
				E:ResetMovers(self.data.mover)
			end

			if self.data.unit == "raidpet" then
				UF:CreateAndUpdateHeaderGroup(self.data.unit, nil, nil, true)
			end

			if IsAddOnLoaded("ElvUI_OptionsUI") then
				local ACD = E.Libs.AceConfigDialog
				if ACD and ACD.OpenFrames and ACD.OpenFrames.ElvUI then
					ACD:SelectGroup("ElvUI", "unitframe", self.data.unit)
				end
			end
		else
			E:Print(L["Error resetting UnitFrame."])
		end
	end,
	whileDead = 1,
	hideOnEscape = false,
}

E.PopupDialogs.RESET_UF_AF = {
	text = L["Accepting this will reset your Filter Priority lists for all auras on UnitFrames. Are you sure?"],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function()
		for unitName, content in pairs(E.db.unitframe.units) do
			if content.buffs then
				content.buffs.priority = P.unitframe.units[unitName].buffs.priority
			end
			if content.debuffs then
				content.debuffs.priority = P.unitframe.units[unitName].debuffs.priority
			end
			if content.aurabar then
				content.aurabar.priority = P.unitframe.units[unitName].aurabar.priority
			end
		end
	end,
	whileDead = 1,
	hideOnEscape = false,
}

E.PopupDialogs.RESET_NP_AF = {
	text = L["Accepting this will reset your Filter Priority lists for all auras on NamePlates. Are you sure?"],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function()
		for unitType, content in pairs(E.db.nameplates.units) do
			if content.buffs and content.buffs.filters then
				content.buffs.filters.priority = P.nameplates.units[unitType].buffs.filters.priority
			end
			if content.debuffs and content.debuffs.filters then
				content.debuffs.filters.priority = P.nameplates.units[unitType].debuffs.filters.priority
			end
		end
	end,
	whileDead = 1,
	hideOnEscape = false,
}

E.PopupDialogs.DELETE_GRAYS = {
	text = format("|cffff0000%s|r", L["Delete gray items?"]),
	button1 = YES,
	button2 = NO,
	OnAccept = function() Bags:VendorGrays(true) end,
	OnShow = function(self)
		MoneyFrame_Update(self.moneyFrame, E.PopupDialogs.DELETE_GRAYS.Money)
	end,
	timeout = 4,
	whileDead = 1,
	hideOnEscape = false,
	hasMoneyFrame = 1
}

E.PopupDialogs.BUY_BANK_SLOT = {
	text = CONFIRM_BUY_BANK_SLOT,
	button1 = YES,
	button2 = NO,
	OnAccept = PurchaseSlot,
	OnShow = function(self)
		MoneyFrame_Update(self.moneyFrame, GetBankSlotCost())
	end,
	hasMoneyFrame = 1,
	hideOnEscape = 1
}

E.PopupDialogs.CANNOT_BUY_BANK_SLOT = {
	text = L["Can't buy anymore slots!"],
	button1 = ACCEPT,
	whileDead = 1
}

E.PopupDialogs.NO_BANK_BAGS = {
	text = L["You must purchase a bank slot first!"],
	button1 = ACCEPT,
	whileDead = 1
}

E.PopupDialogs.RESETUI_CHECK = {
	text = L["Are you sure you want to reset every mover back to it's default position?"],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function()
		E:ResetAllUI()
	end,
	whileDead = 1
}

E.PopupDialogs.HARLEM_SHAKE = {
	text = L["ElvUI needs to perform database optimizations please be patient."],
	button1 = OKAY,
	OnAccept = function()
		if E.isMassiveShaking then
			E:StopHarlemShake()
		else
			E:BeginHarlemShake()
			return true
		end
	end,
	whileDead = 1
}

E.PopupDialogs.HELLO_KITTY = {
	text = L["ElvUI needs to perform database optimizations please be patient."],
	button1 = OKAY,
	OnAccept = function()
		E:SetupHelloKitty()
	end,
	whileDead = 1
}

E.PopupDialogs.HELLO_KITTY_END = {
	text = L["Do you enjoy the new ElvUI?"],
	button1 = L["Yes, Keep Changes!"],
	button2 = L["No, Revert Changes!"],
	OnAccept = function()
		E:Print(L["Type /hellokitty to revert to old settings."])
		StopMusic()
		SetCVar("Sound_EnableAllSound", E.oldEnableAllSound)
		SetCVar("Sound_EnableMusic", E.oldEnableMusic)
	end,
	OnCancel = function()
		E:RestoreHelloKitty()
		StopMusic()
		SetCVar("Sound_EnableAllSound", E.oldEnableAllSound)
		SetCVar("Sound_EnableMusic", E.oldEnableMusic)
	end,
	whileDead = 1
}

E.PopupDialogs.DISBAND_RAID = {
	text = L["Are you sure you want to disband the group?"],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function() Misc:DisbandRaidGroup() end,
	whileDead = 1
}

E.PopupDialogs.CONFIRM_LOOT_DISTRIBUTION = {
	text = CONFIRM_LOOT_DISTRIBUTION,
	button1 = YES,
	button2 = NO,
	hideOnEscape = 1
}

E.PopupDialogs.RESET_PROFILE_PROMPT = {
	text = L["Are you sure you want to reset all the settings on this profile?"],
	button1 = YES,
	button2 = NO,
	hideOnEscape = 1,
	OnAccept = function() E:ResetProfile() end,
	whileDead = 1,
}

E.PopupDialogs.APPLY_FONT_WARNING = {
	text = L["Are you sure you want to apply this font to all ElvUI elements?"],
	OnAccept = function()
		local font = E.db.general.font
		local fontSize = E.db.general.fontSize

		E.db.bags.itemLevelFont = font
		E.db.bags.itemLevelFontSize = fontSize
		E.db.bags.countFont = font
		E.db.bags.countFontSize = fontSize
		E.db.nameplates.font = font
		--E.db.nameplates.fontSize = fontSize
		E.db.actionbar.font = font
		--E.db.actionbar.fontSize = fontSize
		E.db.auras.font = font
		E.db.auras.fontSize = fontSize
		E.db.general.reminder.font = font
		--E.db.general.reminder.fontSize = fontSize
		E.db.chat.font = font
		E.db.chat.fontSize = fontSize
		E.db.chat.tabFont = font
		E.db.chat.tapFontSize = fontSize
		E.db.datatexts.font = font
		E.db.datatexts.fontSize = fontSize
		E.db.general.minimap.locationFont = font
		E.db.tooltip.font = font
		E.db.tooltip.fontSize = fontSize
		E.db.tooltip.headerFontSize = fontSize
		E.db.tooltip.textFontSize = fontSize
		E.db.tooltip.smallTextFontSize = fontSize
		E.db.tooltip.healthBar.font = font
		--E.db.tooltip.healthbar.fontSize = fontSize
		E.db.unitframe.font = font
		--E.db.unitframe.fontSize = fontSize
		E.db.unitframe.units.party.rdebuffs.font = font
		E.db.unitframe.units.raid.rdebuffs.font = font
		E.db.unitframe.units.raid40.rdebuffs.font = font

		E:UpdateAll(true)
	end,
	button1 = YES,
	button2 = CANCEL,
	whileDead = 1,
	hideOnEscape = false
}

E.PopupDialogs.MODULE_COPY_CONFIRM = {
	button1 = ACCEPT,
	button2 = CANCEL,
	whileDead = 1,
	hideOnEscape = false
}

E.PopupDialogs.SCRIPT_PROFILE = {
	text = L["You are using CPU Profiling. This causes decreased performance. Do you want to disable it or continue?"],
	button1 = L["Disable"],
	button2 = L["Continue"],
	OnAccept = function()
		SetCVar("scriptProfile", 0)
		ReloadUI()
	end,
	showAlert = 1,
	whileDead = 1,
	hideOnEscape = false
}

E.PopupDialogs.ELVUI_CONFIG_FOUND = {
	text = L["You still have ElvUI_Config installed. ElvUI_Config has been renamed to ElvUI_OptionsUI, please remove it."],
	button1 = ACCEPT,
	whileDead = 1,
	hideOnEscape = false
}

local MAX_STATIC_POPUPS = 4
function E:StaticPopup_OnShow()
	PlaySound("igMainMenuOpen")

	local dialog = E.PopupDialogs[self.which]
	local OnShow = dialog.OnShow

	if OnShow then
		OnShow(self, self.data)
	end
	if dialog.hasMoneyInputFrame then
		_G[self:GetName().."MoneyInputFrameGold"]:SetFocus()
	end
	if dialog.enterClicksFirstButton then
		self:SetScript("OnKeyDown", E.StaticPopup_OnKeyDown)
	end

	-- boost static popups over ace gui
	if IsAddOnLoaded("ElvUI_OptionsUI") then
		local ACD = E.Libs.AceConfigDialog
		if ACD and ACD.OpenFrames and ACD.OpenFrames.ElvUI then
			self.frameStrataIncreased = true
			self:SetFrameStrata("FULLSCREEN_DIALOG")

			local popupFrameLevel = self:GetFrameLevel()
			if popupFrameLevel < 100 then
				self:SetFrameLevel(popupFrameLevel+100)
			end
		end
	end
end

function E:StaticPopup_EscapePressed()
	local closed = nil
	for _, frame in ipairs(E.StaticPopup_DisplayedFrames) do
		if frame:IsShown() and frame.hideOnEscape then
			local standardDialog = E.PopupDialogs[frame.which]
			if standardDialog then
				local OnCancel = standardDialog.OnCancel
				local noCancelOnEscape = standardDialog.noCancelOnEscape
				if OnCancel and not noCancelOnEscape then
					OnCancel(frame, frame.data, "clicked")
				end
				frame:Hide()
			else
				E:StaticPopupSpecial_Hide(frame)
			end
			closed = 1
		end
	end
	return closed
end

function E:StaticPopupSpecial_Hide(frame)
	frame:Hide()
	E:StaticPopup_CollapseTable()
end

function E:StaticPopup_CollapseTable()
	local displayedFrames = E.StaticPopup_DisplayedFrames
	local index = #displayedFrames
	while (index >= 1) and (not displayedFrames[index]:IsShown()) do
		tremove(displayedFrames, index)
		index = index - 1
	end
end

function E:StaticPopup_SetUpPosition(dialog)
	if not tContains(E.StaticPopup_DisplayedFrames, dialog) then
		local lastFrame = E.StaticPopup_DisplayedFrames[#E.StaticPopup_DisplayedFrames]
		if lastFrame then
			dialog:Point("TOP", lastFrame, "BOTTOM", 0, -4)
		else
			dialog:Point("TOP", E.UIParent, "TOP", 0, -100)
		end
		tinsert(E.StaticPopup_DisplayedFrames, dialog)
	end
end

function E:StaticPopupSpecial_Show(frame)
	if frame.exclusive then
		E:StaticPopup_HideExclusive()
	end
	E:StaticPopup_SetUpPosition(frame)
	frame:Show()
end

function E:StaticPopupSpecial_Hide(frame)
	frame:Hide()
	E:StaticPopup_CollapseTable()
end

--Used to figure out if we can resize a frame
function E:StaticPopup_IsLastDisplayedFrame(frame)
	for i = #E.StaticPopup_DisplayedFrames, 1, -1 do
		local popup = E.StaticPopup_DisplayedFrames[i]
		if popup:IsShown() then
			return frame == popup
		end
	end
	return false
end

function E:StaticPopup_OnKeyDown(key)
	if GetBindingFromClick(key) == "TOGGLEGAMEMENU" then
		return E:StaticPopup_EscapePressed()
	elseif GetBindingFromClick(key) == "SCREENSHOT" then
		RunBinding("SCREENSHOT")
		return
	end

	local dialog = E.PopupDialogs[self.which]
	if dialog then
		if key == "ENTER" and dialog.enterClicksFirstButton then
			local frameName = self:GetName()
			local button
			local i = 1
			while true do
				button = _G[frameName.."Button"..i]
				if button then
					if button:IsShown() then
						E:StaticPopup_OnClick(self, i)
						return
					end
					i = i + 1
				else
					break
				end
			end
		end
	end
end

function E:StaticPopup_OnHide()
	PlaySound("igMainMenuClose")

	E:StaticPopup_CollapseTable()

	local dialog = E.PopupDialogs[self.which]
	local OnHide = dialog.OnHide
	if OnHide then
		OnHide(self, self.data)
	end
	self.extraFrame:Hide()
	if dialog.enterClicksFirstButton then
		self:SetScript("OnKeyDown", nil)
	end

	-- static popup was boosted over ace gui, set it back to normal
	if self.frameStrataIncreased then
		self.frameStrataIncreased = nil
		self:SetFrameStrata("DIALOG")

		local popupFrameLevel = self:GetFrameLevel()
		if popupFrameLevel > 100 then
			self:SetFrameLevel(popupFrameLevel-100)
		end
	end
end

function E:StaticPopup_OnUpdate(elapsed)
	if self.timeleft and self.timeleft > 0 then
		local which = self.which
		local timeleft = self.timeleft - elapsed
		if timeleft <= 0 then
			if not E.PopupDialogs[which].timeoutInformationalOnly then
				self.timeleft = 0
				local OnCancel = E.PopupDialogs[which].OnCancel
				if OnCancel then
					OnCancel(self, self.data, "timeout")
				end
				self:Hide()
			end
			return
		end
		self.timeleft = timeleft
	end

	if self.startDelay then
		local which = self.which
		local timeleft = self.startDelay - elapsed
		if timeleft <= 0 then
			self.startDelay = nil
			local text = _G[self:GetName().."Text"]
			text:SetFormattedText(E.PopupDialogs[which].text, text.text_arg1, text.text_arg2)
			local button1 = _G[self:GetName().."Button1"]
			button1:Enable()
			StaticPopup_Resize(self, which)
			return
		end
		self.startDelay = timeleft
	end

	local onUpdate = E.PopupDialogs[self.which].OnUpdate
	if onUpdate then
		onUpdate(self, elapsed)
	end
end

function E:StaticPopup_OnClick(index)
	if not self:IsShown() then return end

	local which = self.which
	local info = E.PopupDialogs[which]
	if not info then
		return nil
	end
	local hide = true
	if index == 1 then
		local OnAccept = info.OnAccept
		if OnAccept then
			hide = not OnAccept(self, self.data, self.data2)
		end
	elseif index == 3 then
		local OnAlt = info.OnAlt
		if OnAlt then
			OnAlt(self, self.data, "clicked")
		end
	else
		local OnCancel = info.OnCancel
		if OnCancel then
			hide = not OnCancel(self, self.data, "clicked")
		end
	end

	if hide and (which == self.which) and (index ~= 3 or not info.noCloseOnAlt) then
		self:Hide()
	end
end

function E:StaticPopup_EditBoxOnEnterPressed()
	local EditBoxOnEnterPressed, which, dialog
	local parent = self:GetParent()
	if parent.which then
		which = parent.which
		dialog = parent
	elseif parent:GetParent().which then
		-- This is needed if this is a money input frame since it's nested deeper than a normal edit box
		which = parent:GetParent().which
		dialog = parent:GetParent()
	end
	if not self.autoCompleteParams or not AutoCompleteEditBox_OnEnterPressed(self) then
		EditBoxOnEnterPressed = E.PopupDialogs[which].EditBoxOnEnterPressed
		if EditBoxOnEnterPressed then
			EditBoxOnEnterPressed(self, dialog.data)
		end
	end
end

function E:StaticPopup_EditBoxOnEscapePressed()
	local EditBoxOnEscapePressed = E.PopupDialogs[self:GetParent().which].EditBoxOnEscapePressed
	if EditBoxOnEscapePressed then
		EditBoxOnEscapePressed(self, self:GetParent().data)
	end
end

function E:StaticPopup_EditBoxOnTextChanged(userInput)
	if not self.autoCompleteParams or not AutoCompleteEditBox_OnTextChanged(self, userInput) then
		local EditBoxOnTextChanged = E.PopupDialogs[self:GetParent().which].EditBoxOnTextChanged
		if EditBoxOnTextChanged then
			EditBoxOnTextChanged(self, self:GetParent().data)
		end
	end
end

function E:StaticPopup_FindVisible(which, data)
	local info = E.PopupDialogs[which]
	if not info then
		return nil
	end
	for index = 1, MAX_STATIC_POPUPS do
		local frame = _G["ElvUI_StaticPopup"..index]
		if frame and frame:IsShown() and (frame.which == which) and (not info.multiple or (frame.data == data)) then
			return frame
		end
	end
	return nil
end

function E:StaticPopup_Resize(dialog, which)
	local info = E.PopupDialogs[which]
	if not info then
		return nil
	end

	local name = dialog:GetName()
	local text = _G[name.."Text"]
	local editBox = _G[name.."EditBox"]
	local button1 = _G[name.."Button1"]

	local maxHeightSoFar, maxWidthSoFar = (dialog.maxHeightSoFar or 0), (dialog.maxWidthSoFar or 0)
	local width = 320

	if dialog.numButtons == 3 then
		width = 440
	elseif info.showAlert or info.showAlertGear or info.closeButton then
		width = 420
	elseif info.editBoxWidth and info.editBoxWidth > 260 then
		width = width + (info.editBoxWidth - 260)
	end

	if width > maxWidthSoFar then
		dialog:Width(width)
		dialog.maxWidthSoFar = width
	end

	local height = 32 + text:GetHeight() + 8 + button1:GetHeight()
	if info.hasEditBox then
		height = height + 8 + editBox:GetHeight()
	elseif info.hasMoneyFrame then
		height = height + 16
	elseif info.hasMoneyInputFrame then
		height = height + 22
	end
	if info.hasItemFrame then
		height = height + 64
	end

	if height > maxHeightSoFar then
		dialog:Height(height)
		dialog.maxHeightSoFar = height
	end
end

function E:StaticPopup_OnEvent()
	self.maxHeightSoFar = 0
	E:StaticPopup_Resize(self, self.which)
end

local tempButtonLocs = {} --So we don't make a new table each time.
function E:StaticPopup_Show(which, text_arg1, text_arg2, data)
	local info = E.PopupDialogs[which]
	if not info then
		return nil
	end

	if not info.whileDead and UnitIsDeadOrGhost("player") then
		if info.OnCancel then
			info.OnCancel()
		end
		return nil
	end

	if not info.interruptCinematic and InCinematic() then
		if info.OnCancel then
			info.OnCancel()
		end
		return nil
	end

	if info.cancels then
		for index = 1, MAX_STATIC_POPUPS do
			local frame = _G["ElvUI_StaticPopup"..index]
			if frame:IsShown() and (frame.which == info.cancels) then
				frame:Hide()
				local OnCancel = E.PopupDialogs[frame.which].OnCancel
				if OnCancel then
					OnCancel(frame, frame.data, "override")
				end
			end
		end
	end

	-- Pick a free dialog to use, find an open dialog of the requested type
	local dialog = E:StaticPopup_FindVisible(which, data)
	if dialog then
		if not info.noCancelOnReuse then
			local OnCancel = info.OnCancel
			if OnCancel then
				OnCancel(dialog, dialog.data, "override")
			end
		end
		dialog:Hide()
	end
	if not dialog then
		-- Find a free dialog
		local index = 1
		if info.preferredIndex then
			index = info.preferredIndex
		end
		for i = index, MAX_STATIC_POPUPS do
			local frame = _G["ElvUI_StaticPopup"..i]
			if frame and not frame:IsShown() then
				dialog = frame
				break
			end
		end

		--If dialog not found and there's a preferredIndex then try to find an available frame before the preferredIndex
		if not dialog and info.preferredIndex then
			for i = 1, info.preferredIndex do
				local frame = _G["ElvUI_StaticPopup"..i]
				if frame and not frame:IsShown() then
					dialog = frame
					break
				end
			end
		end
	end
	if not dialog then
		if info.OnCancel then
			info.OnCancel()
		end
		return nil
	end

	dialog.maxHeightSoFar, dialog.maxWidthSoFar = 0, 0
	-- Set the text of the dialog
	local name = dialog:GetName()
	local text = _G[name.."Text"]
	text:SetFormattedText(info.text, text_arg1, text_arg2)

	if info.closeButton then
		local closeButton = _G[name.."CloseButton"]
		if info.closeButtonIsHide then
			closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-HideButton-Up")
			closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-HideButton-Down")
		else
			closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
			closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
		end
		closeButton:Show()
	else
		_G[name.."CloseButton"]:Hide()
	end

	-- Set the editbox of the dialog
	local editBox = _G[name.."EditBox"]
	if info.hasEditBox then
		editBox:Show()

		if info.maxLetters then
			editBox:SetMaxLetters(info.maxLetters)
			editBox:SetCountInvisibleLetters(info.countInvisibleLetters)
		end
		if info.maxBytes then
			editBox:SetMaxBytes(info.maxBytes)
		end
		editBox:SetText("")
		if info.editBoxWidth then
			editBox:Width(info.editBoxWidth)
		else
			editBox:Width(130)
		end
	else
		editBox:Hide()
	end

	-- Show or hide money frame
	if info.hasMoneyFrame then
		_G[name.."MoneyFrame"]:Show()
		_G[name.."MoneyInputFrame"]:Hide()
	elseif info.hasMoneyInputFrame then
		local moneyInputFrame = _G[name.."MoneyInputFrame"]
		moneyInputFrame:Show()
		_G[name.."MoneyFrame"]:Hide()
		-- Set OnEnterPress for money input frames
		if info.EditBoxOnEnterPressed then
			moneyInputFrame.gold:SetScript("OnEnterPressed", E.StaticPopup_EditBoxOnEnterPressed)
			moneyInputFrame.silver:SetScript("OnEnterPressed", E.StaticPopup_EditBoxOnEnterPressed)
			moneyInputFrame.copper:SetScript("OnEnterPressed", E.StaticPopup_EditBoxOnEnterPressed)
		else
			moneyInputFrame.gold:SetScript("OnEnterPressed", nil)
			moneyInputFrame.silver:SetScript("OnEnterPressed", nil)
			moneyInputFrame.copper:SetScript("OnEnterPressed", nil)
		end
	else
		_G[name.."MoneyFrame"]:Hide()
		_G[name.."MoneyInputFrame"]:Hide()
	end

	-- Show or hide item button
	if info.hasItemFrame then
		_G[name.."ItemFrame"]:Show()
		if data and type(data) == "table" then
			_G[name.."ItemFrame"].link = data.link
			_G[name.."ItemFrameIconTexture"]:SetTexture(data.texture)
			local nameText = _G[name.."ItemFrameText"]
			nameText:SetTextColor(unpack(data.color or {1, 1, 1, 1}))
			nameText:SetText(data.name)
			if data.count and data.count > 1 then
				_G[name.."ItemFrameCount"]:SetText(data.count)
				_G[name.."ItemFrameCount"]:Show()
			else
				_G[name.."ItemFrameCount"]:Hide()
			end
		end
	else
		_G[name.."ItemFrame"]:Hide()
	end

	-- Set the miscellaneous variables for the dialog
	dialog.which = which
	dialog.timeleft = info.timeout
	dialog.hideOnEscape = info.hideOnEscape
	dialog.exclusive = info.exclusive
	dialog.enterClicksFirstButton = info.enterClicksFirstButton
	-- Clear out data
	dialog.data = data

	-- Set the buttons of the dialog
	local button1 = _G[name.."Button1"]
	local button2 = _G[name.."Button2"]
	local button3 = _G[name.."Button3"]

	do	--If there is any recursion in this block, we may get errors (tempButtonLocs is static). If you have to recurse, we'll have to create a new table each time.
		assert(#tempButtonLocs == 0) --If this fails, we're recursing. (See the table.wipe at the end of the block)

		tinsert(tempButtonLocs, button1)
		tinsert(tempButtonLocs, button2)
		tinsert(tempButtonLocs, button3)

		for i = #tempButtonLocs, 1, -1 do
			--Do this stuff before we move it. (This is why we go back-to-front)
			tempButtonLocs[i]:SetText(info["button"..i])
			tempButtonLocs[i]:Hide()
			tempButtonLocs[i]:ClearAllPoints()
			--Now we possibly remove it.
			if not (info["button"..i] and ( not info["DisplayButton"..i] or info["DisplayButton"..i](dialog))) then
				tremove(tempButtonLocs, i)
			end
		end

		local numButtons = #tempButtonLocs
		--Save off the number of buttons.
		dialog.numButtons = numButtons

		if numButtons == 3 then
			tempButtonLocs[1]:Point("BOTTOMRIGHT", dialog, "BOTTOM", -72, 16)
		elseif numButtons == 2 then
			tempButtonLocs[1]:Point("BOTTOMRIGHT", dialog, "BOTTOM", -6, 16)
		elseif numButtons == 1 then
			tempButtonLocs[1]:Point("BOTTOM", dialog, "BOTTOM", 0, 16)
		end

		for i = 1, numButtons do
			if i > 1 then
				tempButtonLocs[i]:Point("LEFT", tempButtonLocs[i - 1], "RIGHT", 13, 0)
			end

			local width = tempButtonLocs[i]:GetTextWidth()
			if width > 110 then
				tempButtonLocs[i]:Width(width + 20)
			else
				tempButtonLocs[i]:Width(120)
			end
			tempButtonLocs[i]:Enable()
			tempButtonLocs[i]:Show()
		end

		wipe(tempButtonLocs)
	end

	-- Show or hide the alert icon
	local alertIcon = _G[name.."AlertIcon"]
	if info.showAlert then
		alertIcon:SetTexture(STATICPOPUP_TEXTURE_ALERT)
		if button3:IsShown() then
			alertIcon:Point("LEFT", 24, 10)
		else
			alertIcon:Point("LEFT", 24, 0)
		end
		alertIcon:Show()
	elseif info.showAlertGear then
		alertIcon:SetTexture(STATICPOPUP_TEXTURE_ALERTGEAR)
		if button3:IsShown() then
			alertIcon:Point("LEFT", 24, 0)
		else
			alertIcon:Point("LEFT", 24, 0)
		end
		alertIcon:Show()
	else
		alertIcon:SetTexture()
		alertIcon:Hide()
	end

	if info.StartDelay then
		dialog.startDelay = info.StartDelay()
		button1:Disable()
	else
		dialog.startDelay = nil
		button1:Enable()
	end

	editBox.autoCompleteParams = info.autoCompleteParams
	editBox.autoCompleteRegex = info.autoCompleteRegex
	editBox.autoCompleteFormatRegex = info.autoCompleteFormatRegex

	editBox.addHighlightedText = true

	-- Finally size and show the dialog
	E:StaticPopup_SetUpPosition(dialog)
	dialog:Show()

	E:StaticPopup_Resize(dialog, which)

	if info.sound then
		PlaySound(info.sound)
	end

	return dialog
end

function E:StaticPopup_Hide(which, data)
	for index = 1, MAX_STATIC_POPUPS do
		local dialog = _G["ElvUI_StaticPopup"..index]
		if (dialog.which == which) and (not data or (data == dialog.data)) then
			dialog:Hide()
		end
	end
end

function E:Contruct_StaticPopups()
	E.StaticPopupFrames = {}

	for index = 1, MAX_STATIC_POPUPS do
		E.StaticPopupFrames[index] = CreateFrame("Frame", "ElvUI_StaticPopup"..index, E.UIParent, "StaticPopupTemplate")
		E.StaticPopupFrames[index]:SetID(index)

		--Fix Scripts
		E.StaticPopupFrames[index]:SetScript("OnShow", E.StaticPopup_OnShow)
		E.StaticPopupFrames[index]:SetScript("OnHide", E.StaticPopup_OnHide)
		E.StaticPopupFrames[index]:SetScript("OnUpdate", E.StaticPopup_OnUpdate)
		E.StaticPopupFrames[index]:SetScript("OnEvent", E.StaticPopup_OnEvent)

		local name = E.StaticPopupFrames[index]:GetName()
		for i = 1, 3 do
			_G[name.."Button"..i]:SetScript("OnClick", function(button)
				E.StaticPopup_OnClick(button:GetParent(), button:GetID())
			end)
		end

		_G[name.."EditBox"]:SetScript("OnEnterPressed", E.StaticPopup_EditBoxOnEnterPressed)
		_G[name.."EditBox"]:SetScript("OnEscapePressed", E.StaticPopup_EditBoxOnEscapePressed)
		_G[name.."EditBox"]:SetScript("OnTextChanged", E.StaticPopup_EditBoxOnTextChanged)

		--Skin
		E.StaticPopupFrames[index]:SetTemplate("Transparent")

		for i = 1, 3 do
			Skins:HandleButton(_G[name.."Button"..i])
		end

		Skins:HandleEditBox(_G[name.."EditBox"])
		for k = 1, _G[name.."EditBox"]:GetNumRegions() do
			local region = select(k, _G[name.."EditBox"]:GetRegions())
			if region and region:IsObjectType("Texture") then
				if region:GetTexture() == "Interface\\ChatFrame\\UI-ChatInputBorder-Left" or region:GetTexture() == "Interface\\ChatFrame\\UI-ChatInputBorder-Right" then
					region:Kill()
				end
			end
		end
		Skins:HandleEditBox(_G[name.."MoneyInputFrameGold"])
		Skins:HandleEditBox(_G[name.."MoneyInputFrameSilver"])
		Skins:HandleEditBox(_G[name.."MoneyInputFrameCopper"])
		_G[name.."EditBox"].backdrop:Point("TOPLEFT", -2, -4)
		_G[name.."EditBox"].backdrop:Point("BOTTOMRIGHT", 2, 4)
		_G[name.."ItemFrameNameFrame"]:Kill()
		_G[name.."ItemFrame"]:GetNormalTexture():Kill()
		_G[name.."ItemFrame"]:SetTemplate("Default")
		_G[name.."ItemFrame"]:StyleButton()
		_G[name.."ItemFrameIconTexture"]:SetTexCoord(unpack(E.TexCoords))
		_G[name.."ItemFrameIconTexture"]:SetInside()
	end

	E:SecureHook("StaticPopup_SetUpPosition")
	E:SecureHook("StaticPopup_CollapseTable")
end