local Burst = class()
Burst.code = 'burst'

local g = love.graphics

Burst.maxHealth = .5

function Burst:activate()
  self.x = self.owner.owner.x
  self.y = self.y or (ctx.map.height - ctx.map.groundHeight - self.owner.owner.height / 2)

  if ctx.tag == 'server' then
    assert(self.damage and self.heal)

    self.x = self.owner.owner.x
    self.y = self.y or (ctx.map.height - ctx.map.groundHeight - self.owner.owner.height / 2)
    self.team = self.owner.owner.team

    table.each(ctx.target:inRange(self, self.range, 'enemy', 'unit', 'player'), function(target)
      target:hurt(self.damage, self.owner.owner)
    end)

    table.each(ctx.target:inRange(self, self.range, 'ally', 'unit', 'player'), function(target)
      target:heal(target.maxHealth * self.heal, self.owner.owner)
    end)

    return ctx.spells:remove(self)
  end

  self.scale = 0
	self.health = self.maxHealth

	self.angle = love.math.random() * 2 * math.pi
  self.image = data.media.graphics.spell.burst
  ctx.event:emit('view.register', {object = self})
end

function Burst:deactivate()
  ctx.event:emit('view.unregister', {object = self})
end

function Burst:update()
  if ctx.tag == 'client' then
    self.health = timer.rot(self.health, function() ctx.spells:remove(self) end)
    self.scale = math.lerp(self.scale, 1, 20 * tickRate)
  end
end

function Burst:draw()
  local color = self.owner.owner.team == ctx.players:get(ctx.id).team and {40, 230, 40} or {230, 40, 40}
  color[4] = self.health / self.maxHealth * 255
	g.setColor(color)

  local scale = self.scale * ((self.range + 50) * 2 / self.image:getWidth())

	g.draw(self.image, self.x, self.y, self.angle, scale, scale, self.image:getWidth() / 2, self.image:getHeight() / 2)
  g.circle('line', self.x, self.y, self.range * self.scale)
end

return Burst
