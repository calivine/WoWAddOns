
local COUNTER = 0;
local THROTTLE = 1.75;

local DISPLAY_TYPE = "threat";

local units = {"player", "pet", "party1", "partypet1", "party2", "partypet2", "party3", "partypet3", "party4", "partypet4"};

local damageEvents = {
    SWING_DAMAGE = true,
    RANGE_DAMAGE = true,
    SPELL_DAMAGE = true,
    SPELL_PERIODIC_DAMAGE = true,
    DAMAGE_SHIELD = true,
    DAMAGE_SPLIT = true
}

local healEvents = {
    SPELL_HEAL = true,
    SPELL_PERIODIC_HEAL = true
}

local regenEvents = {
    SPELL_ENERGIZE = true,
    SPELL_AURA_APPLIED = true
}

local CLASS_DECORATORS = {
    DRUID = { r = 1.0, g = 0.49, b = 0.04 },
    HUNTER = { r = 0.67, g = 0.83, b = 0.45 },
    MAGE = { r = 0.41, g = 0.80, b = 0.94 },
    PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
    PRIEST = { r = 1.0, g = 1.0, b = 1.0 },
    ROGUE = { r = 1.0, g = 0.96, b = 0.41 },
    SHAMAN = { r = 0.14, g = 0.35, b = 1.0 },
    WARLOCK = { r = 0.58, g = 0.51, b = 0.79 },
    WARRIOR = { r = 0.78, g = 0.61, b = 0.43 }
}

local SPECIAL_ABILITIES = {
    WARRIOR = {
        BATTLE_SHOUT = {
            5,
            11,
            17,
            26,
            39,
            55,
            70
        },
        HEROIC_STRIKE = {
            20,
            39,
            59,
            78,
            98,
            118,
            137,
            145,
            175
        },
        THUNDER_CLAP = {
            17,
            40,
            64,
            96,
            143,
            180
        },
        DEMORALIZING_SHOUT = {
            11,
            17,
            21,
            32,
            43
        }
    },
    MAGE = {
        COUNTERSPELL = {
            300
        },
        REMOVE_LESSER_CURSE = {
            14
        }
    }
}



local PARTY_TARGET = nil;

local PARTY_ROSTER = {};


local ThreatMeter = CreateFrame("Frame", "ThreatMeter", UIParent);
local ThreatMeterDisplayButton = CreateFrame("Button", "ThreatMeterDisplayButton", ThreatMeter, "UIPanelButtonTemplate");

ThreatMeter:EnableMouse(true);
ThreatMeter:SetMovable(true);
ThreatMeter:SetFrameStrata("LOW");
ThreatMeter:EnableDrawLayer("OVERLAY");
ThreatMeter:SetWidth(225);
ThreatMeter:SetHeight(150);
ThreatMeter:SetPoint("LEFT");

--[[
ThreatMeter:CreateTexture("ThreatMeter_BG", "OVERLAY");
ThreatMeter_BG:SetDrawLayer("OVERLAY");
ThreatMeter_BG:SetAllPoints();
ThreatMeter_BG:ClearAllPoints();
ThreatMeter_BG:SetPoint("LEFT", UIParent, "LEFT");
ThreatMeter_BG:SetTexture(0.22, 0.22, 0.22, 1.0);
]]

ThreatMeterDisplayButton:SetHeight(20);
ThreatMeterDisplayButton:SetWidth(75);

if DISPLAY_TYPE == "threat" then
    ThreatMeterDisplayButton:SetText("Damage");
elseif DISPLAY_TYPE == "damage" then
    ThreatMeterDisplayButton:SetText("Threat");
end

ThreatMeterDisplayButton:ClearAllPoints();
ThreatMeterDisplayButton:SetPoint("TOPLEFT", 0, 50);

ThreatMeterDisplayButton:RegisterForClicks("LeftButtonDown");


ThreatMeterDisplayButton:SetScript("OnClick", function(self, button, down)
    if DISPLAY_TYPE == "threat" then
        ThreatMeterDisplayButton:SetText("Damage");
        DISPLAY_TYPE = "damage";
    elseif DISPLAY_TYPE == "damage" then
        ThreatMeterDisplayButton:SetText("Threat");
        DISPLAY_TYPE = "threat";
    end
end);






