
module(..., package.seeall)

local functions = {}
local updatefn = {}

function register(key, fn)
  if key == "update"
    table.insert(updatefn, fn)
    return
  end
  local type = key[1]
  assert(type == "joystick" or type == "keyboard" or type == "mouse")
  functions[key] = fn
end

function joystickdo(joy, btn, wasreleased)
  local fn = joypfn[{"joystick", joy, btn}]
  if fn then
    fn()
  end 
end

function update(dt)
  for i, v in ipairs(updatefn) do
    v(dt)
  end
end

function makeroll(dude)
  return function()
    local r = moves.roll(dude)
    r:point2(dude.joyx, dude.joyy)
    if r.vx then
      dude:setmove(r)
    end
  end
end

function shootat(otherdude)
  return function()
    local f = moves.fire(otherdude)
    otherdude:setmove(f)
  end
end

function deadzone(jnum, xaxis, yaxis, dz)
  local v = Vec(love.joystick.getAxis(jnum, xaxis), -love.joystick.getAxis(jnum, yaxis))
  if v:len() < dz then
    return 0, 0
  else
    return v:unpack()
  end
end


function joyupdate(player, joynum, axis1, axis2)
  return function()
    if not player then
      return
    end

    player.joyx, player.joyy = deadzone(joynum, axis1, axis2, .2)
  end
end

function mouseupdate(player)
  return function()
    player.joyx, player.joyy = 1, 0
  end
end

function leftjoy(player)
  register({"joystick", 1, 5}, shootat(player)) 
  register({"joystick", 1, 7}, makeroll(player)) 
  register("update", joyupdate(player, 1, 1, 2) 
end

function rightjoy(player)
  register({"joystick", 1, 6}, shootat(player)) 
  register({"joystick", 1, 8}, shootat(player)) 
  register("update", joyupdate(player, 1, 1, 2) 
end

function moose(player)
  register({"mouse", 2}, shootat(player))
  register({"mouse", 1}, makeroll(player))
  register("update", mouseupdate(player))
end 
