local parent = debugstack():match[[\AddOns\(.-)\]]
local global = GetAddOnMetadata(parent, 'X-oUF')
local oUF = _G[global] or oUF
assert(oUF, 'oUF not loaded')

local Update = function( self, event, unit )
  if(self.unit ~= unit) then 
    return 
  end
  local namebar = self.Namebar

  local disconnected = not UnitIsConnected(unit)

  namebar.disconnected = disconnected

  local r, g, b, a, t
  if(namebar.colorTapping and UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit)) then
    t = oUF.colors.tapped
  elseif(namebar.colorDisconnected and not UnitIsConnected(unit)) then
    t = oUF.colors.disconnected
  elseif(namebar.colorClass and UnitIsPlayer(unit)) or
    (namebar.colorClassNPC and not UnitIsPlayer(unit)) or
    (namebar.colorClassPet and UnitPlayerControlled(unit) and not UnitIsPlayer(unit)) then
    local _, class = UnitClass(unit)
    t = oUF.colors.class[class]
  elseif(namebar.colorReaction and UnitReaction(unit, 'player')) then
    t = oUF.colors.reaction[UnitReaction(unit, "player")]
  else
    -- nuffin'
  end

  if(t) then
    r, g, b, a = t[1], t[2], t[3], t[4]
  end

  if a == nil then 
    a = 1
  end

  if(b) then
    namebar:SetStatusBarColor(r, g, b, a)

    local bg = namebar.bg
    if(bg) then local mu = bg.multiplier or 1
      bg:SetVertexColor(r * mu, g * mu, b * mu, a * mu)
    end
  end

  if(namebar.PostUpdate) then
    return namebar:PostUpdate(self, unit)
  end
end

local Path = function(self, ...)
  return (self.Namebar.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
  return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local Enable = function(self, unit)
  local namebar = self.Namebar
  if(namebar) then
    namebar.__owner = self
    namebar.ForceUpdate = ForceUpdate
    namebar.Update = Update

    self:RegisterEvent('UNIT_CONNECTION', Path)
    self:RegisterEvent('PLAYER_TARGET_CHANGED', Path)
    self:RegisterEvent('UNIT_NAME_UPDATE', Path)
    self:RegisterEvent('UNIT_FACTION', Path) -- For tapping.

    if(namebar:IsObjectType'StatusBar' and not namebar:GetStatusBarTexture()) then
      namebar:SetStatusBarTexture[[Interface\TargetingFrame\UI-StatusBar]]
    end

    return true
  end
end

local Disable = function(self)
  local namebar = self.namebar
  if(namebar) then
    self:UnregisterEvent('UNIT_CONNECTION', Path)
    self:RegisterEvent('PLAYER_TARGET_CHANGED', Path)
    self:UnregisterEvent('UNIT_NAME_UPDATE', Path)
    self:UnregisterEvent('UNIT_FACTION', Path)
  end
end

oUF:AddElement('Namebar', Path, Enable, Disable)
