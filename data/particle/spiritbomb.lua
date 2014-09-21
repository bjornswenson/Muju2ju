local SpiritBomb = class()
SpiritBomb.code = 'spiritBomb'

SpiritBomb.gravity = 700
SpiritBomb.scale = 1
SpiritBomb.maxHealth = .3
SpiritBomb.radius = 40

function SpiritBomb:activate()
	local dx = math.abs(self.targetx - self.x)
	local dy = -Spuju.height
	local g = self.gravity
	local v = self.velocity
	local root = math.sqrt(v ^ 4 - (g * ((g * dx ^ 2) + (2 * dy * v ^ 2))))
	local angle
	if root ~= root then
		angle = math.pi / 2 + love.math.random(-math.pi / 4, math.pi / 4)
	else
		local a1, a2 = math.atan((v ^ 2 + root) / (g * dx)), math.atan((v ^ 2 - root) / (g * dx))
		angle = math.max(a1, a2)
	end
	self.vx = math.cos(angle) * v * math.sign(self.targetx - self.x)
	self.vy = math.sin(angle) * -v
	self.angle = love.math.random() * 2 * math.pi
	self.health = nil
	self.burstScale = 0
	ctx.view:register(self)
end

function SpiritBomb:deactivate()
  ctx.view:unregister(self)
end

function SpiritBomb:update()
	if self.health then
		self.health = timer.rot(self.health, function() ctx.particles:remove(self) end)
		self.burstScale = math.lerp(self.burstScale, self.radius / Burst.image:getWidth(), 20 * tickRate)
	else
		self.x = self.x + self.vx * tickRate
		self.y = self.y + self.vy * tickRate
		self.vy = self.vy + self.gravity * tickRate
		self.angle = self.angle + math.sign(self.vx) * tickRate
    local image = data.media.graphics.spujuSkull
		if self.y + image:getWidth() >= ctx.map.height - ctx.map.groundHeight then
			self.health = self.maxHealth
			table.each(ctx.target:inRange(self, self.radius, 'minion'), function(m)
				m:hurt(self.damage)
			end)
			if math.abs(self.x - ctx.player.x) < self.radius + ctx.player.width / 2 then
				ctx.player:hurt(self.damage / 2, self.owner)
			end
			if math.abs(self.x - ctx.shrine.x) < self.radius + ctx.shrine.width / 2 then
				ctx.shrine:hurt(self.damage)
			end
		end
	end
end

function SpiritBomb:draw()
	local g = love.graphics
	if self.health then
    local explosion = data.media.graphics.explosion
		g.setColor(80, 230, 80, 200 * self.health / self.maxHealth)
		g.draw(explosion, self.x, ctx.map.height - ctx.map.groundHeight, self.angle, self.burstScale + .25, self.burstScale + .25, explosion:getWidth() / 2, explosion:getHeight() / 2)
	else
    local image = media.graphics.spujuSkull
		g.setColor(255, 255, 255)
		g.draw(image, self.x, self.y, self.angle, self.scale, self.scale, image:getWidth() / 2, image:getHeight() / 2)
	end
end

return SpiritBomb
