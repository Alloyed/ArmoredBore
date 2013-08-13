--libs/utilities
-- XInput = require('XInputLUA') --TODO: selectively disable
require "boilerplate"
local dump = require "dump"
--our own things
Boolet  = require "boolet"
balance  = require "balance"
moves   = require "moves"
control = require "control"
Dude    = require "player"

you = nil
me  = nil

local fnt = nil
local hfnt = nil

local leftscheme = nil
local rightscheme = nil

gamewon = false
-- PLEASE STOP LOOKING THIS IS BAD
-- as if the globals weren't hint enough

function makegooey(x)
	x = x or 0
	return function(self)
		local maxhp = balance.health
		lg.setColor(self.idlecolor)
		lg.rectangle('fill', x, 0, 30, self.hp*30)

		lg.setColor(0,255,10)
		lg.rectangle('line', x, 0, 30, maxhp*30)
		if self.ammo > self.ammotype.cost * self.ammotype.number then
			lg.setColor(0, 200, 10)
		else
			lg.setColor(200, 0, 10)
		end
		lg.rectangle('fill', x, 30 + maxhp*30, 30, 30)

		lg.setColor(255, 255, 255)
		lg.setFont(fnt)
		lg.print(string.format("W%d", self.wins), x, 90 + maxhp*30)
		lg.print(string.format("A%s", string.char(string.byte(self.ammotype.name))), x, 120 + maxhp*30)
	end
end

local menu = {}
local game = {}

function love.load()
	love.keyboard.setKeyRepeat(.150, .050)

	fnt = lg.newFont('VeraMono.ttf', 20)
	hfnt = lg.newFont('VeraMono.ttf', 50)

	star = lg.newImage("star.png")

	local all_callbacks = {
	'update', 'draw', 'focus', 'keypressed', 'keyreleased',
	'mousepressed', 'mousereleased' }

	Gamestate.registerEvents(all_callbacks)
	Gamestate.switch(menu)
end

schemes = {}

for i=1, ljoy.getNumJoysticks() do
	table.insert(schemes, function()
		return function(pl)
				return control.schemes.joypad(pl, 'l', 'l', i)
		end, "Controller " .. i .. "(left)"
	end)
	table.insert(schemes, function()
		return function(pl)
			return control.schemes.joypad(pl, 'r', 'r', i)
 		end, "Controller " .. i .. "(right)"
	end)
	table.insert(schemes, function(pl)
		return function()
			return control.schemes.joypad(pl, 'l', 'r', i)
		end, "Controller " .. i .. "(full)"
	end)
end

table.insert(schemes, function()
	return control.schemes.moose, "Mouse (lel)"
end)

table.insert(schemes, function()
	return control.schemes.numpad, "Keyboard (fag)"
end)


local mindex = 1
local mtext  = {"Start game", "whoops", "whoops", "Options", "Quit"}
local mfn    = { function() start() end,
                 function() selectA() end,
					  function() selectB() end,
                 function() end, -- FIXME: stub, options menu goes here
                 function() love.event.push('quit') end }

-- {{{ Menu
local Aind, Bind = 0, 1
function selectA()
	Aind = (Aind % #schemes) + 1
	local tmp, n = schemes[Aind]()
	leftscheme = tmp
	print(leftscheme)
	mtext[2] = "Player1 : " .. n
end

function selectB()
	Bind = (Bind % #schemes) + 1
	local tmp, n = schemes[Bind]()
	rightscheme = tmp
	mtext[3] = "Player2 : " .. n
end

function menu:enter()
	mindex = 1
	selectA()
	selectB()
end

function menu:update(dt)
end

function menu:draw()
	for i, text in ipairs(mtext) do
		lg.print(text, 10, 100 + i * 20)
	end
	lg.print("A", 1, 100 + mindex * 20)
end

function menu:keypressed(key, uni)
	if key == 'down' then
		mindex = (mindex % #mtext) + 1
	elseif key == 'up' then
		-- TODO: you might notice this is dumb
		mindex = (mindex - 2 % #mtext) + 1
		mindex = (mindex - 2 % #mtext) + 1
		mindex = (mindex % #mtext) + 1
	elseif key == 'return' then
		mfn[mindex]()
	end
end
-- }}}

function start()
	Gamestate.switch(game)
end

function game:enter()
	lg.setBackgroundColor(0x33,0x54,0x10)
	justlikemakegame()
end



function justlikemakegame()
	local ywin, mwin = (you or {wins = 0}).wins, (me or {wins = 0}).wins
	Boolet.reset()
	control.reset()
	gamewon = false

	--LEF
	you = Dude()
	you.name      = "YELLOW"
	you.idlecolor = {0xFF,0x9A,0x00}
	you.movecolor = {0xFF, 0xC0,0x00}
	you.CDcolor   = {0x80, 0x66, 0x40}
	you.gooey     = makegooey(0)
	you.wins      = ywin
	you.shoot     = youshoot

	--RIGH
	me = Dude()
	me.name      = "BLUE"
	me.x         = 900
	me.y         = 700
	me.idlecolor = {0x05, 0x00, 0xFF}
	me.movecolor = {0x00, 0x79, 0xFF}
	me.CDcolor   = {0x40, 0x5E, 0x80}
	me.gooey     = makegooey(lg.getWidth()-30, -1)
	me.wins      = mwin
	me.shoot     = meshoot

	me.other  = you
	you.other = me
	leftscheme(you)
	rightscheme(me)

	do
		local count = balance.initialcountdown
		printstr = string.format("%d", count)

		for i = 1, count do
			Timer.add(i, function() printstr = string.format("%d", count-i) end)
		end
		Timer.add(count+.01, function() printstr = "GO" end)
		Timer.add(count+  1, function() printstr = "" end)
	end
end

function game:update(dt)
	-- XInput.update()
	control.update(dt)
	Timer.update(dt)

	you:update(dt)
	me:update(dt)

	Boolet.updateall(dt, me, you)
end

printstr = ""
function game:draw()
	Boolet.drawall()
	you:draw()
	me:draw()

	you:gooey()
	me:gooey()
	lg.setColor(255,255,255)

	lg.setFont(fnt)
	lg.print("FPS: "..tostring(love.timer.getFPS( )), 40, 10)

	lg.setFont(hfnt)
	lg.printf(printstr, 25,lg.getHeight() / 2,lg.getWidth() - 50, 'center')
end

--XInputlua only overrides the love function
function love.joystickpressed(joy, btn)
	print(joy, btn)
	control.joystickdo(joy, btn, false)
end

alt = false
function game:keypressed(key, uni)
	if key == 'f4' and love.keyboard.isDown('lalt') then
		print("YOU'RE HERE FOREVER")
		return
	end

	control.keyboarddo(key, uni)
end

function game:mousepressed(x, y, btn)
	control.mousedo(btn)
end

function printf(fmt, ...)
	return print(string.format(fmt, ...))
end