function ThreatMeter:OnEvent(event, ...)
    if ( event == "COMBAT_LOG_EVENT_UNFILTERED" ) then
        -- print(CombatLogGetCurrentEventInfo());
        local timestamp, combatEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, args = CombatLogGetCurrentEventInfo();
        
        if ( bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MASK) > COMBATLOG_OBJECT_AFFILIATION_PARTY ) then
            return;
        end

        self:ProcessEntry(CombatLogGetCurrentEventInfo());
    
    elseif ( event == "UNIT_SPELLCAST_SUCCEEDED" ) then
        arg1, arg2, arg3 = ...;
        
        local class = UnitClass(arg1);
        class = string.upper(class);
        
        local name, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(arg3);
        
        local rank = GetSpellSubtext(arg3);
        if ( rank ~= nil ) then
            rank = self:GetRank(rank);
        end
        name = self:FormatSpell(name);
        
        --print(SPECIAL_ABILITIES)
        --[[
        for k,v in pairs(SPECIAL_ABILITIES) do
            print(k);
            -- If unit class equals key value, check if ability also matches
            for key,value in pairs(SPECIAL_ABILITIES[k]) do
                print(key);
                for i,v in ipairs(SPECIAL_ABILITIES[k][key]) do
                    print(i, v);
                end
                
            end
            
        end
        print(SPECIAL_ABILITIES["WARRIOR"]["HEROIC_STRIKE"][2]);
        print(GetSpellInfo(arg3));]]

    elseif ( event == "GROUP_ROSTER_UPDATE" ) then
        print("GRP_ROSTER_UPDATE");
        for i = 1, GetNumGroupMembers() do
            local unit = "party" .. i;
            self:UpdatePets(unit);
            local guid = UnitGUID(unit);
            if ( guid ) then
                local name, realm = UnitName(unit);
                PARTY_ROSTER[guid] = name;
                print(PARTY_ROSTER[guid]);
            end
        end
        if ( not self.in_combat ) then
            self:UpdateFrame();
        end
    elseif ( event == "UNIT_PET" ) then
        local unit = ...;
        self:UpdatePets(unit);

    elseif ( event == "PLAYER_REGEN_DISABLED" ) then
        self.in_combat = true;
        self.combat_start = GetTime();
        COUNTER = 0;
        self:TakeSnapshot()
        self:SetScript("OnUpdate", self.OnUpdate);

    elseif ( event == "PLAYER_REGEN_ENABLED" ) then
        self.in_combat = false;
        self.combat_time = self.combat_time + GetTime() - self.combat_start;
        self:SetScript("OnUpdate", nil);
        self:UpdateFrame();
        -- if refresh per battle is active:

        for idx, unit in ipairs(units) do
            local guid = UnitGUID(unit);
            if ( guid ) then
                
                self.combat_time = 0;
                self.snapshots[guid].threat = 0;
            end
        end

        for k,v in pairs(self.MOB_THREAT_TABLE) do
            print(k);
            for key,value in pairs(self.MOB_THREAT_TABLE[k]) do
                print(key, value);
            end
        end

        PARTY_TARGET = nil;
        self.MOB_THREAT_TABLE = {};

        
        

    elseif ( event == "PLAYER_LOGIN" ) then
        self:Initialize();
    end
end

