Server = class()

Server.tag = 'server'

function Server:load(config)
  self.config = config

	self.paused = false
	self.over = false
  self.timer = 0

  self.event = Event()
  self.net = NetServer()
  self.map = Map()
	self.players = Players()
  self.upgrades = Upgrades()
  self.shrines = Manager()
  self.units = Units()
  self.jujus = Jujus()
  self.shrujus = Shrujus()
  self.spells = Spells()
	self.target = Target()

  if ctx.config.game.gameType == 'survival' then
    ctx.shrines:add(Shrine, {x = ctx.map.width / 2, team = 1})
  elseif ctx.config.game.gameType == 'versus' then
    ctx.shrines:add(Shrine, {x = ctx.map.width * .15, team = 1})
    ctx.shrines:add(Shrine, {x = ctx.map.width * .85, team = 2})
  end

  self.event:on('shrine.dead', function(data)
    if self.net.state ~= 'ending' then
      self.net.state = 'ending'
      if ctx.config.game.gameType == 'survival' then
        ctx.net:emit('over', {winner = 0})
      else
        ctx.net:emit('over', {winner = data.shrine.team == 1 and 2 or 1})
      end

    end
  end)
end

function Server:update()
	if self.paused or self.over then return end

  self.net:update()

  if self.net.state == 'waiting' or self.net.state == 'ending' then return self.net:sync() end

  self.timer = self.timer + 1
	self.players:update()
	self.shrines:update()
  self.units:update()
  self.jujus:update()
  self.shrujus:update()
  self.spells:update()

  self.net:snapshot()

  self.net:sync()
end
