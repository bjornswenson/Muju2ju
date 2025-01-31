local rich = require 'lib/deps/richtext/richtext'

HudChat = class()

local g = love.graphics

function HudChat:init()
  self.active = false
  self.message = ''
  self.log = ''
  self.timer = 0
  self.offset = -love.graphics.getWidth()
  self.prevOffset = self.offset
  self.richText = nil

  ctx.event:on('chat', f.cur(self.add, self))
end

function HudChat:update()
  local u, v = ctx.hud.u, ctx.hud.v
  self.timer = timer.rot(self.timer)
  if self.active or ctx.hud.countdown.active then self.timer = 2 end
  self.prevOffset = self.offset
  self.offset = math.lerp(self.offset, (self.timer == 0) and -(u * .35) - 4 or 0, math.min(tickRate * 15, 1))
end

function HudChat:draw()
  local u, v = ctx.hud.u, ctx.hud.v
  local width = u * .25
  if #self.log == 0 and not self.active then return end

  local upgradeFactor = ctx.hud.upgrades:getFactor()
  if self.timer > 0 then upgradeFactor = math.min(upgradeFactor, 1)
  elseif upgradeFactor > 1 then upgradeFactor = 1 + (upgradeFactor - 1) / 4 end
  local upgradeOffset = -(u * .35) - 4 + (u * .35 + 4) * upgradeFactor
  local offset = math.lerp(self.prevOffset, self.offset, tickDelta / tickRate)
  offset = math.max(offset, upgradeOffset)

  g.setFont('pixel', 8)
  local font = g.getFont()
  local height = (self.richText and self.richText.height or 0) - 2
  if self.active then height = height + (font:getHeight() + 6.5) - 1 end
  
  g.setColor(0, 0, 0, 180)
  g.rectangle('fill', 4 + offset, v - (height + 4), width, height)
  g.setColor(30, 30, 30, 180)
  g.rectangle('line', 4 + offset, v - (height + 4), width, height)
  local yy = v - 4
  if self.active then
    g.setColor(255, 255, 255, 60)
    g.line(4.5 + offset, v - 4 - font:getHeight() - 6.5, 3 + width + offset, v - 4 - font:getHeight() - 6.5)
    g.setColor(255, 255, 255, 180)
    g.printf(self.message, 4 + 4 + offset, math.round(yy - font:getHeight() - 5.5 + 2), width, 'left')
    if self.active then
      local cursorx = math.round(4 + 4 + offset + font:getWidth(self.message)) + 1
      local cursory = math.round(yy - font:getHeight() - 5.5 + 2 + 1)
      g.line(cursorx + .5, cursory + .5, cursorx + .5, cursory + font:getHeight() - 2 + .5)
    end
    yy = yy - font:getHeight() - 6.5
  end

  if self.richText then
    self.richText:draw(4 + 4 + offset, math.round(yy - self.richText.height + 4))
  end
end

function HudChat:textinput(character)
  if self.active then
    self.message = self.message .. character
  end
end

function HudChat:keypressed(key)
  if self.active then
    if key == 'backspace' then self.message = self.message:sub(1, -2)
    elseif key == 'return' or key == 'escape' then
      if #self.message > 0 and key ~= 'escape' then
        ctx.net:send('chat', {
          message = self.message
        })
      end
      self.active = false
      self.message = ''
    end
    
    return true
  elseif key == 'return' then
    self.active = true
    self.message = ''
  end
end

function HudChat:add(data)
  local message = data.message
  local u, v = ctx.hud.u, ctx.hud.v
  local width = u * .25
  
  if #message > 0 then
    if #self.log > 0 then self.log = self.log .. '\n' end
    self.log = self.log .. message
  end

  g.setFont('pixel', 8)
  while ctx.hud.u > 0 and g.getFont():getHeight() * select(2, g.getFont():getWrap(self.log, width)) > (v * .25 - 2) do
    self.log = self.log:sub(2)
  end

  self.log = '{white}' .. self.log
  
  self:refresh()
  self.timer = math.min(2 + (#message / 50), 5)
end

function HudChat:resize()
  self:refresh()
end

function HudChat:refresh()
  if #self.log == 0 then return end
  local u, v = ctx.hud.u, ctx.hud.v
  local width = u * .25 - 4
  g.setFont('pixel', 8)
  self.richText = rich:new({self.log, width, {white = {255, 255, 255}, purple = {190, 160, 220}, orange = {240, 160, 140}, red = {255, 0, 0}, green = {0, 255, 0}}}, {255, 255, 255})
end
