function PartyRoster_OnLoad(self)
  PartyRoster_LoadPlayerNames();
end

function PartyRoster_OnEvent(self, event, ...)
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
      PartyRoster_ClearPartyRoster();
      for i=1, GetNumGroupMembers()-1 do
        local name = (UnitName("party"..i));
        _G["PartyMember"..i+1]:SetText(name); 
      end
    else
      PartyRoster_ClearPartyRoster();
    end

  elseif ( event == "UNIT_TARGET" ) then
    local target = arg1;

    if ( not IsInGroup() ) then
      if ( target == "player" or target == "target" ) then
        local targetName = (UnitName("playertarget"));
        _G["PartyMemberTarget1"]:SetText(targetName);
        _G["PartyMemberTarget1"]:SetPoint("TOPLEFT", "$parent_BG", "TOPLEFT", _G["PartyMember1"]:GetStringWidth()+23, -20);
      else
        _G["PartyMemberTarget1"]:SetText("");
      end
    else
      local n = GetNumGroupMembers();

      if ( target == "player" or target == "target" ) then
        local playerTarget = (UnitName("playertarget"));
        _G["PartyMemberTarget1"]:SetText(playerTarget);
        _G["PartyMemberTarget1"]:SetPoint("TOPLEFT", "$parent_BG", "TOPLEFT", _G["PartyMember1"]:GetStringWidth()+23, -20);
      elseif ( string.match(target, "party") ) then
        for i=1, n-1 do
          local targetName = (UnitName("party"..i.."target"));
          _G["PartyMemberTarget"..i+1]:SetText(targetName);
          _G["PartyMemberTarget"..i+1]:SetPoint("TOPLEFT", "$parent_BG", "TOPLEFT", _G["PartyMember"..i+1]:GetStringWidth()+23, 20*(i+1)*-1);
        end
      else
        for i=1, n-1 do
          _G["PartyMemberTarget"..i]:SetText("");
        end
      end
    end
  end
end

-- Display player names
function PartyRoster_LoadPlayerNames()
  local string;

  PartyRosterDisplay:RegisterEvent("GROUP_FORMED");
  PartyRosterDisplay:RegisterEvent("UNIT_TARGET");
  PartyRosterDisplay:RegisterEvent("GROUP_ROSTER_UPDATE");
  PartyRosterDisplay:RegisterForClicks("RightButtonUp");
  PartyRosterDisplay:RegisterForDrag("LeftButton");
  
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
  --  _G["PartyMemberTarget"..i]:SetPoint("TOPLEFT", "$parent_BG", "TOPLEFT", 112.5, 20*i*-1);
  --end
end

-- Clear party roster
function PartyRoster_ClearPartyRoster()
  for i=2, 5 do
    print("Clearing...");
    _G["PartyMember"..i]:SetText("");
  end
end