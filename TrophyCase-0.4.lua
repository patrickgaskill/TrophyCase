TROPHYCASE_ITEMS_TO_DISPLAY = 9;
TROPHYCASE_BUTTON_HEIGHT = 37;
TROPHYCASE_RANKS_TO_STORE = 25;
TROPHYCASE_SLOT_LIST = { "HeadSlot", "NeckSlot", "ShoulderSlot",
						 "BackSlot", "ChestSlot", "TabardSlot",
						 "WristSlot", "HandsSlot", "WaistSlot",
						 "LegsSlot", "FeetSlot", "Finger0Slot",
						 "Finger1Slot", "Trinket0Slot", "Trinket1Slot",
						 "MainHandSlot", "SecondaryHandSlot", "RangedSlot" };

--------------------------------------------------------------------------------
-- User functions
--------------------------------------------------------------------------------

function ToggleTrophyCase()
	if ( TrophyCase:IsShown() ) then
		HideUIPanel(TrophyCase);
	else
		TrophyCase_ScanItems();
		ShowUIPanel(TrophyCase);
	end
end

function ToggleTrophyCaseDebug()
	if ( TrophyCaseDebug == 1 ) then
		DEFAULT_CHAT_FRAME:AddMessage("TrophyCase: Debug messages are now OFF.");
		TrophyCaseDebug = 0;
	else
		DEFAULT_CHAT_FRAME:AddMessage("TrophyCase: Debug messages are now ON.");
		TrophyCaseDebug = 1;
	end
end

function ResetTrophyCase()
	TrophyCaseDB = nil;
	TrophyCase_InitializeDB();
end

--------------------------------------------------------------------------------
-- Frame functions
--------------------------------------------------------------------------------

function TrophyCase_Update()
	TrophyCase_DebugPrint("TrophyCase_Update");
	local numItems = # TrophyCaseDB.items;
	
	local showScrollBar = nil;
	if ( numItems > TROPHYCASE_ITEMS_TO_DISPLAY ) then
		showScrollBar = 1;
	end
	
	local itemOffset = FauxScrollFrame_GetOffset(TrophyCaseScrollFrame);
	local itemIndex;
	
	for i = 1, TROPHYCASE_ITEMS_TO_DISPLAY do
		itemIndex = itemOffset + i;

		 TrophyCase_DebugPrint("i <" .. i .. "> index<" .. itemIndex .. "> offset<" .. itemOffset ..">");

		if ( TrophyCaseDB.items[itemIndex] ) then
		
			-- Check if link is good on this server
			local itemName, itemLink, itemQuality, itemLevel, _, _, _, _, _, itemTexture = GetItemInfo(TrophyCaseDB.items[itemIndex].link);
			
			if ( itemName ) then
				-- Use information from fresh GetItemInfo
				--TrophyCase_DebugPrint("i=" .. i .. " itemOffset=" .. itemOffset .. " itemIndex=" .. itemIndex .. "<" .. itemName .. "> <" .. itemLink .. "> <" .. itemQuality .. "> <" .. itemLevel .. ">");
				local color = ITEM_QUALITY_COLORS[itemQuality];
				getglobal("TrophyCaseButton" .. i .. "ItemIconTexture"):SetTexture(itemTexture);
				getglobal("TrophyCaseButton" .. i .. "Name"):SetText(itemName);
				getglobal("TrophyCaseButton" .. i .. "Name"):SetVertexColor(color.r, color.g, color.b);
				getglobal("TrophyCaseButton" .. i .. "Level"):SetText(itemLevel);
			else
				-- Use the cached version in the database
				TrophyCase_DebugPrint("weird setting for button " .. i .. " itemIndex=" .. itemIndex .. " itemOffset=" .. itemOffset);
				--TrophyCase_DebugPrint("<" .. itemName .. "> <" .. itemLink .. "> <" .. itemQuality .. "> <" .. itemLevel .. ">");
				getglobal("TrophyCaseButton" .. i .. "ItemIconTexture"):SetTexture(TrophyCaseDB.items[itemIndex].texture);
				getglobal("TrophyCaseButton" .. i .. "Name"):SetText(TrophyCaseDB.items[itemIndex].name);
				getglobal("TrophyCaseButton" .. i .. "Level"):SetText(TrophyCaseDB.items[itemIndex].level);
			end
			
			getglobal("TrophyCaseButton" .. i .. "Character"):SetText(TrophyCaseDB.items[itemIndex].character);
			getglobal("TrophyCaseButton" .. i .. "Realm"):SetText(TrophyCaseDB.items[itemIndex].realm);
		else
			TrophyCase_DebugPrint("trying to hide TrophyCaseButton" .. i);
			--HideUIPanel("TrophyCaseButton" .. i);
			getglobal("TrophyCaseButton" .. i .. "ItemIconTexture"):SetTexture(nil);
			getglobal("TrophyCaseButton" .. i .. "Name"):SetText(nil);
			getglobal("TrophyCaseButton" .. i .. "Name"):SetVertexColor(nil);
			getglobal("TrophyCaseButton" .. i .. "Level"):SetText(nil);
			
		end
	end
	
	FauxScrollFrame_Update(TrophyCaseScrollFrame, numItems, TROPHYCASE_ITEMS_TO_DISPLAY, TROPHYCASE_BUTTON_HEIGHT);
