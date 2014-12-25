UnitBuffs = class()

function UnitBuffs:init(unit)
  self.unit = unit
  self.list = {}

  table.merge(table.only(self.unit.class, Unit.classStats), self.unit)
  self:applyRunes()
end

function UnitBuffs:preupdate()
  table.with(self.list, 'preupdate')
end

function UnitBuffs:postupdate()
  table.with(self.list, 'rot')
  table.with(self.list, 'postupdate')
  table.with(self.list, 'update')
  
  local speed = self.unit.class.speed

  -- Apply Hastes
  local hastes = self:buffsWithTag('haste')
  table.each(hastes, function(haste)
    speed = speed + (self.unit.class.speed * haste.haste)
  end)

  -- Apply Slows
  local slows = self:buffsWithTag('slow')
  table.each(slows, function(slow)
    speed = speed * (1 - slow.slow)
  end)

  self.unit.speed = speed

  -- Apply Roots
  local rooted = table.count(self.buffsWithTag('root')) > 0
  if rooted then self.unit.speed = 0 end

  -- Apply Attack Speed Increases
  local frenzies = self:buffsWithTag('frenzy')
  local attackSpeed = self.unit.class.attackSpeed
  table.each(frenzies, function(frenzy)
    attackSpeed = attackSpeed * (1 - frenzy.frenzy)
  end)

  self.unit.attackSpeed = attackSpeed
end

function UnitBuffs:add(code, vars)
  if self:get(code) then return self:reapply(code, vars) end

  local buff = data.buff[code]()
  buff.unit = self.unit
  buff.ability = ability
  self.list[buff] = buff
  table.merge(vars, buff, true)
  f.exe(buff.activate, buff)
  return buff
end

function UnitBuffs:remove(buff)
  if type(buff) == 'string' then
    -- remove by code
    return
  end

  f.exe(buff.deactivate, buff, self.unit)
  self.list[buff] = nil
end

function UnitBuffs:get(code)
  return next(table.filter(self.list, function(buff) return buff.code == code end))
end

function UnitBuffs:reapply(code, vars)
  local buff = self:get(code)
  if buff then
    table.merge(vars, buff, true)
  else
    self:add(code, vars)
  end
end

function UnitBuffs:buffsWithTag(tag)
  return table.filter(self.list, function(buff) return table.has(buff.tags, tag) end)
end

function UnitBuffs:applyRunes()
  local unit, player = self.unit, self.unit.player
  local runes = player.deck[unit.class.code].runes
  
  table.each(runes, function(rune)
    local level = rune.level
    if level > 0 then
      table.each(rune.values, function(levels, stat)
        local value = levels[level]
        if type(value) == 'number' then
          unit[stat] = unit[stat] + value
        elseif type(value) == 'string' and value:match('%%') then
          local original = unit.class[stat]
          local percent = tonumber(value:match('%-?%d')) / 100
          unit[stat] = unit[stat] + original * percent
        end
      end)
    end
  end)
end

function UnitBuffs:prehurt(amount, source, kind)
  table.with(self.list, 'prehurt', amount, source, kind)

  if kind == 'attack' then
    local armors = self.buffs:buffsWithTag('armor')
    local armor = 0
    table.each(armors, function(buff)
      armor = armor + (1 - armor) * buff.armor
    end)

    amount = amount * (1 - armor)
  end

  return amount
end

function UnitBuffs:posthurt(amount, source, kind)
  table.with(self.list, 'posthurt', amount, source, kind)

  return amount
end
