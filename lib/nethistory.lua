NetHistory = class()

function NetHistory:init(owner)
  self.entries = {}
  self.owner = owner
  self.meta = {__index = self.owner}
end

function NetHistory:get(t)
  if t == tick then return self.owner end

  local history = self.entries

  if #history < 2 then
    return setmetatable({
      tick = tick
    }, self.meta)
  end

  while history[1].tick < tick - 2 / tickRate and #history > 2 do
    table.remove(history, 1)
  end

  if history[#history].tick < t then
    local h1, h2 = history[#history - 1], history[#history]
    local factor = math.min(1 + ((t - h2.tick) / (h2.tick - h1.tick)), .25 / tickRate)
    return table.interpolate(h1, h2, factor)
  end

  for i = #history, 1, -1 do
    if history[i].tick <= t then return history[i] end
  end

  return history[1]
end

function NetHistory:add(entry)
  table.insert(self.entries, setmetatable(entry, self.meta))
end
