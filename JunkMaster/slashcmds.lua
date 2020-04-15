ITEM_QUALITY = {
    [0] = "Poor",
    [1] = "Common",
    [2] = "Uncommon",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary"
}


SLASH_BAGAUDIT1 = "/bagaudit";

SlashCmdList["BAGAUDIT"] = function()
    for bag=0,4 do
        local bagSlots = GetContainerNumSlots(bag);
        print(GetBagName(bag));
        print(bagSlots, '\n');
        for slot=1,bagSlots do
            local icon, itemCount, locked, quality, readable, lootable, itemLink, isFiltered, noValue, itemID = GetContainerItemInfo(bag, slot);
            if ( itemLink ~= nil ) then
                print(itemLink, ITEM_QUALITY[quality]);
            end
        end
    end
end

SLASH_SPACE1 = "/space";

SlashCmdList["SPACE"] = function()
    local slotsRemaining = 0;
    for bag=0,4 do
        slotsRemaining = slotsRemaining + GetContainerNumFreeSlots(bag);
    end
    print("Remaing bag slots: ", slotsRemaining);
end