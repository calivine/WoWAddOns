SLASH_BAGAUDIT1 = "/bagaudit";

SlashCmdList["BAGAUDIT"] = function()
    for bag=0,4 do
        local bagSlots = GetContainerNumSlots(bag);
        print(GetBagName(bag));
        print(bagSlots);
        for slot=1,bagSlots do
            local icon, itemCount, locked, quality, readable, lootable, itemLink, isFiltered, noValue, itemID = GetContainerItemInfo(bag, slot);
            if ( itemLink ~= nil ) then
                print(itemLink, self:ItemQuality(quality));
            end
        end
    end
end

local JM = CreateFrame("Frame", "JM", UIParent);

function JM:OnEvent(event, ...)
    if ( event == "PLAYER_LOGIN" ) then
        self:Initialize();
    elseif ( event == "MERCHANT_SHOW" ) then
        self:SellJunk();
    end
end

JM:SetScript("OnEvent", JM.OnEvent);

if ( IsLoggedIn() ) then
    JM:Initialize();
else
    JM:RegisterEvent("PLAYER_LOGIN");
end

function JM:Initialize()
    self:RegisterEvent("MERCHANT_SHOW")
end

-- Cycle through all bags and slots and sells poor quality items
-- Happens when players interacts with Merchant.
function JM:SellJunk()
    for i=0,4 do
        local bagSlots = GetContainerNumSlots(i);
        for j=1,bagSlots do
            local icon, itemCount, locked, quality, readable, lootable, itemLink, isFiltered, noValue, itemID = GetContainerItemInfo(i, j);
            if ( itemLink ~= nil and quality == 0 ) then
                UseContainerItem(i, j);
            end
        end
    end
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
