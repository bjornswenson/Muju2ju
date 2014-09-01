Hud = class()

local g = love.graphics

function Hud:init()
	self.font = g.newFont('media/fonts/pixel.ttf', 8)
	self.upgrading = false
	self.upgradeBg = g.newImage('media/graphics/upgrade-menu.png')
	self.lock = g.newImage('media/graphics/lock.png')
	self.upgradeAlpha = 0
	self.tooltip = ''
	self.tooltipAlpha = 0
	self.tooltipHover = false
	self.jujuIcon = g.newImage('media/graphics/juju-icon.png')
	self.timer = {total = 0, minutes = 0, seconds = 0}
	ctx.view:register(self, 'gui')
end

function Hud:update()
	self.upgradeAlpha = math.lerp(self.upgradeAlpha, self.upgrading and 1 or 0, 12 * tickRate)
	self.tooltipAlpha = math.lerp(self.tooltipAlpha, self.tooltipHover and 1 or 0, 12 * tickRate)
	-- Update Timer
	self:score()
end

function Hud:health(x, y, health, max, color)
	local g = love.graphics
	health = (100 * health) / max

	g.setColor(0, 0, 0, 160)
	g.rectangle('fill', x, y, 100 * .6, 3)
	g.setColor(color)
	g.rectangle('fill', x, y, health * .6, 3)
end

function Hud:stackingTable(stackingTable, x, range, delta)
		local limit = x + range
		for i = x - range, limit, 1 do
			if not stackingTable[i] then
				stackingTable[i] = 1 
			else 
				stackingTable[i] = stackingTable[i] + delta 
			end
		end
end

function Hud:score()
	if not self.upgrading then
		self.timer.total = self.timer.total + 1
	end
end


