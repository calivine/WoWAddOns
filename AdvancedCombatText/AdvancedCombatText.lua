NUM_ADV_COMBAT_TEXT_LINES = 5;
ADV_COMBAT_TEXT_SCROLLSPEED = 2.0;
ADV_COMBAT_TEXT_FADEOUT_TIME = 1.1;
ADV_COMBAT_TEXT_HEIGHT = 15;
ADV_COMBAT_TEXT_LOCATIONS = {};
ADV_COMBAT_TEXT_SPACING = 10;
ADV_COMBAT_TEXT_MAX_OFFSET = 130;
ADV_COMBAT_TEXT_X_ADJUSTMENT = 80;
ADV_COMBAT_TEXT_X_SCALE = 1;
ADV_COMBAT_TEXT_Y_SCALE = 1;
ADV_COMBAT_TEXT_TO_ANIMATE = {};
ADV_COMBAT_TEXT_RANGEFINDER = 0;
ADV_COMBAT_TEXT_COOLDOWN = 0;

COOLDOWN_TEXT = {};
COOLDOWN_TEXT["Fire Blast"] = {var = "Fire Blast", enabled = 0, countdown = nil, endTime = nil};
COOLDOWN_TEXT["Blink"] = {var = "Blink", enabled = 0, countdown = nil, endTime = nil};
COOLDOWN_TEXT["Frost Nova"] = {var = "Frost Nova", enabled = 0, countdown = nil, endTime = nil};

ADV_COMBAT_TEXT_TYPE_INFO = {};
ADV_COMBAT_TEXT_TYPE_INFO["ENTERING_COMBAT"] = {r = 1, g = 0.1, b = 0.1, var = "COMBAT_TEXT_SHOW_COMBAT_STATE"};
ADV_COMBAT_TEXT_TYPE_INFO["LEAVING_COMBAT"] = {r = 0.1, g = 1, b = 0.1, var = "COMBAT_TEXT_SHOW_COMBAT_STATE"};
ADV_COMBAT_TEXT_TYPE_INFO["CASTING"] = {r = 0.1, g = 1, b = 0.1, var = "COMBAT_TEXT_SHOW_COMBAT_STATE"};
ADV_COMBAT_TEXT_TYPE_INFO["RANGEFINDER"] = {r = 0.1, g = 1, b = 0.1, var = "COMBAT_TEXT_SHOW_COMBAT_STATE"};
ADV_COMBAT_TEXT_TYPE_INFO["COOLDOWN"] = {r = 0.1, g = 0.1, b = 1, var = "COMBAT_TEXT_SHOW_COMBAT_STATE"};




function AdvancedCombatText_OnLoad(self)
    AdvancedCombatText_UpdateDisplayedMessages();
    AdvancedCombatText.xDir = 1;
end

function AdvancedCombatText_OnEvent(self, event, ...)
    local arg1, arg2, arg3, arg4 = ...;
    
    local messageType, message;
    if event == "PLAYER_TARGET_CHANGED" then
        messageType = "RANGEFINDER";
        if ADV_COMBAT_TEXT_RANGEFINDER == 1 then
            ADV_COMBAT_TEXT_RANGEFINDER = 0;
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        messageType = "ENTERING_COMBAT";
    elseif event == "PLAYER_REGEN_ENABLED" then
        messageType = "LEAVING_COMBAT";
    elseif event == "UNIT_SPELLCAST_START" then
        messageType = "CASTING";
        AdvancedCombatText_SheepTarget(arg3);
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        messageType = "COOLDOWN";
        ADV_COMBAT_TEXT_COOLDOWN = 1;
    end

    if messageType == "ENTERING_COMBAT" then
        message = "PREPARE FOR ACTION";
    elseif messageType == "LEAVING_COMBAT" then
        message = "LEAVING COMBAT";
    else
        message = "";
    end
    
    -- Get text color info 
    local info = ADV_COMBAT_TEXT_TYPE_INFO[messageType];
    if event == "UNIT_SPELLCAST_START" or event == "SPELL_UPDATE_COOLDOWN" then
        return;
    else
        AdvancedCombatText_AddMessage(message, ADV_COMBAT_TEXT_SCROLL_FUNCTION, info.r, info.g, info.b);
    end
end

