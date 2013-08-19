module(..., package.seeall)

--TODO: rewrite love.run to include this stuff
-- XInput = require('XInputLUA') --TODO: selectively disable
local joypad = require 'joypad'

local functions = {}
local updatefn = {}

function reset()
	functions = {}
	updatefn = {}
end

function register(key, fn)
	if key == "update" then
		table.insert(updatefn, fn)
		return
	end
	functions[tokey(key)] = fn
end

function tokey(tabl)
	local one, two, three = unpack(tabl)
	if one == "update" then
		return "update"
	elseif one == "joystick" then
		return string.format("%s:%d:%d", one, two, three)
	elseif one == "keyboard" then
		return string.format("%s:%s", one, two)
	elseif one == "mouse" then
		return string.format("%s:%s", one, two)
	else
		return nil --you should probably catch this
	end
end

function joystickdo(joy, btn, wasreleased)
	local fn = functions[tokey({"joystick", joy, btn})]
	if fn then
		fn()
	end
end

function keyboarddo(btn, uni)
	local fn = functions[tokey({"keyboard", btn, uni})]
	if fn then
		fn()
	end
end

function mousedo(btn)
	local fn = functions[tokey({"mouse", btn})]
	if fn then
		fn()
	end
end

function update(dt)
	for i, v in ipairs(updatefn) do
		if v then
			v(dt)
		end
	end
end

function makeroll(dude)
	return function()
		dude:pushmove(moves.roll, dude.joyx, dude.joyy)
	end
end

function shootat(dude)
	return function()
		dude:pushmove(moves.fire)
	end
end

function switch(dude)
	return function()
		dude.ammotype = dude.buf:next()
	end
end

function joyupdate(player, joynum, xaxis, yaxis)
	local deadzone = .2
	return function()
		local xm, ym = xaxis > 0 and 1 or -1, yaxis > 0 and 1 or -1
		local xaxis, yaxis = math.abs(xaxis), math.abs(yaxis)
		local v = Vec(xm * ljoy.getAxis(joynum, xaxis), ym * lj.getAxis(joynum, yaxis))
		if v:len2() < deadzone * deadzone then
			player.joyx, player.joyy = 0, 0
		else
			player.joyx, player.joyy = v.x, v.y
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
		player.joyx, player.joyy = v:unpack()
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
		player.joyx, player.joyy = v:unpack()
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
		player.joyx, player.joyy = v:unpack()
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
		bump, trig = 5, 1
	else
		bump, trig = 6, 2
	end
	register({"joystick", num, trig}, shootat(player))
	register({"joystick", num, bump}, makeroll(player))
	register({"joystick", num, joy3}, switch(player))
	register("update", joyupdate(player, num, joy1, joy2))
end

function schemes.moose(player)
	register({"mouse", "l"}, shootat(player))
	register({"mouse", "r"}, makeroll(player))
	register({"mouse", "m"}, switch(player))
	register("update", mouseupdate(player))
end

function schemes.numpad(player)
	register({"keyboard", "kp0"}, shootat(player))
	register({"keyboard", "kp5"}, makeroll(player))
	register({"keyboard", "kp+"}, switch(player))
	register("update", kbupdate(player))
end

function schemes.what(player)
	register("update", robot(player))
end