end

function TrophyCase_OnLoad()
	--	TrophyCase_DebugPrint("TrophyCase_OnLoad");
	
	this:RegisterEvent("AUTOEQUIP_BIND_CONFIRM");
	this:RegisterEvent("EQUIP_BIND_CONFIRM");
	this:RegisterEvent("LOOT_BIND_CONFIRM");
	this:RegisterEvent("BANKFRAME_OPENED");
	this:RegisterEvent("ITEM_PUSH");
	--this:RegisterEvent("LOOT_SLOT_CLEARED");
	this:RegisterEvent("QUEST_FINISHED");
	this:RegisterEvent("VARIABLES_LOADED");
	
	this:SetAttribute("UIPanelLayout-defined", true);
	this:SetAttribute("UIPanelLayout-enabled", true);
	this:SetAttribute("UIPanelLayout-area", "left");
	this:SetAttribute("UIPanelLayout-pushable", 5);
	this:SetAttribute("UIPanelLayout-whileDead", true);
	
	SLASH_TROPHYCASE1 = "/trophy";
	SLASH_TROPHYCASE2 = "/trophies";
	SlashCmdList["TROPHYCASE"] = ToggleTrophyCase;
end

function TrophyCase_OnEvent(event)
	TrophyCase_DebugPrint("TrophyCase_OnEvent <" .. event .. ">");
	if ( event == "BANKFRAME_OPENED" or
	     event == "ITEM_PUSH" or
	     event == "QUEST_FINISHED" or
	 	 event == "AUTOEQUIP_BIND_CONFIRM" or
		 event == "EQUIP_BIND_CONFIRM" or
		 event == "LOOT_BIND_CONFIRM" ) then
		TrophyCase_ScanItems();
	elseif ( event == "VARIABLES_LOADED" ) then
		TrophyCase_InitializeDB();
	end
end

function TrophyCase_OnShow()
--	TrophyCase_DebugPrint("TrophyCase_OnShow");
	TrophyCase_Update();
	PlaySound("igSpellBookOpen");
end

function TrophyCase_OnHide()
--	TrophyCase_DebugPrint("TrophyCase_OnHide");
	PlaySound("igSpellBookClose");
end

function TrophyCaseItem_OnEnter(index)
	if ( TrophyCaseDB.items[index] ) then
		GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT");
		GameTooltip:SetHyperlink(TrophyCaseDB.items[index].link);
	end
end

--------------------------------------------------------------------------------
-- Data functions
--------------------------------------------------------------------------------

function TrophyCase_ScanItems()
	TrophyCase_DebugPrint("Scanning...");
	-- TODO: can we tell from the link if an item still exists?

	-- Scan the player's bags, including bank bags and keyring
	for bagID = KEYRING_CONTAINER, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do

		-- Scan the bags themselves (but not the keyring or backpack)
		if ( bagID > 0 ) then
			local containerID = ContainerIDToInventoryID(bagID);
			local itemLink = GetInventoryItemLink("player", containerID);
			
			if ( itemLink ) then
				TrophyCaseScanningTooltip:SetInventoryItem("player", containerID);

				-- TODO: check for "This item starts a quest"?
				if ( TrophyCaseScanningTooltipTextLeft2:GetText() == ITEM_SOULBOUND ) then
					--TrophyCase_DebugPrint("bag:" .. bagID .. " inv:" .. containerID .. " " .. itemLink .. " soulbound");
					TrophyCase_CheckItem(itemLink);
				end
			
			end
		end
		
		-- Scan the slots inside each bag
		for slot = 1, GetContainerNumSlots(bagID) do
			local itemLink = GetContainerItemLink(bagID, slot);
			local isSoulbound = 0;
			
			if ( itemLink ) then
				TrophyCaseScanningTooltip:SetBagItem(bagID, slot);

				if ( TrophyCaseScanningTooltipTextLeft2:GetText() == ITEM_SOULBOUND ) then
					--TrophyCase_DebugPrint("   " .. itemLink .. " soulbound");
					TrophyCase_CheckItem(itemLink);
				end				
			
			end
		end
	end
	
	-- Scan each equipment slot
	for i, slotName in ipairs(TROPHYCASE_SLOT_LIST) do
		local itemLink = GetInventoryItemLink("player", GetInventorySlotInfo(slotName));
		local isSoulbound = 0;
		
		if ( itemLink  ) then
			TrophyCaseScanningTooltip:SetInventoryItem("player", GetInventorySlotInfo(slotName));
			
			if ( TrophyCaseScanningTooltipTextLeft2:GetText() == ITEM_SOULBOUND ) then
				--TrophyCase_DebugPrint(slotName .. ": " .. itemLink .. " soulbound");
				TrophyCase_CheckItem(itemLink);
			end

		end
	end
	
	TrophyCase_Update();