function Hud:gui()
	local w, h = love.graphics.getDimensions()

	-- Timer
	local total = self.timer.total * tickRate
	self.timer.seconds = math.floor(total % 60)
	self.timer.minutes = math.floor(total / 60)

	if self.timer.minutes < 10 then
		self.timer.minutes = '0' .. self.timer.minutes
	end

	if self.timer.seconds < 10 then
		self.timer.seconds = '0' .. self.timer.seconds
	end

	love.graphics.setColor(255, 255, 255)
	love.graphics.print(self.timer.minutes .. ':' .. self.timer.seconds, w - 50, 25)

	g.setFont(self.font)
	g.setColor(ctx.player.selectedMinion == 1 and {255, 255, 255} or {150, 150, 150})
	g.print('Zuju', 16, 100)
	if #ctx.player.minions == 2 then
		g.setColor(ctx.player.selectedMinion == 2 and {255, 255, 255} or {150, 150, 150})
		g.print('Vuju', 16, 100 + g.getFont():getHeight() + 2)
	end
	
	-- Health Bars

	local px, py = math.lerp(ctx.player.prevx, ctx.player.x, tickDelta / tickRate), math.lerp(ctx.player.prevy, ctx.player.y, tickDelta / tickRate)
	local green = {0, 255, 0}
	local red = {255, 0, 0}

	self:health(px - 30, py - 20, ctx.player.healthDisplay, ctx.player.maxHealth, green)
	self:health(ctx.shrine.x - 30, ctx.shrine.y - 65, ctx.shrine.healthDisplay, ctx.shrine.maxHealth, green)

	local stackingTable = {}
	table.each(ctx.enemies.enemies, function(enemy)
		local location = math.floor(enemy.x)
		self:stackingTable(stackingTable, location, enemy.width * 2, .5)

		if enemy.code == 'puju' then
			self:health(enemy.x - 25, enemy.y - 25 * stackingTable[location], enemy.healthDisplay, enemy.maxHealth, red)
		elseif enemy.code == 'spirit-bomb' then
			self:health(enemy.x - 25, enemy.y - 45 * stackingTable[location], enemy.healthDisplay, enemy.maxHealth, red)
		end
	end)

	stackingTable = {}
	table.each(ctx.minions.minions, function(minion)
		local location = math.floor(minion.x)
		self:stackingTable(stackingTable, location, minion.width * 2, .5)

		if minion.code == 'zuju' then
			self:health(minion.x - 25, minion.y - 45 * stackingTable[location], minion.healthDisplay, minion.maxHealth, green)
		elseif minion.code == 'vuju' then
			self:health(minion.x - 25, minion.y - 45 * stackingTable[location], minion.healthDisplay, minion.maxHealth, green)
		end
	end)

	if self.upgradeAlpha > .001 then
		local mx, my = love.mouse.getPosition()
		local w2, h2 = w / 2, h / 2
		local x1, y1 = w2 - 300, h2 - 200
		local w, h = 600, 400
		g.setColor(255, 255, 255, self.upgradeAlpha * 240)
		g.draw(self.upgradeBg, 400, 300, 0, .85, .85, self.upgradeBg:getWidth() / 2, self.upgradeBg:getHeight() / 2)

		local xx
		local idx
		self.tooltipHover = false
		
		-- Juju box
		if math.inside(mx, my, w2 - 22, h2 - 250, 48, 48) then
			self.tooltip = math.floor(ctx.player.juju) .. ' Juju!'
			self.tooltipHover = true
		end

		-- Zuju
		if math.inside(mx, my, x1 + (w * .235) - 32, h2 - 144, 64, 64) then
			self.tooltip = [[Zuju
				Unlocked!]]
			self.tooltipHover = true
		end
		xx = x1 + (w * .235)
		idx = 1
		for i = xx - 80, xx + 80, 78 do
			local yy = h2 - 144 + 80
			if idx == 1 or idx == 3 then yy = yy - 12 end
			local key = ctx.upgrades.keys.zuju[idx]
			local name = ctx.upgrades.names.zuju[key]
			local cost = ctx.upgrades.costs.zuju[key][ctx.upgrades.zuju[key] + 1] or ''
			if math.inside(mx, my, i - 24, yy, 50, 50) then
				self.tooltip = ctx.upgrades.tooltips.zuju[key][ctx.upgrades.zuju[key] + 1]
				self.tooltipHover = true
			end
			idx = idx + 1
		end

		-- Voodoo
		if #ctx.player.minions < 2 then
			g.draw(self.lock, x1 + (w * .775) - 20, h2 - 144, 0, .6, .6)
		end

		if math.inside(mx, my, x1 + (w * .775) - 32, h2 - 144, 64, 64) then
			if #ctx.player.minions < 2 then
				self.tooltip = [[Vuju
					Cost: 250]]
			else
				self.tooltip = [[Vuju
					Unlocked!]]
			end
			self.tooltipHover = true
		end
		xx = x1 + (w * .78)
		idx = 1
		for i = xx - 78, xx + 78, 78 do
			local yy = h2 - 144 + 80
			if idx == 1 or idx == 3 then yy = yy - 12 end
			local key = ctx.upgrades.keys.vuju[idx]
			local name = ctx.upgrades.names.vuju[key]
			local cost = ctx.upgrades.costs.vuju[key][ctx.upgrades.vuju[key] + 1] or ''
			if math.inside(mx, my, i - 24, yy, 48, 48) then
				self.tooltip = ctx.upgrades.tooltips.vuju[key][ctx.upgrades.vuju[key] + 1]
				self.tooltipHover = true
			end
			idx = idx + 1
		end

		-- MUUUUUUUUUUUUJU
		xx = x1 + (w * .5)
		idx = 1
		for i = xx - 156, xx + 140, 138 do
			local yy = h2 + 16 + 70
			if idx == 1 or idx == 3 then yy = yy - 12 end
			local key = ctx.upgrades.keys.muju[idx]
			local name = ctx.upgrades.names.muju[key]
			local cost = ctx.upgrades.costs.muju[key][ctx.upgrades.muju[key] + 1] or ''
			if math.inside(mx, my, i - 24, yy, 80, 80) then
				self.tooltip = ctx.upgrades.tooltips.muju[key][ctx.upgrades.muju[key] + 1]
				self.tooltipHover = true
			end
			idx = idx + 1
		end

		if self.tooltip ~= '' then
			g.setColor(0, 0, 0, self.tooltipAlpha * 255)
			local textWidth, lines = g.getFont():getWrap(self.tooltip, 250)
			local xx = math.min(mx + 8, love.graphics.getWidth() - textWidth - 24)
			g.rectangle('fill', xx, my + 8, textWidth + 14, lines * g.getFont():getHeight() + 16)
			g.setColor(255, 255, 255, self.tooltipAlpha * 255)
			g.printf(self.tooltip, xx + 8, my + 16, 250)
		end
	end

	g.setColor(255, 255, 255)
	g.draw(self.jujuIcon, 16, 16, 0, .75, .75)
	g.setColor(0, 0, 0)
	g.printf(math.floor(ctx.player.juju), 16, 16 + self.jujuIcon:getHeight() * .375 - (g.getFont():getHeight() / 2), self.jujuIcon:getWidth() * .75, 'center')
	g.setColor(255, 255, 255)
