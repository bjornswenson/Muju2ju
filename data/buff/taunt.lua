local Taunt = class()
Taunt.code = 'taunt'
Taunt.tags = {'taunt'}

function Taunt:activate(owner, target, timer)
  self.target = target
  self.timer = timer
end

function Taunt:postupdate()
  self.owner.target = self.target

  self.timer = timer.rot(self.timer, function()
    self.owner.buffs:remove(self)
  end)
end

return Taunt
