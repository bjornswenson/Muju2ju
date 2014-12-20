data = {}
data.load = function()

  -- Media
	local function lookup(ext, fn)
		local function halp(s, k)
			local base = s._path .. '/' .. k
			if love.filesystem.exists(base .. ext) then
				s[k] = fn(base .. ext)
			elseif love.filesystem.isDirectory(base) then
				local t = {}
				t._path = base
				setmetatable(t, {__index = halp})
				s[k] = t
			end

			return rawget(s, k)
		end

		return halp
	end

  data.media = {}
	data.media.graphics = setmetatable({_path = 'media/graphics'}, {__index = lookup('.png', love.graphics and love.graphics.newImage or f.empty)})
	data.media.shaders = setmetatable({_path = 'media/shaders'}, {__index = lookup('.shader', love.graphics and love.graphics.newShader or f.empty)})
	data.media.sounds = setmetatable({_path = 'media/sounds'}, {__index = lookup('.ogg', love.audio and love.audio.newSource or f.empty)})

  -- Data
  local function load(dir, type, fn)
    local id = 1
    local function halp(dir, dst)
      for _, file in ipairs(love.filesystem.getDirectoryItems(dir)) do
        path = dir .. '/' .. file
        if love.filesystem.isDirectory(path) then
          dst[file] = {}
          halp(path, dst[file])
        elseif file:match('%.lua$') and not file:match('^%.') then
          local obj = love.filesystem.load(path)()
          obj = f.exe(fn, obj) or obj
          obj.id = id
          data[type][id] = obj
          dst[obj.code] = obj
          id = id + 1
        end
      end
    end

    data[type] = {}
    halp(dir, data[type])
  end

  load('data/buff', 'buff')
  load('data/ability', 'ability')
  load('data/unit', 'unit')
  load('data/spell', 'spell')
  load('data/animation', 'animation', function(animation)
    local keys = table.keys(animation.states)
    table.sort(keys)

    for i = 1, #keys do
      local state = animation.states[keys[i]]
      animation.states[i] = state
      state.index = i
      state.name = keys[i]
    end

    return animation
  end)
  load('data/particle', 'particle')
  load('data/effect', 'effect')
  load('data/gooey', 'gooey')
end

