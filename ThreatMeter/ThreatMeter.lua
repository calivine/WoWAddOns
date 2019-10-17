PARTY_ROSTER = {};
ENEMY_ROSTER = {};
DMG = 0;

local COUNTER = 0;
local THROTTLE = 5.0;

local units = {"player", "pet", "party1", "partypet1", "party2", "partypet2", "party3", "partypet3", "party4", "partypet4"};

local damageEvents = {
    SWING_DAMAGE = true,
    RANGE_DAMAGE = true,
    SPELL_PERIODIC_DAMAGE = true,
    DAMAGE_SHIELD = true,
    DAMAGE_SPLIT = true
}

local healEvents = {
    SPELL_HEAL = true,
    SPELL_PERIODIC_HEAL = true
}

local ThreatMeter = CreateFrame("Frame", "ThreatMeter", UIParent);

function ThreatMeter:OnEvent(event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, combatEvent, arg1, sourceGUID, sourceName, sourceFlags, arg2, destGUID, destName, destFlags, arg3, arg4, arg5, arg6, arg7 = CombatLogGetCurrentEventInfo();
        local typeFlags = bit.band(select(5, ...), COMBATLOG_OBJECT_TYPE_MASK);
        local isPlayer = typeFlags == COMBATLOG_OBJECT_TYPE_PLAYER;
        
        if isPlayer then
            if combatEvent == "SPELL_DAMAGE" then
                DMG = DMG + arg7;
                print(DMG);
            end
        end
        local srcFlags = select(5, ...);
        if bit.band(srcFlags, COMBATLOG_OBJECT_AFFILIATION_MASK) > COMBATLOG_OBJECT_AFFILIATION_PARTY then
            return;
        end
        self:ProcessEntry(...);
    elseif event == "GROUP_ROSTER_UPDATE" then
        for i = 1, GetNumGroupMembers() do
            local unit = "party" .. i;
            self:UpdatePets(unit);
        end
        if not self.in_combat then
            self:UpdateFrame();
        end
    elseif event == "UNIT_PET" then
        local unit = ...;
        self:UpdatePets(unit);
    elseif event == "PLAYER_REGEN_DISABLED" then
        self.in_combat = true;
        self.combat_start = GetTime();
        COUNTER = 0;
        self:TakeSnapshot()
        self:SetScript("OnUpdate", self.OnUpdate);
    elseif event == "PLAYER_REGEN_ENABLED" then
        self.in_combat = false;
        self.combat_time = self.combat_time + GetTime() - self.combat_start;
        self:SetScript("OnUpdate", nil);
        self:UpdateFrame();
    elseif event == "PLAYER_LOGIN" then
        self:Initialize();
    end
end

ThreatMeter:SetScript("OnEvent", ThreatMeter.OnEvent);

if IsLoggedIn() then
    ThreatMeter:Initialize();
else
    ThreatMeter:RegisterEvent("PLAYER_LOGIN");
end

function ThreatMeter:Initialize()
    self.combat_time = 0;
    self.party_damage = {};
    self.party_heals = {};
    self.pet_guids = {};

    local zero_mt = {
        __index = function(tbl, key)
            return 0;
        end,
    };

    setmetatable(self.party_damage, zero_mt);
    setmetatable(self.party_heals, zero_mt);

    self.snapshots = {};
    local emptytbl_mt = {
        __index = function(tbl, key)
            local new = setmetatable({}, zero_mt);
            rawset(tbl, key, new);
            return new;
        end,
    };

    setmetatable(self.snapshots, emptytbl_mt);
    
    self.player_guid = UnitGUID("player");

    print(self.player_guid);

    self:RegisterEvent("GROUP_ROSTER_UPDATE");
    self:RegisterEvent("UNIT_PET");
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
    self:RegisterEvent("PLAYER_REGEN_DISABLED");
    self:RegisterEvent("PLAYER_REGEN_ENABLED");

    self:CreateFrames();
    self:UpdateFrame();

end



function ThreatMeter:ProcessEntry(timestamp, combatEvent, srcGUID, srcName, srcFlags, destGUID, destName, destFlags, ...)
    if damageEvents[combatEvent] then
        local offset = combatEvent == "SWING_DAMAGE" and 1 or 4;
        local amount, overkill, school, resisted, blocked, absorbed = select(offset, ...);

        -- Check if this is a pet, and if so map the pet's GUID to the party member's GUID using the mapping table
        if self.pet_guids[srcGUID] then
            srcGUID = self.pet_guids[srcGUID];
        end
        self.party_damage[srcGUID] = self.party_damage[srcGUID] + amount;
    elseif healEvents[combatEvent] then
        local amount, overhealing, absorbed = select(4, ...);
        self.party_heals[srcGUID] = (self.party_heals[srcGUID] or 0) + (amount - overhealing);
    elseif combatEvent == "SPELL_SUMMON" then
        self.pet_guids[destGUID] = srcGUID .. "pet";
    end
end

-- Loop through all the valid unit ids and store the current DPS or HPS so it can later be subtracted
function ThreatMeter:TakeSnapshot()
    for idx, unit in ipairs(units) do
        local guid = UnitGUID(unit);
        if guid then
            if self.pet_guids[guid] then
                guid = self.pet_guids[guid];
            end
            
            self.snapshots[guid].damage = self.party_damage[guid];
            self.snapshots[guid].heals = self.party_heals[guid];
            print(self.party_damage[guid]);
        end
    end
end


function ThreatMeter:UpdatePets(unit)
    local petUnit;
    if unit == "player" then
        petUnit = "pet";
    else
        petUnit = unit:gsub("(party) (%d)", "%1pet%2");
    end

    if petUnit and UnitExists(petUnit) then
        local guid = UnitGUID(unit);
        local petGUID = UnitGUID(petUnit);
        self.pet_guids[petGUID] = guid .. "pet"
    end
end

function ThreatMeter:OnUpdate(elapsed)
    COUNTER = COUNTER + elapsed;
    if COUNTER >= THROTTLE then
        COUNTER = 0;
        self:UpdateFrame(THROTTLE);
        self:TakeSnapshot();
    end
end

function ThreatMeter:CreateFrames()
    self:ClearAllPoints();
    self:SetPoint("TOP", MinimapCluster, "BOTTOM", 0, -15);
    self:SetWidth(300);
    self:SetHeight(150);
    
    self.rows = {};
    for i = 1, 10 do
        local row = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
        row:SetText("");
        self.rows[i] = row;

        if i == 1 then
            row:SetPoint("TOPLEFT", 0, 0);
        else
            row:SetPoint("TOPLEFT", self.rows[i-1], "BOTTOMLEFT", 0, 0);
        end
    end
end

function ThreatMeter:UpdateFrame(elapsed)
    for idx, unit in ipairs(units) do
        local row = self.rows[idx];
        if UnitExists(unit) then
            local guid = UnitGUID(unit);
            if self.pet_guids[guid] then
                guid = self.pet_guids[guid];
            end

            local dps, hps,
            if elapsed and elapsed > 0 then
                dps = (self.party_damage[guid] - self.snapshots[guid].damage) / elapsed;
                hps = (self.party_heals[guid] - self.snapshots[guid].heals) / elapsed;
            elseif self.combat_time > 0 then
                dps = self.party_damage[guid] / self.combat_time;
                hps = self.party_heals[guid] / self.combat_time;
            else
                dps = 0;
                hps = 0;
            end

            -- Update frame with new values
            local name = UnitName(unit);
            local dpstext = self:ShortNum(dps);
            local hpstext = self:ShortNum(hps);
            row:SetFormattedText("[%s] DPS: %s, Heal %s", name, dpstext, hpstext);
            row:Show();
        else
            row:Hide();
        end
    end
end

function ThreatMeter:ShortNum(num)
    local large = num > 1000;
    return string.format("%2.f%s", large and (num / 1000) or num, large and "k" or "");
end

--function ThreatMeter_OnLoad(self)
--    local playerID = UnitGUID("player");
  --  PARTY_ROSTER[1] = playerID;
    --print(playerID);
    --ThreatMeter:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
--end

--function ThreatMeter_OnEvent(self, event, ...)
  --  if ( event == "COMBAT_LOG_EVENT_UNFILTERED" ) then
    --    local timestamp, combatEvent, arg1, sourceGUID, sourceName, sourceFlags, arg2, destGUID, destName, destFlags, arg3, arg4, arg5, arg6, arg7 = CombatLogGetCurrentEventInfo();
      --  if ( sourceGUID == PARTY_ROSTER[1] ) then
        --    print(combatEvent);
          --  print(arg7);
            --print(CombatLogGetCurrentEventInfo());
        --end
    --end
--end