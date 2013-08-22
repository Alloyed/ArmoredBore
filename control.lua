local json = require "misc.dkjson"

module(..., package.seeall)

local joypad = require 'joypad'

local functions = {}
local updatefn = {}

function reset()
	joypad.init()
	local cb = {}
	function cb.buttonpressed()
	end
	joypad.setCallbacks({buttonpressed = joystickdo, triggeron = triggerdo})
	functions = {}
	updatefn = {}
end

function register(key, fn)
	if key == "update" then
		table.insert(updatefn, fn)
		return
	end
	functions[tokey(unpack(key))] = fn
end

function tokey(...)
	local name, arg1, arg2 = ...
	if name == "update" then
		return "update"
	elseif name == "joystick" then
		return string.format("%s:%d:%d", name, arg1, arg2)
	elseif name == "keyboard" or
		    name == "mouse"    or
			 name == "trigger"  then
		return string.format("%s:%s", name, arg1)
	else
		assert(nil, string.format("Invalid event of type %s", name))
		return nil --you should probably catch this
	end
end

function joystickdo(joy, btn)
	local fn = functions[tokey("joystick", joy, btn)]
	if fn then return fn() end
end

function keyboarddo(btn, uni)
	local fn = functions[tokey("keyboard", btn, uni)]
	if fn then return fn() end
end

function mousedo(btn)
	local fn = functions[tokey("mouse", btn)]
	if fn then return fn() end
end

function triggerdo(trg)
	local k = tokey("trigger", trg)
	local fn = functions[k]
	if fn then return fn() end
end

function update(dt)
	joypad.update(dt)
	for _, fn in ipairs(updatefn) do
		if fn then fn(dt) end
	end
end

function makeroll(dude)
	return function()
		dude.movebuf[#dude.movebuf].roll = true
		dude:pushmove(moves.roll, dude.joyx, dude.joyy)
	end
end

function shootat(dude)
	return function()
		dude.movebuf[#dude.movebuf].shoot = true
		dude:pushmove(moves.fire)
	end
end

-- this looks funky but that's why it's hidden in a function
local function apply(player, joyx, joyy)
	player.joyx, player.joyy = joyx, joyy
	player.movebuf[#player.movebuf].joy = {joyx, joyy}
end

function joyupdate(player, stick)
	local deadzone = .25
	return function()
		local v = Vec(joypad.getStick(stick))
		if v:len2() < deadzone * deadzone then
			apply(player, 0, 0)
		else
			apply(player, v.x, v.y)
		end
	end
end

function mouseupdate(player)
	local camera = player.game.camera
	return function()
		local x, y = camera:mousepos()
		local v = Vec((x-player.x) / balance.dashradius ,(y-player.y) / balance.dashradius )
		if v:len() > 1 then
			v:normalize_inplace()
		end
		apply(player, v.x, v.y)
	end
end

local ks = {
	Vec(-1,  1),
	Vec( 0,  1),
	Vec( 1,  1),
	Vec(-1,  0),
	Vec( 0,  0),
	Vec( 1,  0),
	Vec(-1, -1),
	Vec( 0, -1),
	Vec( 1, -1)
}

function kbupdate(player)
	return function()
		local kb = love.keyboard.isDown
		local v = Vec(0, 0)
			for k, val in ipairs(ks) do
			if kb("kp"..tostring(k)) then
				v = v + val
			end
		end
		v:normalize_inplace()
		apply(player, v.x, v.y)
	end
end

function robot(player)
	local roll  = makeroll(player)
	local shoot = shootat(player)
	Timer.addPeriodic(1.3, shoot)
	local cdown = false
	return function()
		local o = player.other
		local v = Vec(-o.joyx, -o.joyy)
		if (not cdown and o.move.name == "firing") then
			roll()
			cdown = true
			Timer.add(2, function() cdown = false end)
		end
		apply(player, v.x, v.y)
	end
end

function replay(player, buffa)
	local roll, shoot =
	makeroll(player), shootat(player)
	return function()
		local cbuf = buffa[#player.movebuf] or buffa[#buffa]
		if cbuf.roll then
			roll()
		elseif cbuf.shoot then
			shoot()
		end
		local joyx, joyy = unpack(cbuf.joy)
		apply(player, joyx, joyy)
	end
end

schemes = {}

function schemes.joypad(player, joy, buttons, num)
	local joy1, joy2, bump, trig
	if joy == 'l' then
		joy1, joy2, joy3 = 1, 2, 11
	else
		joy1, joy2, joy3 = 4, 5, 12
	end

	if buttons == 'l' then
		bump, trig = 5, 3
	else
		bump, trig = 6, 6
	end
	register({"trigger", joypad.newTrigger(num, trig, .5)}, shootat(player))
	register({"joystick", num, bump}, makeroll(player))
	-- register({"joystick", num, joy3}, switch(player))
	register("update", joyupdate(player, joypad.newStick(num, joy1, joy2)))
end

function schemes.moose(player)
	register({"mouse", "l"}, shootat(player))
	register({"mouse", "r"}, makeroll(player))
	-- register({"mouse", "m"}, switch(player))
	register("update", mouseupdate(player))
end

function schemes.numpad(player)
	register({"keyboard", "kp0"}, shootat(player))
	register({"keyboard", "kp5"}, makeroll(player))
	-- register({"keyboard", "kp+"}, switch(player))
	register("update", kbupdate(player))
end

function schemes.what(player)
	register("update", robot(player))
end

function schemes.replay(player, key)
	local str = lfs.read("buffa.json")
	local buf = json.decode(str)
	register("update", replay(player, buf[key]))
end


