THREAT_TEXT_SCROLLSPEED = 2.0;
THREAT_TEXT_FADEOUT_TIME = 1.1;
THREAT_TEXT_HEIGHT = 25;
THREAT_TEXT_LOCATIONS = {};
THREAT_TEXT_SPACING = 10;
THREAT_TEXT_MAX_OFFSET = 130;
THREAT_TEXT_X_ADJUSTMENT = 80;
THREAT_TEXT_X_SCALE = 1;
THREAT_TEXT_Y_SCALE = 1;
THREAT_TEXT_TO_ANIMATE = {};

THREAT_TEXT_TYPE_INFO = {};
THREAT_TEXT_TYPE_INFO["ENTERING_COMBAT"] = {r = 1, g = 0.1, b = 0.1, var = "COMBAT_TEXT_SHOW_COMBAT_STATE"};
THREAT_TEXT_TYPE_INFO["LEAVING_COMBAT"] = {r = 0.1, g = 1, b = 0.1, var = "COMBAT_TEXT_SHOW_COMBAT_STATE"};
THREAT_TEXT_TYPE_INFO["THREAT_UPDATE"] = {r = 0.1, g = 1, b = 0.1, var = "COMBAT_TEXT_SHOW_COMBAT_STATE"};
THREAT_TEXT_TYPE_INFO["IN_RANGE"] = {r = 0.1, g = 1, b = 0.1, var = "COMBAT_TEXT_SHOW_COMBAT_STATE"};


function ThreatText_OnLoad(self)
    ThreatText_UpdateDisplayedMessages();
    ThreatText.xDir = 1;
end

function ThreatText_OnEvent(self, event, ...)
    local arg1, arg2, arg3, arg4 = ...;
    
    local messageType, message;

    if event == "PLAYER_REGEN_DISABLED" then
        messageType = "ENTERING_COMBAT";
    elseif event == "PLAYER_REGEN_ENABLED" then
        messageType = "LEAVING_COMBAT";
    elseif event == "UNIT_SPELLCAST_START" then
        messageType = "THREAT_UPDATE";
        local name, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(arg3);
        local target, realm = UnitName("target");
        -- local isTanking, status, threatpct, rawthreatpct, threatvalue = UnitDetailedThreatSituation("player", "target");
        if name == "Polymorph" then
            if IsInGroup() then
                SendChatMessage("Casting "..format("%s",name).." on "..format("%s",target), "PARTY");
            else
                SendChatMessage("Casting "..format("%s",name).." on "..format("%s",target), "SAY");
            end
            -- print("Casting "..format("%s",name).." on "..format("%s",target));
            SetRaidTarget("target",5);
        end
    elseif event == "UNIT_TARGET" then
        messageType = "IN_RANGE";
        if UnitIsEnemy("player", "target") then
            local spellRange = IsSpellInRange("frostbolt","target");
            if spellRange == 1 then
                print("Frostbolt is within range!");
            end
        end  
    end

    if messageType == "ENTERING_COMBAT" then
        message = "PREPARE FOR ACTION";
    elseif messageType == "LEAVING_COMBAT" then
        message = "LEAVING COMBAT";
    else
        message = "";
    end
    
    local info = THREAT_TEXT_TYPE_INFO[messageType];
    
    ThreatText_AddMessage(message, THREAT_TEXT_SCROLL_FUNCTION, info.r, info.g, info.b);
end

function ThreatText_OnUpdate(self, elapsed)
    local lowestMessage = THREAT_TEXT_LOCATIONS.startY;
    local alpha, xPos, yPos;
    for index, value in pairs(THREAT_TEXT_TO_ANIMATE) do
      if ( value.scrollTime >= THREAT_TEXT_SCROLLSPEED ) then
        ThreatText_RemoveMessage(value);
      else
        value.scrollTime = value.scrollTime + elapsed;
        -- Calculate x and y positions
        xPos, yPos = value.scrollFunction(value);
   
        -- Record Y position
        value.yPos = yPos;
   
        value:SetPoint("TOP", WorldFrame, "BOTTOM", xPos, yPos);
        if ( value.scrollTime >= THREAT_TEXT_FADEOUT_TIME ) then
          alpha = 1-((value.scrollTime-THREAT_TEXT_FADEOUT_TIME)/(THREAT_TEXT_SCROLLSPEED-THREAT_TEXT_FADEOUT_TIME));
          alpha = max(alpha, 0);
          value:SetAlpha(alpha);
        end
   
      end
    end
    if ( (THREAT_TEXT_Y_SCALE ~= WorldFrame:GetHeight() / 768) or (THREAT_TEXT_X_SCALE ~= WorldFrame:GetWidth() / 1024) ) then
        ThreatText_UpdateDisplayedMessages();
    end
