Upgrades = class()

Upgrades.costs = {}
Upgrades.costs.firstAbility = 50
Upgrades.costs.secondAbility = 100
Upgrades.costs.abilityUpgrade = 100
Upgrades.costs.population = 100

function Upgrades:process(data, player)
  local function spend(amount)
    return ctx.tag == 'server' and player:spend(amount) or true
  end

  local deck = data.unit and player.deck[data.unit]
  local abilityCount = data.unit and table.count(deck.upgrades)
  local unit = data.unit and _G['data'].unit[deck.code]
  local ability = data.unit and data.ability and unit.abilities[data.ability]
  local abilityCost = ability and (abilityCount == 0 and self.costs.firstAbility or self.costs.secondAbility)
  local upgrade = unit and ability and data.upgrade and ability.upgrades[data.upgrade].code

  if ability and not upgrade and spend(abilityCost) then
    deck.abilities[ability] = true
    return true
  elseif ability and upgrade and spend(self.costs.abilityUpgrade) then
    deck.upgrades[ability][upgrade] = true
    return true
  elseif data.unit and data.rune then
    -- Coming soon
    return true
  elseif data.other == 'population' and spend(self.costs.population) then
    player.maxPopulation = player.maxPopulation + 1
    return true
  end

  return false
end

