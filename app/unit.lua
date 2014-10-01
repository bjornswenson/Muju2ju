Unit = class()

Unit.depth = -10

function Unit:activate()
  self.history = NetHistory(self)

	self.y = ctx.map.height - ctx.map.groundHeight - self.height
	self.target = nil
	self.fireTimer = 0
  self.dead = false

  -- Depth randomization / Fake3D
	local r = love.math.random(-20, 20)
	self.scale = (data.animation[self.code] and data.animation[self.code].scale or 1) + (r / 210)
	self.y = self.y + r
	self.depth = self.depth - r / 20 + love.math.random() * (1 / 20)

	self.health = self.maxHealth
	self.healthDisplay = self.health
	self.damageReduction = 0
	self.damageReductionDuration = 0
	self.damageAmplification = 0
	self.damageAmplificationDuration = 0
	self.slow = 0
	self.knockBack = 0
	self.knockBackDisplay = 0

  self.rng = love.math.newRandomGenerator(self.id)

  ctx.event:emit('view.register', {object = self})
end

function Unit:deactivate()
  ctx.event:emit('view.unregister', {object = self})
end

function Unit:update()

  -- Rots and Lerps
	self.fireTimer = self.fireTimer - math.min(self.fireTimer, tickRate)
	self.healthDisplay = math.lerp(self.healthDisplay, self.health, 20 * tickRate)
	self.damageReductionDuration = timer.rot(self.damageReductionDuration, function() self.damageReduction = 0 end)
	self.damageAmplificationDuration = timer.rot(self.damageAmplificationDuration, function() self.damageAmplification = 0 end)
	self.slow = math.lerp(self.slow, 0, 1 * tickRate)
	self.x = self.x + self.knockBack * tickRate * 3000
	self.knockBack = math.max(0, math.abs(self.knockBack) - tickRate) * math.sign(self.knockBack)
	self.knockBackDisplay = math.lerp(self.knockBackDisplay, math.abs(self.knockBack), 20 * tickRate)

	if isaminion then
    self:hurt(self.maxHealth * .02 * tickRate)
    self.speed = math.max(self.speed - .5 * tickRate, 20)
  end
end

function Unit:inRange()
  if not self.target then return false end
  return math.abs(self.target.x - self.x) <= self.attackRange + self.target.width / 2
end

function Unit:move()
  if not self.target or self:inRange() then return end
  self.x = self.x + self.speed * math.sign(self.target.x - self.x) * tickRate * (1 - self.slow)
end

function Unit:hurt(amount)
  if ctx.tag ~= 'server' then return end
	self.health = self.health - (amount + (amount * self.damageAmplification))
	if self.health <= 0 then
    self:die()
		return true
	end
end

function Unit:die()
  
  -- Juju!
	local x = 10--love.math.random(14 + (ctx.enemies.level ^ .85) * .75, 20 + (ctx.enemies.level ^ .85))
	if love.math.random() > .5 then
		ctx.spells:add('juju', {amount = x, x = self.x, y = self.y, vx = love.math.random(-35, 35)})
	else
		ctx.spells:add('juju', {amount = x / 2, x = self.x, y = self.y, vx = love.math.random(0, 45)})
		ctx.spells:add('juju', {amount = x / 2, x = self.x, y = self.y, vx = love.math.random(-45, 0)})
	end

  ctx.units:remove(self)
end