end

function Hud:keypressed(key)
	if (key == 'tab' or key == 'e') and math.abs(ctx.player.x - ctx.shrine.x) < ctx.player.width then
		self.upgrading = not self.upgrading
		return true
	end

	if key == 'escape' and self.upgrading then
		self.upgrading = false
	end
end

function Hud:keyreleased(key)

end

function Hud:mousepressed(x, y, b)
	if not self.upgrading then return end
	local w, h = love.graphics.getDimensions()
	local w2, h2 = w / 2, h / 2
	local x1, y1 = w2 - 300, h2 - 200
	local w, h = 600, 400
	if math.inside(x, y, w2 - 50, h2 + 216, 100, 40) then
		self.upgrading = false
	end
end

function Hud:mousereleased(x, y, b)
	if self.upgrading then
		local w, h = love.graphics.getDimensions()
		local w2, h2 = w / 2, h / 2
		local x1, y1 = w2 - 300, h2 - 200
		local w, h = 600, 400
		local xx

		xx = x1 + (w * .235)
		idx = 1
		for i = xx - 80, xx + 80, 78 do
			local yy = h2 - 144 + 80
			if idx == 1 or idx == 3 then yy = yy - 12 end
			if math.inside(x, y, i - 24, h2 - 144 + 80, 48, 48) then
				local key = ctx.upgrades.keys.zuju[idx]
				local cost = ctx.upgrades.costs.zuju[key][ctx.upgrades.zuju[key] + 1]
				if cost and ctx.player:spend(cost) then
					ctx.upgrades.zuju[key] = ctx.upgrades.zuju[key] + 1
					ctx.sound:play({sound = 'menuClick'})
				end
			end
			idx = idx + 1
		end

		xx = x1 + (w * .78)
		idx = 1
		for i = xx - 78, xx + 78, 78 do
			local yy = h2 - 144 + 80
			if idx == 1 or idx == 3 then yy = yy - 12 end
			if math.inside(x, y, i - 24, yy, 48, 48) then
				local key = ctx.upgrades.keys.vuju[idx]
				local cost = ctx.upgrades.costs.vuju[key][ctx.upgrades.vuju[key] + 1]
				if cost and ctx.player:spend(cost) then
					ctx.upgrades.vuju[key] = ctx.upgrades.vuju[key] + 1
					ctx.sound:play({sound = 'menuClick'})
				end
			end
			idx = idx + 1
		end

		xx = x1 + (w * .5)
		idx = 1
		for i = xx - 156, xx + 140, 138 do
			local yy = h2 + 16 + 70
			if idx == 1 or idx == 3 then yy = yy - 12 end
			if math.inside(x, y, i - 24, h2 + 16 + 80, 48, 48) then
				local key = ctx.upgrades.keys.muju[idx]
				local cost = ctx.upgrades.costs.muju[key][ctx.upgrades.muju[key] + 1]
				if cost and ctx.player:spend(cost) then
					ctx.upgrades.muju[key] = ctx.upgrades.muju[key] + 1
					ctx.sound:play({sound = 'menuClick'})
				end
			end
			idx = idx + 1
		end

		if #ctx.player.minions < 2 and math.inside(x, y, x1 + (w * .775) - 32, h2 - 144, 64, 64) then
			if ctx.player:spend(250) then
				table.insert(ctx.player.minions, Voodoo)
				table.insert(ctx.player.minioncds, 0)
					ctx.sound:play({sound = 'menuClick'})
			end
		end
	end
end