end

function ThreatText_AddMessage(message, scrollFunction, r, g, b)
    local string;
    string = _G["ThreatText1"];
    if string:IsShown() then
        ThreatText_RemoveMessage(string);
    end
    string:SetText(message);
    string:SetTextColor(r,g,b);
    string.scrollTime = 0;
    string.scrollFunction = scrollFunction;

    local lowestMessage;
    local useXadjustment = 1;

    lowestMessage = string:GetBottom();

    string.xDir = ThreatText.xDir;
    string.startX = THREAT_TEXT_LOCATIONS.startX + (useXadjustment * THREAT_TEXT_X_ADJUSTMENT);
    string.startY = lowestMessage;
    string.yPos = lowestMessage;
    string:ClearAllPoints();
    string:SetPoint("TOP", WorldFrame, "BOTTOM", string.startX, lowestMessage);
    string:SetAlpha(1);
    string:Show();
    tinsert(THREAT_TEXT_TO_ANIMATE, string);
end

function ThreatText_RemoveMessage(string)
    for index, value in pairs(THREAT_TEXT_TO_ANIMATE) do
        if ( value == string ) then
          tremove(THREAT_TEXT_TO_ANIMATE, index);
          string:SetText("");
          string:SetAlpha(0);
          string:Hide();
          string:SetPoint("TOP", WorldFrame, "BOTTOM", THREAT_TEXT_LOCATIONS.startX, THREAT_TEXT_LOCATIONS.startY);
          break;
        end
    end
end

function ThreatText_ClearAnimationList()
    local string = _G["ThreatText1"];
    string:SetAlpha(0);
    string:Hide();
    string:SetPoint("TOP", WorldFrame, "BOTTOM", THREAT_TEXT_LOCATIONS.startX, THREAT_TEXT_LOCATIONS.startY);
end

function ThreatText_UpdateDisplayedMessages()
    -- Register events
    ThreatText:RegisterEvent("PLAYER_REGEN_DISABLED");
    ThreatText:RegisterEvent("PLAYER_REGEN_ENABLED");
    ThreatText:RegisterEvent("UNIT_SPELLCAST_START");
    ThreatText:RegisterEvent("UNIT_TARGET");

    -- Get scale
    THREAT_TEXT_Y_SCALE = WorldFrame:GetHeight() / 768;
    THREAT_TEXT_X_SCALE = WorldFrame:GetWidth() / 1024;
    THREAT_TEXT_SPACING = 10 * THREAT_TEXT_Y_SCALE;
    THREAT_TEXT_MAX_OFFSET = 130 * THREAT_TEXT_Y_SCALE;
    THREAT_TEXT_X_ADJUSTMENT = 80 * THREAT_TEXT_X_SCALE;


    -- Update scrolldirection
    THREAT_TEXT_SCROLL_FUNCTION = ThreatText_StandardScroll;
    THREAT_TEXT_LOCATIONS = {
        startX = 0,
        startY = 384 * THREAT_TEXT_Y_SCALE,
        endX = 0,
        endY = 609 * THREAT_TEXT_Y_SCALE
    };

    -- Clear Animations
    ThreatText_ClearAnimationList();
end

function ThreatText_StandardScroll(value)
    -- Calculate x and y positions
    local xPos = value.startX+((THREAT_TEXT_LOCATIONS.endX - THREAT_TEXT_LOCATIONS.startX)*value.scrollTime/THREAT_TEXT_SCROLLSPEED);
    local yPos = value.startY+((THREAT_TEXT_LOCATIONS.endY - THREAT_TEXT_LOCATIONS.startY)*value.scrollTime/THREAT_TEXT_SCROLLSPEED);
    return xPos, yPos;
end

function CombatText_FountainScroll(value)
    -- Calculate x and y positions
    local radius = 150;
    local xPos = value.startX-value.xDir*(radius*(1-cos(90*value.scrollTime/THREAT_TEXT_SCROLLSPEED)));
    local yPos = value.startY+radius*sin(90*value.scrollTime/THREAT_TEXT_SCROLLSPEED);
    return xPos, yPos;
  end