end

function TrophyCase_CheckItem(itemLink)
	if ( itemLink == nil ) then
		return;
	end
	
	local itemName, _, itemQuality, itemLevel, _, _, _, itemStackCount, _, itemTexture = GetItemInfo(itemLink);

	-- Check if it is at least an epic and is nonstackable
	if ( itemQuality < 4 or itemStackCount > 1 ) then
		return;
	end
	
	TrophyCase_DebugPrint("*** CHECKING " .. itemLink);
	
	local playerName, _ = UnitName("player");
	local realmName = GetRealmName();
	local itemCount = # TrophyCaseDB.items;
	
	local newItemRef = {
		["name"] = itemName,
		["quality"] = itemQuality,
		["level"] = itemLevel,
		["texture"] = itemTexture,
		["link"] = itemLink,
		["character"] = playerName,
		["realm"] = realmName
	};
	
	-- Check for duplicates
	
	local alreadyExists = false;
	local needsUpdate = false;
	
	--[[local _, _, string1 = string.find(itemLink, "^|c%x+|H(.+)|h%[.+%]");
	TrophyCase_DebugPrint("<" .. itemLink .. "> <" .. string1 .. ">");
	for i, itemRef in ipairs(TrophyCaseDB.items) do

		TrophyCase_ItemsMatch(itemLink, itemRef.link);
	
	
		local _, _, string2 = string.find(itemRef.link, "^|c%x+|H(.+)|h%[.+%]");
		
		if ( string1 == string2 and playerName == itemRef.character and realmName == itemRef.realm ) then
			alreadyExists = true;
			TrophyCase_DebugPrint("alreadyExists");
			break;
		end
	end
	]]

	for i, itemRef in ipairs(TrophyCaseDB.items) do
		if ( TrophyCase_ItemsMatch(itemLink, itemRef.link) and
			 playerName == itemRef.character and
			 realmName == itemRef.realm ) then
			
			if ( not itemLink == itemRef.link ) then
				TrophyCase_DebugPrint("needsUpdate = true");
				needsUpdate = true;
			end
			
			alreadyExists = true;
			TrophyCase_DebugPrint("alreadyExists = true");
			break;
		end
	end

	if ( alreadyExists ) then
		if ( needsUpdate ) then
			DEFAULT_CHAT_FRAME:AddMessage("Updating " .. itemLink .. " in your trophy case.", HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
			table.remove(TrophyCaseDB.items, i);
			table.insert(TrophyCaseDB.items, newItemRef);
		end
	else
		--TrophyCase_DebugPrint("Inserting " .. itemLink);
		DEFAULT_CHAT_FRAME:AddMessage("Added " .. itemLink .. " to your trophy case.", HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		table.insert(TrophyCaseDB.items, newItemRef);
	end
	
	table.sort(TrophyCaseDB.items, function(a, b)
		if ( a.level == b.level ) then
			if ( a.quality == b.quality ) then
				return (a.name < b.name)
			else
				return (a.quality > b.quality)
			end
		else
			return (a.level > b.level)
		end
	end);
	
end

function TrophyCase_ItemsMatch(link1, link2)
	--TrophyCase_DebugPrint("ItemsMatch <" .. link1 .. "> <" .. link2 .. ">");
	local _, _, string1 = string.find(link1, "^|c%x+|H(.+)|h%[.+%]");
	local _, _, string2 = string.find(link2, "^|c%x+|H(.+)|h%[.+%]");
	
	local _, itemId1, _, _, _, _, _, _, uniqueId1 = strsplit(":", string1);
	local _, itemId2, _, _, _, _, _, _, uniqueId2 = strsplit(":", string2);

	return ( itemId1 == itemId2 and uniqueId1 == uniqueId2 );
end

function TrophyCase_InitializeDB()
	-- Configure default values
	if ( not TrophyCaseDB ) then
		TrophyCaseDB = {
			items = {}
		};
	elseif ( not TrophyCaseDB.items ) then
		TrophyCaseDB.items = {};
	end
	
	if ( not TrophyCaseDebug ) then
		TrophyCaseDebug = 0;
	end

	TrophyCase_ScanItems();
end


function TrophyCase_DebugPrint(msg)
	if ( TrophyCaseDebug == 1 ) then
		DEFAULT_CHAT_FRAME:AddMessage(msg);
	end
end