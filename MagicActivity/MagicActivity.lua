local MagicActivity = CreateFrame("Frame", "MagicActivity", UIParent);

MagicActivity:SetFrameStrata("LOW");
MagicActivity:SetPoint("RIGHT");
MagicActivity:SetWidth("175");
MagicActivity:SetHeight("100");

function MagicActivity_OnLoad(self)
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
    SESSION_KILL_COUNT = 0;
    print(SESSION_KILL_COUNT);
end

MagicActivity:SetScript("OnLoad", MagicActivity_OnLoad);

