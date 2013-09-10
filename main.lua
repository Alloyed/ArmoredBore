--libs/utilities
--[[
local ren = require "misc.renoise"
ren.load()

local tab = {}
tab['snd/bgm.mp3']  = {16, -1}
tab['snd/beep.wav'] = {2, 2}
tab['snd/me.wav']   = {0, 0}
tab['snd/you.wav']  = {1, 1}
tab['snd/dash.wav'] = {3, 3}
tab['snd/cd.wav']   = {4, 4}
tab['snd/go.wav']   = {5, 4}
ren.sounds(tab)
love.audio = ren
--]]

require "boilerplate"
local dump = require "dump"
local qu   = require "Quickie"
--our own things
balance         = require "balance"
colors          = require "colors"
Boolet          = require "boolet"
Powerup         = require "powerup"
moves           = require "moves"
control         = require "control"
Dude            = require "player"
Shotgonner      = require "shotgun"
Game            = require "game"
CharacterSelect = require "charselect"

minfnt = nil
fnt    = nil
hfnt   = nil

local leftscheme = nil
local rightscheme = nil

LEADER  = true
BLOOM   = false
gamewon = false


--- XXX PLEASE STOP LOOKING THIS ENTIRE FILE IS BAD XXX
-- as if the globals weren't hint enough

menu = {}

function love.load()
	love.keyboard.setKeyRepeat(.150, .050)

	minfnt = lg.newFont('font/Sansation_Regular.ttf', 15)
	fnt    = lg.newFont('font/Sansation_Regular.ttf', 20)
	hfnt   = lg.newFont('font/Sansation_Bold.ttf', 45)

	local all_callbacks = {
	'update', 'draw', 'focus', 'keypressed', 'keyreleased',
	'mousepressed', 'mousereleased' }

	Gamestate.registerEvents(all_callbacks)
	Gamestate.switch(menu)
end


local mindex = 1
local mtext  = {"Start game", "LDR", "BLOOM", "Quit"}
local mfn    = { function() start() end,
                 function() leaderboards() end,
					  function() setBloom() end,
                 function() love.event.push('quit') end }

-- {{{ Menu
function leaderboards()
	LEADER = not LEADER
	mtext[2] = "Send to leaderboards: " .. (LEADER and "on" or "off")
end

function setBloom()
	BLOOM = not BLOOM
	mtext[3] = "use Bloom: " .. (BLOOM and "on" or "off")
end

function menu:enter()
	mindex = 1
	leaderboards()
	setBloom()
end

function menu:update(dt)
	qu.group.push {grow = 'down', pos = {10, 10}, size = {800, 040}, align = 'center'}
		for i, txt in ipairs(mtext) do
			if qu.Button{text = txt, size = {'tight'}} then
				mfn[i]()
			end
		end
	qu.group.pop {}
end

function menu:keypressed(key, uni)
	qu.keyboard.pressed(key, uni)
end

cc = [[
Suck my dick I'm a shark
I don't even need a massive controls list anymore :D
]]
function menu:draw()
	lg.setBackgroundColor(0, 0, 0)
	lg.setColor(255, 255, 255)
	lg.setFont(minfnt)
	qu.core.draw()
	lg.print(cc, 200, 10)
end
-- }}}

function start()
	Gamestate.switch(CharacterSelect())
end

function printf(fmt, ...)
	return print(string.format(fmt, ...))
end
