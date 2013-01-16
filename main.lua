Gamestate = require "hump.gamestate"
Class = require "hump.class"
love.joystick = require('XInputLUA')
dump = require "dump"
Vec = require "hump.vector"
Boolet = require "Boolet"
Consts = require "balance"
moves = require "moves"


Console = require "console.console"
console = nil
input   = nil
output  = nil
you     = nil
me      = nil
g = love.graphics

Dude = require "player"
local fnt = nil

function makegooey(x)
	x = x or 0
	return function(self)
		g.setColor(self.idlecolor)
		g.rectangle('fill', x, 0, 30, self.hp*30)
		g.setColor(0,255,10)
		g.rectangle('line', x, 0, 30, Consts.health*30)
		g.setFont(fnt)
		g.print(self.wins, x, g.getHeight()-20)
	end
end


function love.load()
	love.keyboard.setKeyRepeat(.150, .050)
	g.setBackgroundColor(0x33,0x54,0x10)

	fnt = love.graphics.newFont('VeraMono.ttf', 20)
	console = Console.new(fnt)
	print("welcom to viddy gam be sure to play")
	startsound = love.audio.newSource("stort.wav")
	meshoot = love.audio.newSource("meshoot.wav", "static")
	youshoot = love.audio.newSource("youshoot.wav" , "static")
	justlikemakegame()
end


function justlikemakegame()
	local ywin, mwin = (you or {wins = 0}).wins, (me or {wins = 0}).wins or 0
	Boolet.reset()
	--LEF
	you = Dude()
	you.name = "Leftbro"
	you.idlecolor = {0xFF,0x9A,0x00}
	you.movecolor = {0xFF, 0xC0,0x00}
	you.CDcolor = {0x80, 0x66, 0x40}
	you.gooey = makegooey(0)
	you.wins = ywin
	you.shoot = youshoot
	
	--RIGH
	me = Dude()
	me.name = "Rightbro"
	me.x = 900
	me.y = 700
	me.idlecolor = {0x05, 0x00, 0xFF}
	me.movecolor = {0x00, 0x79, 0xFF}
	me.CDcolor = {0x40, 0x5E, 0x80}
	me.gooey = makegooey(g.getWidth()-30)
	me.wins = mwin
	me.shoot = meshoot
	
	me.other = you
	you.other = me
	
	joyfn[7] = makeroll(you) --LB
	joyfn[8] = makeroll(me) --RB
	joyfn[5] = shootat(you) --LT
	joyfn[6] = shootat(me) --RT
	
	love.audio.stop(startsound)
	love.audio.play(startsound)
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
	
	Boolet.updateall(dt, me, you)
end

function love.draw()
	you:draw()
	me:draw()
	Boolet.drawall()
	
	you:gooey()
	me:gooey()
	g.setColor(255,255,255)
	if console:isfocused() then
		console:draw(love.graphics.getWidth(), love.graphics.getHeight())
	end
end

joyfn = {}

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


function love.joystickpressed(joy, btn)
	local fn = joyfn[btn]
	if fn then
		fn()
	end
--	if btn == 5 then --LT
--		local f = moves.fire(you)
--		you:setmove(f)
--	elseif btn == 6 then --RT
--		local f = moves.fire(me)
--		me:setmove(f)
--	elseif btn == 7 then --LB
--		local r = moves.roll(you)
--		r:point2(you.joyx, you.joyy)
--		if r.vx then
--			you:setmove(r)
--		end
--	elseif btn == 8 then --RB
--		local r = moves.roll(me)
--		r:point2(me.joyx, me.joyy)
--		if r.vx then
--			me:setmove(r)
--		end
--	end
end

function love.keypressed(key)
	if key == "escape" then
		console:focus()
	end
end

function print(...)
	return console:print(...)
end

function printf(fmt, ...)
	return print(string.format(fmt, ...))
end

function quit()
	love.event.push('quit')
end
exit = quit
