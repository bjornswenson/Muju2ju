require 'app/enemies/enemy'

Puju = extend(Enemy)

Puju.code = 'puju'
Puju.width = 64
Puju.height = 24
Puju.speed = 40
Puju.damage = 18
Puju.fireRate = 1.1
Puju.maxHealth = 65
Puju.attackRange = Puju.width / 2

Puju.buttRate = 4
Puju.buttDamage = 27
Puju.buttRange = Puju.attackRange * 1.25

function Puju:init(data)
	Enemy.init(self, data)

  -- Stats
	self.maxHealth = self.maxHealth + 4 * ctx.enemies.level ^ 1.1
	self.health = self.maxHealth
  self.healthDispaly = self.health
	self.damage = self.damage + .5 * ctx.enemies.level
	self.buttDamage = self.damage * 1.5
	self.buttTimer = 1

  -- Animation Stuff ew
	self.skeleton = Skeleton({name = 'puju', x = self.x, y = self.y + self.height + 8, scale = self.scale})
	self.animator = Animator({
		skeleton = self.skeleton,
		mixes = {
			{from = 'attack', to = 'headbutt', time = .2},
			{from = 'headbutt', to = 'attack', time = .2},
		}
	})
	self.animationState = 'attack'
	self.animator:set(self.animationState, true)
	self.animator.state.onComplete = function(trackIndex)
		local name = self.animator.state:getCurrent(trackIndex).animation.name
		if name == 'headbutt' then
			self.animationState = 'attack'
			self.animator:set(self.animationState, true)
		end
	end
	self.animator.state.onEvent = function(trackIndex, event)
		print('event ' .. event.data.name)
	end
	self.animationSpeeds = table.map({
		headbutt = .69 * tickRate,
		attack = .8 * tickRate
	}, f.val)
	self.attackAnimation = 0
end

function Puju:update()
	Enemy.update(self)

  -- Targeting
	self.target = ctx.target:closest(self, 'shrine', 'player', 'minion')
	if self.target and self.fireTimer == 0 and self:inRange() then self:attack() end
	self:move()

  -- Rots
	self.buttTimer = timer.rot(self.buttTimer)

  -- Animation
	self.skeleton.skeleton.x = self.x
	self.skeleton.skeleton.y = self.y + self.height / 2 + 5 * math.sin(tick * tickRate * 4)
	self.skeleton.skeleton.flipX = (self.target.x - self.x) > 0
	self.animator:update(self.animationSpeeds[self.animationState]() * ((self.animationState ~= 'attack' or self.attackAnimation > 0) and 1 or 0))
	self.attackAnimation = timer.rot(self.attackAnimation)
end

function Puju:attack()
	self.fireTimer = self.fireRate

	if self.buttTimer == 0 and self.target ~= ctx.player and self.target ~= ctx.shrine and love.math.random() < .6 then
		return self:butt()
	end

	local damage = self.damage * (1 - self.damageReduction)
	if self.target:hurt(damage, self) then self.target = false end
	self:hurt(damage * .25 * ctx.upgrades.muju.mirror.level)
	local sound = ctx.sound:play({sound = 'combat'})
	if sound then sound:setVolume(.5) end
	self.attackAnimation = 1
end

function Puju:butt()
	local targets = ctx.target:inRange(self, self.buttRange * 2, 'minion')
	local damage = self.buttDamage * (1 - self.damageReduction)
	if #targets >= 2 then damage = damage / 2 end
	table.each(targets, function(target)
		if math.sign(self.target.x - self.x) == math.sign(target.x - self.x) then
			target:hurt(damage, self)
			local sign = math.sign(target.x - self.x)
			target.knockBack = sign * (.2 + love.math.random() / 25)
		end
	end)
	self.buttTimer = self.buttRate
	self.animationState = 'headbutt'
	self.animator:set(self.animationState, false)
	local sound = ctx.sound:play({sound = 'combat'})
	if sound then sound:setVolume(.5) end
end

function Puju:draw()
	local g = love.graphics
	local sign = -math.sign(self.target.x - self.x)
	g.setColor(255, 255, 255)
	self.animator:draw()
	if self.damageReduction > 0 then
		g.setColor(255, 255, 255, 200 * math.min(self.damageReductionDuration, 1))
		g.draw(media.graphics.curseIcon, self.x, self.y - 55, self.damageReductionDuration * 4, .5, .5, self.curseIcon:getWidth() / 2, self.curseIcon:getHeight() / 2)
	end
end
