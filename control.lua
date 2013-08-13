module(..., package.seeall)

--TODO: rewrite love.run to include this stuff
-- XInput = require('XInputLUA') --TODO: selectively disable
local lj = love.joystick

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
		local r = moves.roll(dude)
		r:point2(dude.joyx, dude.joyy)
		if r.vx then
			dude:setmove(r)
		end
	end
end

function shootat(dude)
	return function()
		local f = moves.fire(dude)
		dude:setmove(f)
	end
end

function switch(dude)
	return function()
		dude.ammotype = dude.buf:next()
	end
end

function deadzone(jnum, xaxis, yaxis, dz)
	local v = Vec(lj.getAxis(jnum, xaxis), -lj.getAxis(jnum, yaxis))
	if v:len() < dz then
		return 0, 0
	else
		return v:unpack()
	end
end

local joyx, joyy = {}, {}
local xi, yi = 1, 1
function joyupdate(player, joynum, axis1, axis2)
	return function()
		if not player then
			return
		end

		player.joyx, player.joyy = deadzone(joynum, axis1, axis2, .2)
	joyx[xi], joyy[yi] = player.joyx, player.joyy
	xi = math.mod(xi + 1, 60)
	yi = math.mod(yi + 1, 60)
	end
end

function mouseupdate(player)
	return function()
		local v = Vec(.01 * (love.mouse.getX()-player.x), .01 * (love.mouse.getY()-player.y))
		if v:len() > 1 then
			v:normalize_inplace()
		end
		player.joyx, player.joyy = v:unpack()
	end
end

local xxi, yyi = 30, 30
function randomdate(player)
	return function()
		player.joyx, player.joyy = joyx[xxi] or 0, joyy[yyi] or 0
		xxi = math.mod(xi + 1, 60)
		yyi = math.mod(yi + 1, 60)
	end
end

local ks = {
	Vec(-1, 1),
	Vec(0, 1),
	Vec(1, 1),
	Vec(-1, 0),
	Vec(0, 0),
	Vec(1, 0),
	Vec(-1, -1),
	Vec(0, -1),
	Vec(1, -1)
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

schemes = {}

function schemes.joypad(player, joy, buttons, num)
	local joy1, joy2, bump, trig
	if joy == 'l' then
		joy1, joy2, joy3 = 1, 2, 11
	else
		joy1, joy2, joy3 = 3, 4, 12
	end

	if buttons == 'l' then
		bump, trig = 7, 5
	else
		bump, trig = 8, 6
	end
	register( {"joystick", num, trig}, shootat(player)) 
	register( {"joystick", num, bump}, makeroll(player)) 
	register( {"joystick", num, joy3}, switch(player))
	register( "update", joyupdate(player, num, joy1, joy2)) 
end

function schemes.moose(player)
	register( {"mouse", "l"}, shootat(player))
	register( {"mouse", "r"}, makeroll(player))
	register( {"mouse", "m"}, switch(player))
	register( "update", mouseupdate(player))
end

function schemes.numpad(player)
	register( {"keyboard", "kp0"}, shootat(player))
	register( {"keyboard", "kp5"}, makeroll(player))
	register( {"keyboard", "kp+"}, switch(player))
	register( "update", kbupdate(player))
end

function schemes.what(player)
	register("update", randomdate(player))
end


