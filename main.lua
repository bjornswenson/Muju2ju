require 'require'

runes = {
  { name = 'Agility Rune',
    description = 'This rune will make your minion faster.'
  },
  { name = 'Force Rune',
    description = '50 DPS PLUS'
  },
  { name = 'Fortitude Rune',
    description = 'This rune will make your minion stronk.'
  },
  { name = 'Frenzy Rune',
    description = 'This rune will make ur minion like its on some speed',
  },
  { name = 'Range Rune',
    description = 'This rune will make ur minion attack farther'
  }
}

testConfig = {
  ip = '127.0.0.1',
  port = 6061,
  players = {
    { username = 'player',
      ip = '127.0.0.1',
      team = 1,
      color = 'purple',
      skin = {},
      deck = {
        { code = 'duju',
          skin = {},
          runes = {}
        },
        { code = 'kuju',
          skin = {},
          runes = {}
        },
        { code = 'huju',
          skin = {},
          runes = {}
        }
      }
    },
    --[[{ username = 'yoko',
      ip = '127.0.0.1',
      team = 2,
      color = 'purple',
      skin = {},
      deck = {
        { code = 'bruju',
          skin = {},
          runes = {}
        }
      }
    }]]
  },
  game = {
    gameType = 'versus',
    options = {}
  }
}

function love.load()
  data.load()

  if table.has(arg, 'server') then
    local config
    if table.has(arg, 'test') then
      config = testConfig
    else
      if love.filesystem.exists('config.json') then
        local json = require 'lib/deps/dkjson'
        local string = love.filesystem.read('config.json')
        config = json.decode(string)
      else
        error('Server missing config file')
      end
    end

    Context:add(Server, config)
  else
    Context:add(Menu)
  end
end

love.update = Context.update
love.draw = Context.draw
love.quit = Context.quit

love.handlers = setmetatable({}, {__index = Context})
