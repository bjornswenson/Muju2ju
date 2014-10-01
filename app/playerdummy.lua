PlayerDummy = extend(Player)

function PlayerDummy:activate()
  self.history = NetHistory(self)
  self.animationIndex = nil
  self.animationPrev = nil
  self.animationTime = 0
  self.animationPrevTime = 0
  self.animationAlpha = nil
  self.animationFlip = false

  Player.activate(self)
end

function PlayerDummy:update()
	self.healthDisplay = math.lerp(self.healthDisplay, self.health, 20 * tickRate)
  self.deathTimer = timer.rot(self.deathTimer)
end

function PlayerDummy:get(t)
  return self.history:get(t)
end

function PlayerDummy:draw()
  local t = tick - (interp / tickRate)
  local prev = self:get(t)
  local cur = self:get(t + 1)
  local lerpd = table.interpolate(prev, cur, tickDelta / tickRate)
  
  if prev.animationAlpha and cur.animationAlpha and cur.animationAlpha < prev.animationAlpha then lerpd.animationAlpha = prev.animationAlpha end
  if cur.animationTime < prev.animationTime then lerpd.animationTime = prev.animationTime end
  self.animation:drawRaw(lerpd.animationIndex, lerpd.animationTime, lerpd.animationPrev, lerpd.animationPrevTime, lerpd.animationAlpha, lerpd.animationFlip, lerpd.x, lerpd.y)

  if self.dead then self.ghost:draw(lerpd.ghostX, lerpd.ghostY) end
end

function PlayerDummy:getHealthbar()
  local t = tick - (interp / tickRate)
  local lerpd = table.interpolate(self:get(t), self:get(t + 1), tickDelta / tickRate)
  return lerpd.x, lerpd.y, lerpd.health / lerpd.maxHealth
end

function PlayerDummy:trace(data)
  local animationMap = {
    [0] = nil,
    'idle', 'walk', 'summon', 'death', 'resurrect'
  }

  self.x = data.x or self.x
  self.y = data.y or self.y
  self.health = data.health or self.health
  self.animationTime = data.animationTime or self.animationTime
  self.animationPrevTime = data.animationPrevTime or self.animationPrevTime
  self.animationFlip = data.animationFlip
  self.ghostX = data.ghostX or self.ghostX
  self.ghostY = data.ghostY or self.ghostY
  if self.ghost and data.ghostAngle then self.ghost.angle = math.rad(data.ghostAngle) end

  self.history:add({
    tick = data.tick,
    x = self.x,
    y = self.y,
    health = self.health,
    animationIndex = animationMap[data.animationIndex],
    animationPrev = animationMap[data.animationPrev],
    animationTime = self.animationTime,
    animationPrevTime = data.animationPrevTime,
    animationAlpha = data.animationAlpha,
    animationFlip = self.animationFlip,
    ghostX = self.ghostX,
    ghostY = self.ghostY
  })
end
