local Kuju = extend(Animation)
Kuju.code = 'kuju'

Kuju.scale = .35
Kuju.offsety = 64
Kuju.backwards = true
Kuju.default = 'idle'
Kuju.states = {}

Kuju.states.spawn = {
  priority = 5,
  speed = .21
}

Kuju.states.idle = {
  priority = 1,
  loop = true,
  speed = .21
}

Kuju.states.walk = {
  priority = 1,
  loop = true,
  speed = .73
}

Kuju.states.attack = {
  priority = 1,
  loop = true,
  speed = 1
}

Kuju.states.death = {
  priority = 5,
  speed = .8
}

return Kuju
