Gamestate = require "hump.gamestate"
Class = require "hump.class"
love.joystick = require('XInputLUA')
--dump = require "dump"
Vec = require "hump.vector"
Boolet = require "Boolet"
Consts = require "balance"
moves = require "moves"

console = nil
input   = nil
output  = nil


Dude = require "player"

function makegooey(x)
	x = x or 0
	return function(self)
		g.setColor(self.idlecolor)
		g.print(string.format("HP: %d", self.hp), x, 0)
	end
end

you = Dude()
you.name = "YOU"
you.idlecolor = {0xFF,0x9A,0x00}
you.movecolor = {0xFF, 0xC0,0x00}
you.CDcolor = {0x80, 0x66, 0x40}
you.gooey = makegooey(0)


me = Dude()
me.name = "ME "
me.idlecolor = {0x05, 0x00, 0xFF}
me.movecolor = {0x00, 0x79, 0xFF}
me.CDcolor = {0x40, 0x5E, 0x80}
me.gooey = makegooey(700)

function love.load()
	g = love.graphics
	love.keyboard.setKeyRepeat(150, 50)
	g.setBackgroundColor(0x33,0x54,0x10)
end


function deadzone(xaxis, yaxis, dz) 
	local v = Vec(love.joystick.getAxis(1, xaxis), -love.joystick.getAxis(1, yaxis))
	if v:len() < dz then
		return 0, 0
	else
		return v:unpack()
	end
end

function love.update(dt)
	local j = love.joystick
	
	j.update() --TODO: make xinput/directinput triggerable
	you.joyx, you.joyy = deadzone(1, 2, .2)
	me.joyx, me.joyy = deadzone(3, 4, .2)
	
	you:update(dt)
	me:update(dt)
	
	for k, v in pairs(Boolet.boolets) do
		v:update(dt, me, you)
	end
end

function love.draw()
	you:draw()
	me:draw()
	
	for k, v in pairs(Boolet.boolets) do
		v:draw()
	end
	
	you:gooey()
	me:gooey()
end

function love.joystickpressed(joy, btn)
	if btn == 5 then --LT
		local f = moves.fire(you)
		you:setmove(f)
	elseif btn == 6 then --RT
		local f = moves.fire(me)
		me:setmove(f)
	elseif btn == 7 then --LB
		local r = moves.roll(you)
		r:point2(you.joyx, you.joyy)
		if r.vx then
			you:setmove(r)
		end
	elseif btn == 8 then --RB
		local r = moves.roll(me)
		r:point2(me.joyx, me.joyy)
		if r.vx then
			me:setmove(r)
		end
	end
end