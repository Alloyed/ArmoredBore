--libs/utilities
XInput = require('XInputLUA') --TODO: selectively disable
Gamestate = require "hump.gamestate"
Class   = require "hump.class"
Vec     = require "hump.vector"
Timer   = require "hump.timer"
Console = require "console.console"
dump    = require "dump"
--our own things
Boolet  = require "Boolet"
Consts  = require "balance"
moves   = require "moves"
control = require "control"
Dude    = require "player"

you = nil
me  = nil
g = love.graphics

local fnt = nil
local hfnt = nil
--PLEASE STOP LOOKING THIS IS BAD

function makegooey(x)
	x = x or 0
	return function(self)
		g.setColor(self.idlecolor)
		g.rectangle('fill', x, 0, 30, self.hp*30)
		
		g.setColor(0,255,10)
		g.rectangle('line', x, 0, 30, Consts.health*30)
		if self.ammo > self.ammotype.cost * self.ammotype.number then
			g.setColor(0, 200, 10)
		else
			g.setColor(200, 0, 10)
		end
		g.rectangle('fill', x, 30 + Consts.health*30, 30, 30)
		
		g.setColor(255, 255, 255)
		g.setFont(fnt)
		g.print(string.format("W%d", self.wins), x, 90 + Consts.health*30)
		g.print(string.format("A%s", string.char(string.byte(self.ammotype.name))), x, 120 + Consts.health*30)
	end
end

local menu = Gamestate.new()
local gam = Gamestate.new()

function love.load()
	love.keyboard.setKeyRepeat(.150, .050)
	
	fnt = love.graphics.newFont('VeraMono.ttf', 20)
	hfnt = love.graphics.newFont('VeraMono.ttf', 50)
	console = Console.new(fnt)
	
	star = g.newImage("star.png")
	
	print("welcom to " .. Consts.vidya .. " be sure to play")
	
	defaultscheme()
	
	local all_callbacks = {
	'update', 'draw', 'focus', 'keypressed', 'keyreleased',
	'mousepressed', 'mousereleased' }
	
	Gamestate.registerEvents(all_callbacks)
	Gamestate.switch(menu)
end

function menu:update(dt)
end

local helpstr = require "helpstring"
function menu:draw()
	g.setColor(255,255,255)
	g.printf(helpstr, 25, 25, g.getWidth()-50, "center")
	if console:isfocused() then
		console:draw(love.graphics.getWidth(), love.graphics.getHeight())
	end
end

function menu:keypressed(key, uni)
	if key == '`' then
		console:focus()
		return
	end
	console:keypressed(key, uni)
end

function start()
	Gamestate.switch(gam)
end

function gam:enter()
	g.setBackgroundColor(0x33,0x54,0x10)
	justlikemakegame()
end

local leftscheme = nil
local rightscheme = nil
gamewon = false

function justlikemakegame()
	local ywin, mwin = (you or {wins = 0}).wins, (me or {wins = 0}).wins
	Boolet.reset()
	control.reset()
	gamewon = false
	
	--LEF
	you = Dude()
	you.name = "YELLOW"
	you.idlecolor = {0xFF,0x9A,0x00}
	you.movecolor = {0xFF, 0xC0,0x00}
	you.CDcolor = {0x80, 0x66, 0x40}
	you.gooey = makegooey(0)
	you.wins = ywin
	you.shoot = youshoot
	
	--RIGH
	me = Dude()
	me.name = "BLUE"
	me.x = 900
	me.y = 700
	me.idlecolor = {0x05, 0x00, 0xFF}
	me.movecolor = {0x00, 0x79, 0xFF}
	me.CDcolor = {0x40, 0x5E, 0x80}
	me.gooey = makegooey(g.getWidth()-30, -1)
	me.wins = mwin
	me.shoot = meshoot
	
	me.other = you
	you.other = me
	leftscheme (you)
	rightscheme (me)
	
	printstr = string.format("%d", Consts.initialcountdown)

	for i = 1, Consts.initialcountdown do
		Timer.add(i, function() printstr = string.format("%d", Consts.initialcountdown-i) end)
	end
	Timer.add(Consts.initialcountdown+.01, function() printstr = "GO" end)
	Timer.add(Consts.initialcountdown+1, function() printstr = "" end)

end

function defaultscheme()
	leftscheme = function(pl) control.schemes.joypad(pl, 'l', 'l', 1) end
	rightscheme = function(pl) control.schemes.joypad(pl, 'r', 'r', 1) end
	print("default scheme loaded")
end

function twocontroller()
	leftscheme = function(pl) control.schemes.joypad(pl, 'l', 'r', 1) end
	rightscheme = function(pl) control.schemes.joypad(pl, 'l', 'r', 2) end
	print("two controller scheme loaded")
end

function poorfag()
	leftscheme = function(pl) control.schemes.moose(pl) end
	rightscheme = function(pl) control.schemes.numpad(pl) end
   print("mouse/kb scheme loaded")
end

function gam:update(dt)
	XInput.update()
	control.update(dt)
	Timer.update(dt)

	you:update(dt)
	me:update(dt)
	
	Boolet.updateall(dt, me, you)
end

printstr = ""
function gam:draw()
	Boolet.drawall()
	you:draw()
	me:draw()
	
	you:gooey()
	me:gooey()
	g.setColor(255,255,255)
  	
	g.setFont(fnt) 
	g.print("FPS: "..tostring(love.timer.getFPS( )), 40, 10)
	
	g.setFont(hfnt)
	g.printf(printstr, 25, g.getHeight() / 2, g.getWidth() - 50, 'center')
	if console:isfocused() then
		console:draw(love.graphics.getWidth(), love.graphics.getHeight())
	end
end

--XInputlua only overrides the love function
function love.joystickpressed(joy, btn)
	control.joystickdo(joy, btn, false)
end

alt = false
function gam:keypressed(key, uni)
	if key == '`' then
		console:focus()
		return
	elseif key == 'f4' and love.keyboard.isDown('lalt') then
		print("YOU'RE HERE FOREVER")
		return
	end
	
	console:keypressed(key, uni)
	control.keyboarddo(key, uni)
end

function gam:mousepressed(x, y, btn)
	control.mousedo(btn)
end

local _print = print
--Handy and dandy
function print(...)
	_print(...)
	return console:print(...)
end

function clear()
	console:reset()
end

function printf(fmt, ...)
	return print(string.format(fmt, ...))
end

--Not sure why i need this, it was in the console example
--function quit()
--	love.event.push('quit')
--end
--exit = quit
