local lg = love.graphics
local joypad = require "joypad"

function love.load()
	joypad.init()
end

function love.update(dt)
	joypad.update()
end

function love.draw()
	local n = 50
	for x, btn in joypad.getButtons(1) do
		local t = btn and 'fill' or 'line'
		lg.rectangle(t, (x * n), n, n, n)
	end
	for x, val in joypad.getAxes(1) do
		lg.rectangle('fill', (x*n), (n * 2.5), n, val * n * .5)
	end
	lg.print(joypad.getHat(1, 1), n, n*3)
end
