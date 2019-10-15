local start_time = 0;
local end_time = 0;
local total_time = 0;
local total_damage = 0;
local average_damage = 0;

function CombatTracker_OnLoad(self)
    -- Add player to party roster
    local playerID = UnitGUID("player");
    PARTY_ROSTER[1] = playerID;
    print(playerID);
    CombatTracker:RegisterEvent("PLAYER_REGEN_DISABLED");
    CombatTracker:RegisterEvent("PLAYER_REGEN_ENABLED");
    CombatTracker:RegisterEvent("UNIT_COMBAT");
    CombatTracker:RegisterForClicks("RightButtonUp");
    CombatTracker:RegisterForDrag("LeftButton"); 
end

function CombatTracker_OnEvent(self, event, ...)
    if ( event == "PLAYER_REGEN_DISABLED" ) then
        CombatTrackerText:SetText("In combat");
        total_damage = 0;
        start_time = GetTime();
    
    elseif ( event == "PLAYER_REGEN_ENABLED" ) then
        end_time = GetTime();
        total_time = end_time - start_time;
        average_dps = total_damage / total_time;
        CombatTracker_UpdateText();
    
    elseif ( event == "UNIT_COMBAT" ) then
        local unit, action, modifier, damage, damageType = ...;
        if ( InCombatLockdown() ) then
            if ( unit == "target" and action ~= "HEAL" ) then
            total_damage = total_damage + damage;
            end_time = GetTime();
            total_time = math.min(end_time - start_time, 1);
            average_dps = total_damage / total_time;
            CombatTracker_UpdateText();
            end
        end
    end
end

function CombatTracker_UpdateText()
    local status = string.format("%ds / %d dmg / %.2f dps", total_time, total_damage, average_dps)
    CombatTrackerText:SetText(status);
end

function CombatTracker_ReportDPS()
    local msgformat = "%d seconds spent in combat with %d outgoing damage. Average DPS was %.2f";
    local msg = string.format(msgformat, total_time, total_damage, average_dps);
    if ( GetNumGroupMembers() > 0 ) then
        SendChatMessage(msg, "PARTY");
    else
        print(msg);
    end
end