Animation = class()

Animation.offsetx = 0
Animation.offsety = 0

function Animation:init(owner, vars)
  local name = self.code
  table.merge(vars, self, true)

	local json = spine.SkeletonJson.new()
	json.scale = self.scale 

	self.skeletonData = json:readSkeletonDataFile('media/skeletons/' .. name .. '/' .. name .. '.json')
	self.skeleton = spine.Skeleton.new(self.skeletonData)
	self.skeleton.createImage = function(_, attachment)
		return love.graphics.newImage('media/skeletons/' .. name .. '/' .. attachment.name .. '.png')
	end
	self.skeleton:setToSetupPose()

  self.owner = owner

  self.stateData = spine.AnimationStateData.new(self.skeletonData)

  table.each(self.animations, function(animation, name)
    animation.name = name
    if animation.mix then
      table.each(animation.mix, function(time, to)
        self.stateData:setMix(name, to, time)
      end)
    end
  end)

  self.state = spine.AnimationState.new(self.stateData)

  self.state.onComplete = function(track)
    local action = self:current(track).complete
    if not action then return end
    if type(action) == 'function' then action(self, self.owner)
    elseif type(action) == 'string' then self:set(action) end
  end

  self.state.onEvent = function(track, event)
    if self.on and self.on[event.data.name] then
      self.on[event.data.name](self, self.owner, event)
    end
  end

  if self.initial then self:set(self.initial) end
end

function Animation:update()
  self.skeleton.x = self.owner.x + self.offsetx
  self.skeleton.y = self.owner.y + self.offsety
  self.skeleton.flipX = self.flipX

  local current = self:current()
  if not current then return end
  self.state:update(tickRate * (f.exe(current.speed, self, self.owner) or 1))
  self.state:apply(self.skeleton)
  self.skeleton:updateWorldTransform()
end

function Animation:draw()
  self.skeleton:draw()
end

function Animation:set(name)
  local current = self:current()
  if current and (current.name == name or self.animations[name].priority < current.priority) then return end
  self.state:setAnimationByName(0, name, self.animations[name].loop, 0)
end

function Animation:current(track)
  track = track or 0
  local animation = self.state:getCurrent(track)
  if not animation then return nil end
  return self.animations[animation.animation.name]
end

function Animation:blocking()
  local current = self:current()
  return current and current.blocking
end
