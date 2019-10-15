PARTY_ROSTER = {};
ENEMY_ROSTER = {};

function ThreatMeter_OnLoad(self)
    local playerID = UnitGUID("player");
    PARTY_ROSTER[1] = playerID;
    print(playerID);
    ThreatMeter:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
end

function ThreatMeter_OnEvent(self, event, ...)
    if ( event == "COMBAT_LOG_EVENT_UNFILTERED" ) then
        local timestamp, combatEvent, arg1, sourceGUID, sourceName, sourceFlags, arg2, destGUID, destName, destFlags, arg3, arg4, arg5, arg6, arg7 = CombatLogGetCurrentEventInfo();
        if ( sourceGUID == PARTY_ROSTER[1] ) then
            print(combatEvent);
            print(arg7);
            print(CombatLogGetCurrentEventInfo());
        end
    end
end