function AdvancedCombatText_OnUpdate(self, elapsed)
    local lowestMessage = ADV_COMBAT_TEXT_LOCATIONS.startY;
    local alpha, xPos, yPos;
    if not UnitAffectingCombat("player")  then
        if UnitIsEnemy("player", "target") then
            local actionType, id, subType = GetActionInfo(1);
            if actionType == "spell" then
                local name, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(id);
                if IsSpellInRange(name,"target") == 1 and ADV_COMBAT_TEXT_RANGEFINDER == 0 then
                    ADV_COMBAT_TEXT_RANGEFINDER = 1;
                    -- print(format("%s is within range!", name));
                    local Rmessage = format("%s IN RANGE", name);
                    AdvancedCombatText_AddMessage(Rmessage, ADV_COMBAT_TEXT_SCROLL_FUNCTION, 1, 0.1, 0.1);
                elseif IsSpellInRange(name,"target") == 0 and ADV_COMBAT_TEXT_RANGEFINDER == 1 then
                    ADV_COMBAT_TEXT_RANGEFINDER = 0;
                end
            end
        end
    end
    if ADV_COMBAT_TEXT_COOLDOWN == 1 then
        for index, value in pairs(COOLDOWN_TEXT) do
            if value.enabled == 0 then
                -- Check if spell has a countdown
                local start, duration, enabled, modRate = GetSpellCooldown(value.var);
                if enabled == 1 and duration > 2 then
                    value.countdown = start + elapsed;
                    value.endTime = start + duration;
                    value.enabled = 1;
                    ADV_COMBAT_TEXT_COOLDOWN = 1;
                end
            elseif value.enabled == 1 then
                if value.countdown >= value.endTime then
                    local countdownMessage = value.var.." is ready";
                    AdvancedCombatText_AddMessage(countdownMessage, ADV_COMBAT_TEXT_SCROLL_FUNCTION, 0.1, 0.1, 1);
                    value.enabled = 0;
                    ADV_COMBAT_TEXT_COOLDOWN = 0;
                    value.countdown = nil;
                    value.endTime = nil;
                else
                    value.countdown = value.countdown + elapsed;
                end
            end
        end
    end
            
    for index, value in pairs(ADV_COMBAT_TEXT_TO_ANIMATE) do
        
        if ( value.scrollTime >= ADV_COMBAT_TEXT_SCROLLSPEED ) and value:GetText() ~= nil then -- 
            AdvancedCombatText_RemoveMessage(value);
        else
            value.scrollTime = value.scrollTime + elapsed;
            -- Calculate x and y positions
            xPos, yPos = value.scrollFunction(value);
    
            -- Record Y position
            value.yPos = yPos;
            value:SetPoint("TOP", WorldFrame, "BOTTOM", xPos, yPos);
            if ( value.scrollTime >= ADV_COMBAT_TEXT_FADEOUT_TIME ) then
                alpha = 1-((value.scrollTime-ADV_COMBAT_TEXT_FADEOUT_TIME)/(ADV_COMBAT_TEXT_SCROLLSPEED-ADV_COMBAT_TEXT_FADEOUT_TIME));
                alpha = max(alpha, 0);
                value:SetAlpha(alpha);
            end
    
        end
    end
    if ( (ADV_COMBAT_TEXT_Y_SCALE ~= WorldFrame:GetHeight() / 768) or (ADV_COMBAT_TEXT_X_SCALE ~= WorldFrame:GetWidth() / 1024) ) then
        print("Updating...");
        AdvancedCombatText_UpdateDisplayedMessages();
    end
end

function AdvancedCombatText_AddMessage(message, scrollFunction, r, g, b)
    local string, noStringsAvailable = AdvancedCombatText_GetAvailableString();
    if ( noStringsAvailable ) then
        return;
    end

    --string = _G["AdvancedCombatText1"];
    --if string:IsShown() then
    --    AdvancedCombatText_RemoveMessage(string);
    --end

    string:SetText(message);
    string:SetTextColor(r,g,b);
    string.scrollTime = 0;
    string.scrollFunction = scrollFunction;

    --if string:GetText() == nil then
    --    string.inRange = 0;
    --else
    --    string.inRange = nil;
    --end


    local lowestMessage;
    local useXadjustment = 1;

    lowestMessage = string:GetBottom();

    string.xDir = AdvancedCombatText.xDir;
    string.startX = ADV_COMBAT_TEXT_LOCATIONS.startX + (useXadjustment * ADV_COMBAT_TEXT_X_ADJUSTMENT);
    string.startY = lowestMessage;
    string.yPos = lowestMessage;
    string:ClearAllPoints();
    string:SetPoint("TOP", WorldFrame, "BOTTOM", string.startX, lowestMessage);
    string:SetAlpha(1);
    string:Show();
    tinsert(ADV_COMBAT_TEXT_TO_ANIMATE, string);
end

function AdvancedCombatText_RemoveMessage(string)
    for index, value in pairs(ADV_COMBAT_TEXT_TO_ANIMATE) do
        if ( value == string ) then
            tremove(ADV_COMBAT_TEXT_TO_ANIMATE, index);
            --string:SetText("");
            string:SetAlpha(0);
            string:Hide();
            string:SetPoint("TOP", WorldFrame, "BOTTOM", ADV_COMBAT_TEXT_LOCATIONS.startX, ADV_COMBAT_TEXT_LOCATIONS.startY);
            break;
        end
    end
end

function AdvancedCombatText_GetAvailableString()
    local string;
    for i=1, NUM_ADV_COMBAT_TEXT_LINES do
        string = _G["AdvancedCombatText"..i];
        if ( not string:IsShown() ) then
            return string;
        end
    end
    return AdvancedCombatText_GetOldestString(), 1;
end

