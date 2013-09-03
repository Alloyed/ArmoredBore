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
	-- "kp1" = Vec(-1,  1),
	down     = Vec( 0,  1),
	-- "kp3" = Vec( 1,  1),
	left     = Vec(-1,  0),
	-- "kp5" = Vec( 0,  0),
	right    = Vec( 1,  0),
	-- "kp7" = Vec(-1, -1),
	up       = Vec( 0, -1)
	-- "kp9" = Vec( 1, -1)
}

function kbupdate(player)
	return function()
		local v = Vec(0, 0)
			for key, dist in pairs(ks) do
			if lk.isDown(key) then
				v = v + dist
			end
		end
		v:normalize_inplace()
		apply(player, v.x, v.y)
	end
end

local function rtime()
	return math.random() * .4 + .9
end

function robot(player)
	local roll  = makeroll(player)
	local shoot = shootat(player)
	Timer.add(rtime(), function(fn) shoot() Timer.add(rtime(), fn) end)
	local dir = 1
	local joy = Vec(0, 0)
	return function()
		local o = player.other
		local v = Vec(player.cx-o.cx, player.cy-o.cy):normalized():rotated(dir * math.pi/1.8)
		if (o.move.name == "firing" and player.move.name == "idle") then
			roll()
			if math.random() > .75 then dir = dir * -1 end
		end
		local n = .3
		joy = (joy * (1 - n)) + (v * n)
		apply(player, joy.x, joy.y)
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

local xpad = nil
if love._os:match("indows") then -- not a massive diff. but it bugs me
	xpad = {
		-- Axes
		lx = 1, ly = -2, lt = -5,
		rx = 3, ry = -4, rt = -6,
		-- Buttons
		lb = 7,  rb = 8,
		ls = 11, rs = 12
	}
else
	xpad = {
		-- Axes
		lx = 1, ly = 2, lt = 3,
		rx = 4, ry = 5, rt = 6,
		-- Buttons
		lb = 5,  rb = 6,
		ls = 11, rs = 12
	}
end

function schemes.joypad(player, joy, buttons, num)
	assert(player)
	local joy1, joy2, bump, trig
	if joy == 'l' then
		joy1, joy2, joy3 = xpad.lx, xpad.ly, xpad.ls
	else
		joy1, joy2, joy3 = xpad.rx, xpad.ry, xpad.rs
	end

	if buttons == 'l' then
		bump, trig = xpad.lb, xpad.lt
	else
		bump, trig = xpad.rb, xpad.rt
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
	player.segments = 8 -- 8 way style for dpads
	register({"keyboard", "z"}, shootat(player))
	register({"keyboard", "x"}, makeroll(player))
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


