--libs/utilities
-- XInput = require('XInputLUA') --TODO: selectively disable
require "boilerplate"
local dump = require "dump"
--our own things
balance = require "balance"
colors  = require "colors"
Boolet  = require "boolet"
moves   = require "moves"
control = require "control"
Dude    = require "player"
Game    = require "game"

minfnt = nil
fnt    = nil
hfnt   = nil

local leftscheme = nil
local rightscheme = nil

gamewon = false
--- XXX PLEASE STOP LOOKING THIS ENTIRE FILE IS BAD XXX
-- as if the globals weren't hint enough

menu = {}

function love.load()
	love.keyboard.setKeyRepeat(.150, .050)

	minfnt = lg.newFont('VeraMono.ttf', 15)
	fnt    = lg.newFont('VeraMono.ttf', 20)
	hfnt   = lg.newFont('VeraMono.ttf', 50)

	star = lg.newImage("star.png")

	local all_callbacks = {
	'update', 'draw', 'focus', 'keypressed', 'keyreleased',
	'mousepressed', 'mousereleased' }

	Gamestate.registerEvents(all_callbacks)
	Gamestate.switch(menu)
end

--XInputlua only overrides the love function
--function love.joystickpressed(joy, btn)
	-- print(joy, btn)
--	control.joystickdo(joy, btn, false)
--end

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
	return function(pl)
		return control.schemes.replay(pl, "you")
	end, "Replay as Player 1"
end)

table.insert(schemes, function()
	return function(pl)
		return control.schemes.replay(pl, "me")
	end, "Replay as Player 2"
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
	lg.setBackgroundColor(0, 0, 0)
	lg.setColor(255, 255, 255)
	lg.setFont(minfnt)
	for i, text in ipairs(mtext) do
		lg.print(text, 10, 100 + i * 20)
	end
	lg.print(">", 1, 100 + mindex * 20)
	lg.print(">byzanz", 450, 400)
	local y = 0
	for _, c in pairs(colors.me) do
		lg.setColor(c)
		lg.rectangle('fill', 400, 400 + y, 10, 10)
		y = y + 10
	end

	for _, c in pairs(colors.you) do
		lg.setColor(c)
		lg.rectangle('fill', 400, 400 + y, 10, 10)
		y = y + 10
	end

	lg.setColor(colors.ui)
	lg.rectangle('fill', 400, 400 + y, 10, 10)
	y = y + 10
	lg.setColor(colors.bg)
	lg.rectangle('fill', 400, 400 + y, 10, 10)
end
-- }}}

function start()
	Gamestate.switch(Game(), leftscheme, rightscheme)
end

function printf(fmt, ...)
	return print(string.format(fmt, ...))
end
