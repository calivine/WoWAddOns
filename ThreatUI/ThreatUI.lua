-- Variables to track time and damage
local start_time = 0;
local end_time = 0;
local total_time = 0;
local total_damage = 0;
local average_damage = 0;

function ThreatUI_OnLoad(self)
  ThreatUI_LoadPlayerNames();
end

function ThreatUI_OnEvent(self, event, ...)
  local arg1, arg2, arg3, arg4 = ...;

  if ( event == "GROUP_FORMED" ) then
    -- Update group roster display when joining a party, forming party or when new party members join.
    
    _G["PartyMember1"]:SetText((UnitName("player")));
    
    for i=1, GetNumGroupMembers()-1 do
      local name = (UnitName("party"..i));
      _G["PartyMember"..i+1]:SetText((UnitName("party"..i)));
    end

  elseif ( event == "GROUP_ROSTER_UPDATE" ) then
    
    _G["PartyMember1"]:SetText((UnitName("player")));

    if ( GetNumGroupMembers() > 0 ) then
      ThreatUI_ClearPartyRoster();
      for i=1, GetNumGroupMembers()-1 do
        local name = (UnitName("party"..i));
        _G["PartyMember"..i+1]:SetText(name); 
      end
    else
      ThreatUI_ClearPartyRoster();
    end

  elseif ( event == "UNIT_TARGET" ) then
    local target = arg1;

    if ( not IsInGroup() ) then
      if ( target == "player" or target == "target" ) then
        local targetName = (UnitName("playertarget"));
        _G["PartyMemberThreat1"]:SetText(targetName);
        _G["PartyMemberThreat1"]:SetPoint("TOPLEFT", "$parent_BG", "TOPLEFT", _G["PartyMember1"]:GetStringWidth()+23, -20);
      else
        _G["PartyMemberThreat1"]:SetText("");
      end
    else
      local n = GetNumGroupMembers();

      if ( target == "player" or target == "target" ) then
        local playerTarget = (UnitName("playertarget"));
        _G["PartyMemberThreat1"]:SetText(playerTarget);
        _G["PartyMemberThreat1"]:SetPoint("TOPLEFT", "$parent_BG", "TOPLEFT", _G["PartyMember1"]:GetStringWidth()+23, -20);
      elseif ( string.match(target, "party") ) then
        for i=1, n-1 do
          local targetName = (UnitName("party"..i.."target"));
          _G["PartyMemberThreat"..i+1]:SetText(targetName);
          _G["PartyMemberThreat"..i+1]:SetPoint("TOPLEFT", "$parent_BG", "TOPLEFT", _G["PartyMember"..i+1]:GetStringWidth()+23, 20*(i+1)*-1);
        end
      else
        for i=1, n-1 do
          _G["PartyMemberThreat"..i]:SetText("");
        end
      end
    end
  end
end

-- Display player names
function ThreatUI_LoadPlayerNames()
  local string;

  ThreatDisplay:RegisterEvent("GROUP_FORMED");
  ThreatDisplay:RegisterEvent("UNIT_TARGET");
  ThreatDisplay:RegisterEvent("GROUP_ROSTER_UPDATE");
  
  _G["PartyMember1"]:SetText((UnitName("player")));
  if ( not IsInGroup() ) then
    -- Set positions of party roster
    for i=1, 5 do
      string = _G["PartyMember"..i];
      string:SetPoint("TOPLEFT", "$parent_BG", "TOPLEFT", 20, 20*i*-1);
    end
  else
    local n = GetNumGroupMembers();

    for i=1, n-1 do
      string = _G["PartyMember"..i+1];
      string:SetText((UnitName("party"..i)));
      string:SetPoint("TOPLEFT", "$parent_BG", "TOPLEFT", 20, 20*(i+1)*-1);
    end
  end

  -- Set target name display positions
  --for i=1, 5 do
  --  _G["PartyMemberThreat"..i]:SetPoint("TOPLEFT", "$parent_BG", "TOPLEFT", 112.5, 20*i*-1);
  --end
end

-- Clear party roster
function ThreatUI_ClearPartyRoster()
  for i=2, 5 do
    print("Clearing...");
    _G["PartyMember"..i]:SetText("");
  end
end