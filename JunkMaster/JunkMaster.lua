
TEXT_DISPLAY_X_OFFSET = -247;
TEXT_DISPLAY_Y_OFFSET = -7;
TEXT_DISPAY_HEIGHT = 50;
TEXT_DISPLAY_WIDTH = 50;


local JM = CreateFrame("Frame", "JM", UIParent);
JM:SetFrameStrata("HIGH");
JM:SetPoint("BOTTOMRIGHT");
JM:SetHeight(TEXT_DISPAY_HEIGHT);
JM:SetWidth(TEXT_DISPLAY_WIDTH);

local JM_Texture = JM:CreateTexture("JM_Texture", "OVERLAY");
JM_Texture:SetPoint("BOTTOMRIGHT", JM, "BOTTOMRIGHT", TEXT_DISPLAY_X_OFFSET, TEXT_DISPLAY_Y_OFFSET);
JM_Texture:SetColorTexture(0.22, 0.22, 0.22, 0);
JM_Texture:SetAlpha(1);
JM_Texture:SetHeight(TEXT_DISPAY_HEIGHT);
JM_Texture:SetWidth(TEXT_DISPLAY_WIDTH);

function JM:OnEvent(event, ...)
    if ( event == "PLAYER_LOGIN" ) then
        self:Initialize();
    elseif ( event == "MERCHANT_SHOW" ) then
        self:SellJunk();
    elseif ( event == "BAG_UPDATE" ) then
        local remaining = self:SlotsRemaining();
        remainingSlotsText:SetFormattedText("%d", remaining);
    end
end

JM:SetScript("OnEvent", JM.OnEvent);

if ( IsLoggedIn() ) then
    JM:Initialize();
else
    JM:RegisterEvent("PLAYER_LOGIN");
end

function JM:Initialize()
    self:RegisterEvent("MERCHANT_SHOW");
    self:RegisterEvent("BAG_UPDATE");
    self:CreateFrame();
    print('JunkMaster v1.0.1');
end

function JM:CreateFrame()
    local remaining = self:SlotsRemaining();
    remainingSlotsText = self:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    remainingSlotsText:SetTextColor(1,1,1,1);
    remainingSlotsText:SetFormattedText("%d", remaining);
    remainingSlotsText:SetPoint("CENTER", TEXT_DISPLAY_X_OFFSET, TEXT_DISPLAY_Y_OFFSET);
end

-- Cycle through all bags and slots and sells poor quality items
-- Happens when players interacts with Merchant.
function JM:SellJunk()
    local foundJunk = false;
    for i=0,4 do
        local bagSlots = GetContainerNumSlots(i);
        for j=1,bagSlots do
            local icon, itemCount, locked, quality, readable, lootable, itemLink, isFiltered, noValue, itemID = GetContainerItemInfo(i, j);
            if ( itemLink ~= nil and quality == 0 ) then
                if ( not foundJunk ) then
                    foundJunk = true;
                    print("Selling Junk...");
                end
                UseContainerItem(i, j);
            end
        end
    end
end

function JM:SlotsRemaining()
    local slotsRemaining = 0;
    for bag=0,4 do
        local numFreeSlots = GetContainerNumFreeSlots(bag);
        if ( numFreeSlots ~= nil ) then
            slotsRemaining = slotsRemaining + numFreeSlots;
        end
    end
    return slotsRemaining;
end

function JM:ItemQuality(id)
    local ITEM_QUALITY = {
        [0] = "Poor",
        [1] = "Common",
        [2] = "Uncommon",
        [3] = "Rare",
        [4] = "Epic",
        [5] = "Legendary"
    }
    return ITEM_QUALITY[id];
end
