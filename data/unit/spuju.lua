local Spuju = extend(Unit)
Spuju.code = 'spuju'
Spuju.image = love.graphics and love.graphics.newImage('media/skeletons/spuju/spuju.png')

Spuju.width = 60
Spuju.height = 60

Spuju.maxHealth = 75
Spuju.maxHealthPerMinute = 6.5
Spuju.damage = 6
Spuju.damagePerMinute = 8
Spuju.attackRange = 300
Spuju.attackSpeed = .3
Spuju.speed = 40

function Spuju:activate()
	Unit.activate(self)

  self.scale = .8

  -- Stats
	self.maxHealth = self.maxHealth + 5 * ctx.units.enemyLevel ^ .9
	self.health = self.maxHealth
	self.damage = self.damage + 1.1 * ctx.units.enemyLevel ^ .9
	self.attackRange = self.attackRange + math.min(math.max(ctx.units.enemyLevel - 20, 0) * 2, 100)
	self.clip = 3
	if ctx.units.enemyLevel > 50 then self.clip = self.clip + 1 end
	if ctx.units.enemyLevel > 80 then self.clip = self.clip + 1 end
	self.maxClip = self.clip
end

function Spuju:update()
	Unit.update(self)

  self:selectTarget()
  if self:inRange() and self.attackTimer == 0 then self:attack() end
	self:move()
end

function Spuju:attack()
	if self.clip == 0 then self.clip = self.maxClip end
	self.clip = self.clip - 1
	self.attackTimer = self.clip == 0 and self.attackSpeed * 6 or self.attackSpeed
  local seed = tick % 256
  local spiritBomb = {kind = ctx.spells.map.spiritBomb, owner = self.id, seed = seed}
	local targetx = self.target == ctx.shrine and self.target.x or self.target.x + love.math.randomNormal(65)
	local velocity = 150 + 250 * (math.abs(self.target.x - self.x) / self.attackRange)
	local damage = self.damage
  ctx.net:emit('spiritBomb', {x = self.x, y = self.y - self.height / 2, targetx = targetx, velocity = velocity, damage = damage, owner = self})
end

return Spuju
