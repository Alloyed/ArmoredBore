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

camera = nil

local fnt = nil
local hfnt = nil

local leftscheme = nil
local rightscheme = nil

gamewon = false
--- XXX PLEASE STOP LOOKING THIS ENTIRE FILE IS BAD XXX
-- as if the globals weren't hint enough

function gooey(self, bx, ex)
	local dw = bx > ex and -1 or 1
	-- HP bar
	local size = 30
	local hpbar_h = balance.health * size
	local hpbar_w = size
	local hpleft = (self.hp / balance.health) * hpbar_h

	lg.setColor(self.idlecolor)
	lg.rectangle('fill', bx, 0, hpbar_w * dw, hpleft)

	lg.rectangle('fill', hpbar_w, hpbar_h, hpbar_w * .5, me.ammo * -30 / me.ammotype.cost)

	lg.setColor(0,255,10)
	lg.rectangle('line', bx, 0, hpbar_w * dw, hpbar_h)

	if me.ammo > me.ammotype.cost * me.ammotype.number then
		lg.setColor(0, 200, 10)
	else
		lg.setColor(200, 0, 10)
	end
	lg.rectangle('fill', bx, 30 + hpbar_h, 30, 30)

	lg.setColor(255, 255, 255)
	lg.setFont(fnt)
	-- lg.print(me.wins .. "", ex, 0)
	-- lg.print(string.format("A%s", string.char(string.byte(me.ammotype.name))), x, 120 + hpbar_h)
end

local menu = {}
local game = {}

function love.load()
	camera = Camera()

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
	return control.schemes.what, "AI"
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

do
-- FIXME: imperative ugliness
local t = .25
local function add(dt)
	t = t + dt
end

local function up()
		-- TODO: you might notice this is dumb
		mindex = (mindex - 2 % #mtext) + 1
		mindex = (mindex - 2 % #mtext) + 1
		mindex = (mindex % #mtext) + 1
end

local function down()
		mindex = (mindex % #mtext) + 1
end

function menu:update(dt)
	local hat = ljoy.getHat(1, 1)
	if (string.match(hat, 'd')) then
		add(dt)
		if t > .25 then
			t = t - .25
			down()
		end
	elseif (string.match(hat, 'u')) then
		add(dt)
		if t > .25 then
			t = t - .25
			up()
		end
	else
		t = .25
	end
end

function menu:keypressed(key, uni)
	if key == 'down' then
		down()
	elseif key == 'up' then
		up()
	elseif key == 'return' then
		mfn[mindex]()
	end
end

end

function menu:draw()
	for i, text in ipairs(mtext) do
		lg.print(text, 10, 100 + i * 20)
	end
	lg.print("A", 1, 100 + mindex * 20)
	lg.print(ljoy.getHat(1, 1), 500, 500)
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
	you.wins      = ywin
	you.shoot     = youshoot

	--RIGH
	me = Dude(900, 700)
	me.name      = "BLUE"
	me.idlecolor = {0x05, 0x00, 0xFF}
	me.movecolor = {0x00, 0x79, 0xFF}
	me.CDcolor   = {0x40, 0x5E, 0x80}
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

	local x = .5 * (me.x + you.x)
	local y = .5 * (me.y + you.y)
	camera:lookAt(x, y)

	local pad = 250
	local zx  = lg.getWidth()  / (me.x + pad - you.x)
	local zy  = lg.getHeight() / (me.y + pad - you.y)
	camera:zoomTo(math.min(zx, zy))
end

printstr = ""
function game:draw()
	camera:attach()
	Boolet.drawall()
	you:draw()
	me:draw()
	camera:detach()

	local hw = lg.getWidth() * .5
	gooey(you, 0, hw)
	gooey(me, hw * 2, hw)
	lg.setColor(255,255,255)

	lg.setFont(fnt)
	lg.print("FPS: "..tostring(love.timer.getFPS( )), 40, 10)

	lg.setFont(hfnt)
	lg.printf(printstr, 25, lg.getHeight() / 2,lg.getWidth() - 50, 'center')
end

--XInputlua only overrides the love function
function love.joystickpressed(joy, btn)
	-- print(joy, btn)
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
