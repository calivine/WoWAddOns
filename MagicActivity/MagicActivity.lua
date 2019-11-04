local SESSION_KILL_COUNT = 0;

local MagicActivity = CreateFrame("Frame", "MagicActivity", UIParent);

MagicActivity:SetFrameStrata("LOW");
MagicActivity:SetPoint("RIGHT");
MagicActivity:SetWidth("175");
MagicActivity:SetHeight("100");



function MagicActivity:OnEvent(event, ...)
    if ( event == "COMBAT_LOG_EVENT_UNFILTERED" ) then 
        local timestamp, combatEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, args = CombatLogGetCurrentEventInfo();
        
        -- If combatEvent is not about the party, return. 
        if ( bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MASK) > COMBATLOG_OBJECT_AFFILIATION_PARTY ) then
            return;
        end



    elseif ( event == "PLAYER_LOGIN" ) then
        self:Initialize();
    end

end

MagicActivity:SetScript("OnEvent", MagicActivity.OnEvent)

if ( IsLoggedIn() ) then
    MagicActivity:Initialize();
else
    MagicActivity:RegisterEvent("PLAYER_LOGIN");
end

function MagicActivity:Initialize()
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
end

function MagicActivity:ProcessEntry(timestamp, combatEvent, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
    if ( combatEvent == "UNIT_DIED" ) then
        SESSION_KILL_COUNT = SESSION_KILL_COUNT + 1;
        -- Call updateFrame method to change display
    end
end