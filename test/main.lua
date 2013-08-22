local lg = love.graphics
local joypad = require "joypad"

cbaks = {}

dbgstr = "n\nn\nn\nn\nn\nn"
local function dbgprint(...)
	local str = ""
	table.foreach({...}, function(_, n) str = str .. ", " .. n end)
	dbgstr = dbgstr .. '\n' .. str
	dbgstr = string.match(dbgstr, "\n(.*)$")
end

for _, name in ipairs(joypad.callbacks) do
	cbaks[name] = dbgprint
end

function love.load()
	joypad.init()
	joypad.setCallbacks(cbaks)
	right = joypad.newStick(1, 1, 2)
	rt    = joypad.newTrigger(1, 3, .60)
	left  = joypad.newStick(1, 4, 5)
	lt    = joypad.newTrigger(1, 6, .60)
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

	for x, _ in ipairs(joypad.sticks) do
		local jx, jy = joypad.getStick(x)
		local jx, jy = jx * n / 2, jy * n / 2
		local cx, cy = x*n, n*4
		lg.circle('line', cx, cy, n * .5)
		lg.line(cx, cy, cx + jx, cy + jy)
	end

	lg.print(joypad.getHat(1, 1), n, n*5)
	local jx, jy = joypad.getHatAsStick(1, 1)
	local jx, jy = jx * n / 2, jy * n / 2
	local cx, cy = n, n*6
	lg.circle('line', cx, cy, n * .5)
	lg.line(cx, cy, cx + jx, cy + jy)

	for x, _ in ipairs(joypad.triggers) do
		local btn = joypad.getTrigger(x)
		local t = btn and 'fill' or 'line' 
		lg.rectangle(t, (x * n), n*7, n, n)
	end

	lg.print(dbgstr, 400, 400)
end
