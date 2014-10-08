local Duju = extend(Unit)
Duju.code = 'duju'

Duju.width = 64
Duju.height = 24

Duju.maxHealth = 75
Duju.maxHealthPerMinute = 8
Duju.damage = 11
Duju.damagePerMinute = 10
Duju.attackRange = 32
Duju.attackSpeed = 1.12
Duju.speed = 65

-- Spells
Duju.chargeRate = 30
Duju.chargeMax = 150
Duju.chargeRegen = 0
Duju.chargeDamage = 0

Duju.buttCooldown = 5
Duju.buttKnockback = .25
Duju.buttStun = 0
Duju.buttDamageMultiplier = 1

Duju.impaleDuration = .75
Duju.impaleArmorReduction = .1
Duju.impaleWeaken = 0

function Duju:activate()
	Unit.activate(self)

  if ctx.tag == 'server' then
    self.maxHealth = self.maxHealth + 4 * ctx.units.enemyLevel ^ 1.1
    self.health = self.maxHealth
    self.damage = self.damage + .5 * ctx.units.enemyLevel
    self.buttDamage = self.damage * 1.5
    self.buttTimer = 1
  end

  -- Animation
  --self.animation = data.animation.duju(self, {scale = self.scale})
	self.attackAnimation = 0
end

function Duju:update()
	Unit.update(self)

  -- Targeting
  if ctx.tag == 'server' then
    self:selectTarget()
    if self.target and self.attackTimer == 0 and self:inRange() then self:attack() end
    self:move()

    self.buttTimer = timer.rot(self.buttTimer)
    if self.target then
      --self.animation.flipX = (self.target.x - self.x) > 0
    end
    self.attackAnimation = timer.rot(self.attackAnimation)
  end

  -- Animation
	--self.animation.offsety = self.height / 2 + 5 * math.sin(tick * tickRate * 4)
end

function Duju:attack()
	self.attackTimer = self.attackSpeed

  local buttable = isa(self.target, Unit)
	if self.buttTimer == 0 and buttable and self.rng:random() < .6 then
		return self:butt()
	end

	local damage = self.damage
	if self.target:hurt(damage, self) then self.target = false end
  if not self.target then self:selectTarget() end
  ctx.event:emit('sound.play', {sound = 'combat', volume = .5})
	self.attackAnimation = 1
end

function Duju:butt()
	local targets = ctx.target:inRange(self, self.buttRange * 2, 'enemy', 'unit')
	local damage = self.buttDamage
	if #targets >= 2 then damage = damage / 2 end
	table.each(targets, function(target)
		if math.sign(self.target.x - self.x) == math.sign(target.x - self.x) then
			target:hurt(damage, self)
			local sign = math.sign(target.x - self.x)
			target.knockBack = sign * (.2 + self.rng:random() / 25)
		end
	end)
	self.buttTimer = self.buttRate
	--self.animation:set('headbutt')
  ctx.event:emit('sound.play', {sound = 'combat', with = function(sound) sound:setVolume(.5) end})
  if not self.target then self:selectTarget() end
end

return Duju