function ThreatMeter:ProcessEntry(timestamp, combatEvent, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
    if ( damageEvents[combatEvent] ) then
        print(combatEvent);
        local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9 = ...;
        -- print(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9);
        print(arg2);
        
        local offset = combatEvent == "SWING_DAMAGE" and 1 or 4;
        local amount, overkill, school, resisted, blocked, absorbed = select(offset, ...);
        local class, class_file_name, race, race_file_name, sex = GetPlayerInfoByGUID(srcGUID);
        PARTY_TARGET = destGUID;
        -- Check if this is a pet, and if so map the pet's GUID to the party member's GUID using the mapping table
        --[[if self.pet_guids[srcGUID] then
            srcGUID = self.pet_guids[srcGUID];
        end]]

        if ( class == "Warrior" ) then
            if ( combatEvent == "SPELL_DAMAGE" ) then
                local rank = GetSpellSubtext(arg2);
                rank = self:GetRank(GetSpellSubtext(arg2));
                arg2 = self:FormatSpell(arg2);
                for k,v in pairs(SPECIAL_ABILITIES["WARRIOR"]) do
                    if ( k == arg2 ) then
                        amount = amount + SPECIAL_ABILITIES["WARRIOR"][arg2][rank];
                    end  
                end
            end
            amount = amount * 0.8;
        elseif class == "Mage" then
            amount = amount * 0.7;
        end

        -- Add threat amount to Mob's threat table
        if ( self.MOB_THREAT_TABLE[destGUID] ) == nil then
            self.MOB_THREAT_TABLE[destGUID] = {};
            self.MOB_THREAT_TABLE[destGUID][srcGUID] = amount;
        else
            if ( self.MOB_THREAT_TABLE[destGUID][srcGUID] ) == nil then
                self.MOB_THREAT_TABLE[destGUID][srcGUID] = amount;
            else
                self.MOB_THREAT_TABLE[destGUID][srcGUID] = self.MOB_THREAT_TABLE[destGUID][srcGUID] + amount;
            end
        end

        self.party_damage[srcGUID] = self.party_damage[srcGUID] + amount;
        
        

    elseif ( healEvents[combatEvent] ) then
        local amount, overhealing, absorbed = select(4, ...);
        self.party_heals[srcGUID] = (self.party_heals[srcGUID] or 0) + (amount - overhealing);
        -- self.threat_tables[srcGUID].threat = self.threat_tables[srcGUID].threat + ( ( amount - overhealing )  * 0.5 );
        
    elseif ( combatEvent == "SPELL_SUMMON" ) then
        self.pet_guids[destGUID] = srcGUID .. "pet";
    
    elseif ( combatEvent == "UNIT_DIED" ) then
        print("UNIT_DIED");
        print(...);
    end
end

-- Loop through all the valid unit ids and store the current DPS or HPS so it can later be subtracted
function ThreatMeter:TakeSnapshot()
    for idx, unit in ipairs(units) do
        local guid = UnitGUID(unit);
        if ( guid ) then
            if ( self.pet_guids[guid] ) then
                guid = self.pet_guids[guid];
            end
            self.snapshots[guid].damage = self.party_damage[guid];
            
            if ( PARTY_TARGET ~= nil ) then
                self.snapshots[guid].threat = self.MOB_THREAT_TABLE[PARTY_TARGET][guid];
            end
            self.snapshots[guid].heals = self.party_heals[guid];
        end
    end
end


function ThreatMeter:UpdatePets(unit)
    local petUnit;
    if ( unit == "player" ) then
        petUnit = "pet";
    else
        petUnit = unit:gsub("(party) (%d)", "%1pet%2");
    end

    if ( petUnit and UnitExists(petUnit) ) then
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
    self:SetPoint("LEFT", UIParent, "LEFT", 40, -15);
    self:SetWidth(300);
    self:SetHeight(150);
    
    self.rows = {};
    for i = 1, 10 do
        local row = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
        row:SetText("");
        self.rows[i] = row;

        if ( i == 1 ) then
            row:SetPoint("TOPLEFT", 0, 0);
        else
            row:SetPoint("TOPLEFT", self.rows[i-1], "BOTTOMLEFT", 0, 0);
        end
    end
end

function ThreatMeter:UpdateFrame(elapsed)
    for idx, unit in ipairs(units) do
        --local row = self.rows[idx];
        if UnitExists(unit) then
            local guid = UnitGUID(unit);
            if ( self.pet_guids[guid] ) then
                guid = self.pet_guids[guid];
            end

            local dps, hps, threat;
            if ( elapsed and elapsed > 0 ) then
                dps = (self.party_damage[guid] - self.snapshots[guid].damage);-- / elapsed;
                hps = (self.party_heals[guid] - self.snapshots[guid].heals);-- / elapsed;
                threat = self.snapshots[guid].threat;
            elseif ( self.combat_time > 0 ) then
                dps = self.party_damage[guid];-- / self.combat_time;
                hps = self.party_heals[guid];-- / self.combat_time;
                threat = self.snapshots[guid].threat;
            else
                dps = 0;
                hps = 0;
                threat = 0;
            end

            -- Update frame with new values
            local name = UnitName(unit);
            --local dpstext = self:ShortNum(dps);
            --local hpstext = self:ShortNum(hps);
            --local threat_text = threat;

            
            local threat_text = threat;
            
            local dpstext = self:ShortNum(dps);
            local hpstext = self:ShortNum(hps);

            --row:SetFormattedText("[%s] DPS: %s, Heal: %s", name, dpstext, hpstext);
            --row:SetFormattedText("%d. %s: %s", idx, name, threat_text);
            --row:Show();
        else
            --row:Hide();
        end
    end
    local i = 0;
    if ( PARTY_TARGET ~= nil ) then
        for k,v in self:spairs(self.MOB_THREAT_TABLE[PARTY_TARGET], function(t,a,b) return t[b] < t[a] * 1.1  end) do
            i = i + 1;
            local row = self.rows[i];
            local class, class_file_name, race, race_file_name, sex = GetPlayerInfoByGUID(k);
            class = string.upper(class);
            row:SetTextColor(CLASS_DECORATORS[class].r, CLASS_DECORATORS[class].g, CLASS_DECORATORS[class].b);
            if ( DISPLAY_TYPE == "threat" ) then
                row:SetFormattedText("%d. %s: %s", i, PARTY_ROSTER[k], v);
            elseif ( DISPLAY_TYPE == "damage" ) then
                row:SetFormattedText("%d. %s: %s", i, PARTY_ROSTER[k], self.snapshots[k].damage);
            end
            row:Show();
            
        end
    end
end


ThreatMeter:SetScript("OnEvent", ThreatMeter.OnEvent);

if ( IsLoggedIn() ) then
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
        end
    };

    setmetatable(self.party_damage, zero_mt);
    setmetatable(self.party_heals, zero_mt);

    self.snapshots = {};
    
    self.MOB_THREAT_TABLE = {};

    local emptytbl_mt = {
        __index = function(tbl, key)
            local new = setmetatable({}, zero_mt);
            rawset(tbl, key, new);
            return new;
        end
    };

    setmetatable(self.snapshots, emptytbl_mt);
    
    --setmetatable(self.MOB_THREAT_TABLE, emptytbl_mt);
    
    self.player_guid = UnitGUID("player");
    local name, realm = UnitName("player");
    local class, class_file_name, race, race_file_name, sex = GetPlayerInfoByGUID(self.player_guid);
    
    PARTY_ROSTER[self.player_guid] = name;

    self:RegisterEvent("GROUP_ROSTER_UPDATE");
    self:RegisterEvent("UNIT_PET");
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
    self:RegisterEvent("UNIT_POWER_UPDATE");
    self:RegisterEvent("PLAYER_REGEN_DISABLED");
    self:RegisterEvent("PLAYER_REGEN_ENABLED");
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
    self:RegisterForDrag("LeftButton");
    
    self:CreateFrames();
    self:UpdateFrame();

    self:SetScript("OnDragStart", self.BeginMoving);
    self:SetScript("OnDragStop", self.StopMoving);

end







--[[
     Utility functions:
        ShortNum
        BeginMoving
        StopMoving
        spairs
        GetRank
        
------------------------------------------------------------------------------------------]]

function ThreatMeter:ShortNum(num)
    local large = num > 1000;
    return string.format("%.2f%s", large and (num / 1000) or num, large and "k" or "");
end

function ThreatMeter:BeginMoving()
    self:StartMoving();
end

function ThreatMeter:StopMoving()
    self:StopMovingOrSizing();
end

function ThreatMeter:spairs(t, order)
    --collect the keys
    local keys = {};
    for k in pairs(t) do 
        keys[#keys+1] = k;
    end

    if order then
        table.sort(keys, function(a,b) return order(t,a,b) end);
    else
        table.sort(keys);
    end

    local i = 0;
    return function()
        i = i + 1;
        if keys[i] then
            return keys[i], t[keys[i]];
        end
    end
end

function ThreatMeter:GetRank(rank)
    return tonumber(string.sub(rank, -1, -1)) or 0;
end

function ThreatMeter:FormatSpell(arg2)
    return string.upper(string.gsub(arg2, " ", "_"));
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