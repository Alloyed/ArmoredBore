Gamestate = require "hump.gamestate"
Class = require "hump.class"
--love.joystick = require('XInputLUA')
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

function help()
	print("This viddy game takes two dueds and one xbax controller")
	print("Dude 1 uses the left stick and trigger")
	print("Dude 2 uses the right stick and trigger")
	print("use the bumper to dash in the direction the stick is pointing")
	print("use the trigger to fire bullet from the gun'sbraster")
end

function makegooey(x)
	x = x or 0
	return function(self)
		g.setColor(self.idlecolor)
		g.rectangle('fill', x, 0, 30, self.hp*30)
		
		g.setColor(0,255,10)
		g.rectangle('line', x, 0, 30, Consts.health*30)
		
		if self.ammo > Consts.bulletcost*3 then
			g.setColor(0, 200, 10)
		else
			g.setColor(200, 0, 10)
		end
		g.rectangle('fill', x, 30 + Consts.health*30, 30, 30)
		
		g.setColor(255, 255, 255)
		g.setFont(fnt)
		g.print(string.format("W%d", self.wins), x, 90 + Consts.health*30)
	end
end

gam = Gamestate.new()

function love.load()
	love.keyboard.setKeyRepeat(.150, .050)
	
	fnt = love.graphics.newFont('VeraMono.ttf', 20)
	console = Console.new(fnt)
	print("welcom to viddy gam be sure to play")
	startsound = love.audio.newSource("stort.wav")
	meshoot = love.audio.newSource("meshoot.wav", "static")
	youshoot = love.audio.newSource("youshoot.wav" , "static")
	hert = love.audio.newSource("beep.wav", "static")
	
	local all_callbacks = {
	'update', 'draw', 'focus', 'keypressed', 'keyreleased',
	'mousepressed', 'mousereleased'
	}

	Gamestate.switch(gam)
	Gamestate.registerEvents(all_callbacks)
end

function gam:enter()
	g.setBackgroundColor(0x33,0x54,0x10)
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


function gam:update(dt)
	--local j = love.joystick
	
	--j.update() --TODO: make xinput/directinput triggerable
	--you.joyx, you.joyy = deadzone(1, 2, .2)
	--me.joyx, me.joyy = deadzone(3, 4, .2)

	you:update(dt)
	me:update(dt)
	
	Boolet.updateall(dt, me, you)
end


function gam:draw()
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
end

function gam.keypressed(key)
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
