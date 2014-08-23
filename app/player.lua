Player = class()

Player.width = 30
Player.height = 60

Player.walkSpeed = 65
Player.maxHealth = 100

Player.depth = 0

function Player:init()
	self.health = 100
	self.x = 100
	self.y = love.graphics.getHeight() - ctx.environment.groundHeight - self.height
	self.prevx = self.x
	self.prevy = self.y
	self.speed = 0
	self.jujuRealm = 0
	self.jujuJuice = 100
	self.dead = false
	self.minions = {Imp}
	self.selectedMinion = 1
	self.direction = 1

	ctx.view:register(self)
end

function Player:update()
	self.prevx = self.x
	self.prevy = self.y

	if love.keyboard.isDown('left', 'a') then
		self.speed = math.lerp(self.speed, -self.walkSpeed, math.min(10 * tickRate, 1))
	elseif love.keyboard.isDown('right', 'd') then
		self.speed = math.lerp(self.speed, self.walkSpeed, math.min(10 * tickRate, 1))
	else
		self.speed = math.lerp(self.speed, 0, math.min(10 * tickRate, 1))
	end

	self.x = self.x + self.speed * tickRate
	self.direction = self.speed == 0 and self.direction or math.sign(self.speed)

	self.jujuRealm = timer.rot(self.jujuRealm, function()
		self.health = self.maxHealth
		self.dead = false
	end)
end

function Player:spend(amount)
	-- Check if Muju is broke
	if self.jujuJuice >= amount then
		-- He's not broke!
		self.jujuJuice = self.jujuJuice - amount
		return true
	else 
		-- He's broke!
		return false
	end
end

function Player:draw()
	local g = love.graphics
	local x, y = math.lerp(self.prevx, self.x, tickDelta / tickRate), math.lerp(self.prevy, self.y, tickDelta / tickRate)

	g.setColor(128, 0, 255, 160)
	g.rectangle('fill', x - self.width / 2, y, self.width, self.height)

	g.setColor(128, 0, 255)
	g.rectangle('line', x - self.width / 2, y, self.width, self.height)
end

function Player:summon()
	local minion = self.minions[self.selectedMinion]
	if self:spend(minion.cost) then
		ctx.minions:add(minion, {x = self.x + love.math.random(-10, 20), direction = self.direction})
	end
end

function Player:hurt(amount)
	self.health = self.health - amount
	-- Check whether or not to enter Juju Realm
	if self.health < 0 and self.jujuRealm == 0 then
  	-- We jujuin'
		self.jujuRealm = 5
		self.dead = true
		return true
	end

	if self.jujuRealm > 0 then
		-- What's going on in the Juju Realm
	end
end

function Player:keypressed(key)
	for i = 1, #self.minions do
		if tonumber(key) == i then
			self.selectedMinion = i
			return
		end
	end

	if key == ' ' then
		self:summon()
	end
end

function Player:keyreleased(key)
	--
end