function AdvancedCombatText_GetOldestString()
    local oldestString = ADV_COMBAT_TEXT_TO_ANIMATE[1];
    AdvancedCombatText_RemoveMessage(oldestString);
    return oldestString;
end

function AdvancedCombatText_ClearAnimationList()
    local string;
    for i=1, NUM_ADV_COMBAT_TEXT_LINES do
        string = _G["AdvancedCombatText"..i];
        string:SetAlpha(0);
        string:Hide();
        string:SetPoint("TOP", WorldFrame, "BOTTOM", ADV_COMBAT_TEXT_LOCATIONS.startX, ADV_COMBAT_TEXT_LOCATIONS.startY);   
    end
end

function AdvancedCombatText_UpdateDisplayedMessages()
    -- Set Unit to track
    CombatTextSetActiveUnit("player");

    -- Register events
    AdvancedCombatText:RegisterEvent("PLAYER_REGEN_DISABLED");
    AdvancedCombatText:RegisterEvent("PLAYER_REGEN_ENABLED");
    AdvancedCombatText:RegisterEvent("UNIT_SPELLCAST_START");
    AdvancedCombatText:RegisterEvent("PLAYER_TARGET_CHANGED");
    AdvancedCombatText:RegisterEvent("SPELL_UPDATE_COOLDOWN");

    -- Get scale
    ADV_COMBAT_TEXT_Y_SCALE = WorldFrame:GetHeight() / 768;
    ADV_COMBAT_TEXT_X_SCALE = WorldFrame:GetWidth() / 1024;
    ADV_COMBAT_TEXT_SPACING = 10 * ADV_COMBAT_TEXT_Y_SCALE;
    ADV_COMBAT_TEXT_MAX_OFFSET = 130 * ADV_COMBAT_TEXT_Y_SCALE;
    ADV_COMBAT_TEXT_X_ADJUSTMENT = 80 * ADV_COMBAT_TEXT_X_SCALE;

    -- Update shown messages
    for index, value in pairs(ADV_COMBAT_TEXT_TYPE_INFO) do
        if ( value.var ) then
            if ( _G[value.var] == "1" ) then
                value.show = 1;
            else
                value.show = nil;
            end
        end
    end

    -- Update scrolldirection
    ADV_COMBAT_TEXT_SCROLL_FUNCTION = AdvancedCombatText_FountainScroll;
    ADV_COMBAT_TEXT_LOCATIONS = {
        startX = 0,
        startY = 384 * ADV_COMBAT_TEXT_Y_SCALE,
        endX = 0,
        endY = 609 * ADV_COMBAT_TEXT_Y_SCALE
    };

    -- Clear Animations
    AdvancedCombatText_ClearAnimationList();
end

function AdvancedCombatText_StandardScroll(value)
    -- Calculate x and y positions
    local xPos = value.startX+((ADV_COMBAT_TEXT_LOCATIONS.endX - ADV_COMBAT_TEXT_LOCATIONS.startX)*value.scrollTime/ADV_COMBAT_TEXT_SCROLLSPEED);
    local yPos = value.startY+((ADV_COMBAT_TEXT_LOCATIONS.endY - ADV_COMBAT_TEXT_LOCATIONS.startY)*value.scrollTime/ADV_COMBAT_TEXT_SCROLLSPEED);
    return xPos, yPos;
end

function AdvancedCombatText_FountainScroll(value)
    -- Calculate x and y positions
    local radius = 150;
    local xPos = value.startX-value.xDir*(radius*(1-cos(90*value.scrollTime/ADV_COMBAT_TEXT_SCROLLSPEED)));
    local yPos = value.startY+radius*sin(90*value.scrollTime/ADV_COMBAT_TEXT_SCROLLSPEED);
    return xPos, yPos;
end

function AdvancedCombatText_SheepTarget(value)
    local name, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(value);
    local target, realm = UnitName("target");
    -- local isTanking, status, threatpct, rawthreatpct, threatvalue = UnitDetailedThreatSituation("player", "target");
    if name == "Polymorph" then
        if IsInGroup() then
            if random(1,2) == 1 then
                SendChatMessage("Casting "..format("%s",name).." on "..format("%s",target), "PARTY");
            else
                SendChatMessage("Sheeping "..format("%s",target), "PARTY");
            end
        else
            SendChatMessage("Casting "..format("%s",name).." on "..format("%s",target), "SAY");
        end
        -- print("Casting "..format("%s",name).." on "..format("%s",target));
        SetRaidTarget("target",5);
    end
end

function AdvancedCombatText_PullSpellInfo(actionNum, ret)
    local actionType, id, subType = GetActionInfo(actionNum);
    local name, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(id);
    if ret == "all" then
        return name, rank, icon, castTime, minRange, maxRange, spellId;
    elseif ret == "name" then
        return name;
    elseif ret == "rank" then
        return rank;
    elseif ret == "icon" then
        return icon;
    elseif ret == "castTime" then
        return castTime;
    elseif ret == "spellId" then
        return spellId;
    else
        print("Second argument must be variable from 'GetSpellInfo' payload");
        return nil;
    end
end


