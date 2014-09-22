NetServer = extend(Net)

NetServer.signatures = {}
NetServer.signatures[evtLeave] = {{'id', '4bits'}, {'reason', 'string'}, important = true}
NetServer.signatures[evtSync] = {
  {'id', '4bits'},
  {'tick', '16bits'},
  {'ack', '16bits'},
  {'x', '16bits'}, {'y', '16bits'},
  {'health', '10bits'},
  {'minion', '3bits'},
  delta = {'x', 'y', 'health', 'minion'}
}
NetServer.signatures[evtDead] = {{'id', '4bits'}, important = true}
NetServer.signatures[evtSpawn] = {{'id', '4bits'}, important = true}
NetServer.signatures[msgJoin] = {{'id', '4bits'}, {'tick', '16bits'}, important = true}

NetServer.receive = {}
NetServer.receive['default'] = f.empty

NetServer.receive[msgJoin] = function(self, event)
  local pid = self.peerToPlayer[event.peer]
  self:send(msgJoin, event.peer, {id = pid, tick = tick})
  --[[
  if everyoneHasConnected then
    self:emit(evtReady)
  end
  ]]
end

NetServer.receive[msgLeave] = function(self, event) self:disconnect(event) end

NetServer.receive[msgInput] = function(self, event)
  ctx.players:get(self.peerToPlayer[event.peer]):trace(event.data, event.peer:round_trip_time())
end

function NetServer:init()
  self.other = NetClient

  self:listen(6061)
  self.peerToPlayer = {}
  self.eventBuffer = {}
  self.importantEventBuffer = {}

  ctx.event:on('game.quit', function(data)
    self:quit()
  end)

  Net.init(self)
end

function NetServer:quit()
  if self.host then
    for i = 1, ctx.players.max do
      if self.host:get_peer(i) then self.host:get_peer(i):disconnect_now() end
    end
    self.host:flush()
  end
  self.host = nil
end

function NetServer:connect(event)
  self.peerToPlayer[event.peer] = #ctx.players.players
  event.peer:timeout(0, 0, 3000)
  event.peer:ping()
end

function NetServer:disconnect(event)
  local pid = self.peerToPlayer[event.peer]
  local reason = event.reason or 'left'
  self:emit(evtLeave, {id = pid, reason = reason})
  self.peerToPlayer[event.peer] = nil
  event.peer:disconnect_now()
end

function NetServer:send(msg, peer, data)
  self.outStream:clear()
  self:pack(msg, data)
  peer:send(tostring(self.outStream))
end

function NetServer:emit(evt, data)
  if not self.host then return end
  local buffer = self.signatures[evt].important and self.importantEventBuffer or self.eventBuffer
  table.insert(buffer, {evt, data})
  ctx.event:emit(evt, data)
end

function NetServer:sync()
  if not self.host then return end
  
  if #self.importantEventBuffer > 0 then
    self.outStream:clear()
    while #self.importantEventBuffer > 0 do
      self:pack(unpack(self.importantEventBuffer[1]))
      table.remove(self.importantEventBuffer, 1)
    end

    self.host:broadcast(tostring(self.outStream), 0, 'reliable')
  end

  if #self.eventBuffer > 0 then
    self.outStream:clear()
    while #self.eventBuffer > 0 do
      self:pack(unpack(self.eventBuffer[1]))
      table.remove(self.eventBuffer, 1)
    end

    self.host:broadcast(tostring(self.outStream), 1, 'unreliable')
  end
end
