
local you = nil
local me  = nil

local ls, rs = nil, nil

camera = nil

timeleft = 0

isGameOver = false

function gameover(self)
	isGameOver = true
	printstr = string.format("%s WINS", self.other.name)
	self.other.wins = self.other.wins + 1
	self:setmove(moves.cooldown, 999)
	Timer.add(4, function()
		printstr = ""
		Gamestate.switch(Game(), ls, rs)
	end)
end

-- FIXME kill me it hurts to live
function gooey(self, bx, ex)
	-- holy mama that's a lot of decls
	local dw = bx > ex and -1 or 1
	local size = 30
	local hpbar_h = balance.health * size
	local hpbar_w = size
	local hpleft = (self.hp / balance.health) * hpbar_h

	-- notches in HPbar
	lg.setLineWidth(1)
	lg.setColor(colors.fg)
	local y = 0
	while y < hpbar_h do
		lg.line(bx, y, bx + (hpbar_w*dw), y)
		y = y + hpbar_w
	end

	-- Actual HPbar
	lg.setColor(self.idlecolor)
	lg.rectangle('fill', bx, 0, hpbar_w * dw, hpleft)

	-- ammo bar
	if me.ammo > me.ammotype.cost * me.ammotype.number then
		lg.setColor(colors.ui)
	end
	lg.rectangle('fill', bx + (hpbar_w * dw), hpbar_h,
	                     hpbar_w * .5 * dw, self.ammo * -30 / self.ammotype.cost)
	-- HPbar outline
	lg.setLineWidth(3)
	lg.setColor(self.CDcolor)
	lg.rectangle('line', bx, 0, hpbar_w * dw, hpbar_h)
end

local Game = Class {}

function Game:enter(last, leftscheme, rightscheme)
	local ywin, mwin = (you or {wins = 0}).wins, (me or {wins = 0}).wins
	Boolet.reset()
	control.reset()
	Timer.clear()
	Timer.addPeriodic(.5, function() colors = lfs.load("colors.lua")() end)
	isGameOver = false

	--LEF
	you = Dude()
	you.name      = "YELLOW"
	you.idlecolor = colors.you.idle
	you.movecolor = colors.you.move
	you.CDcolor   = colors.you.cooldown
	you.wins      = ywin
	you.shoot     = youshoot

	--RIGH
	me = Dude(900, 700)
	me.name      = "BLUE"
	me.idlecolor = colors.me.idle
	me.movecolor = colors.me.move
	me.CDcolor   = colors.me.cooldown
	me.wins      = mwin
	me.shoot     = meshoot

	me.other  = you
	you.other = me
	ls, rs = leftscheme, rightscheme
	leftscheme(you)
	rightscheme(me)

	timeleft = 5 * 60

	do
		local count = balance.initialcountdown
		printstr = string.format("%d", count)

		for i = 1, count do
			Timer.add(i, function() printstr = string.format("%d", count-i) end)
		end
		Timer.add(count+.01, function() printstr = "GO" started = true end)
		Timer.add(count+  1, function() printstr = "" end)
	end
	Signals.clear("gameover")
	Signals.register("gameover", gameover)
end

function Game:update(dt)
	if started then
		timeleft = timeleft - dt
	end
	-- XInput.update()
	control.update(dt)
	Timer.update(dt)

	you:update(dt)
	me:update(dt)

	Boolet.updateall(dt, me, you)

	local x = .5 * (me.x + you.x)
	local y = .5 * (me.y + you.y)
	camera:lookAt(x, y)

	local pad = balance.margin * 2
	local zx  = lg.getWidth()  / (pad + math.abs(me.x - you.x))
	local zy  = lg.getHeight() / (pad + math.abs(me.y - you.y))
	local zum = math.min(math.min(zx, zy), 1)
	camera:zoomTo(zum)
end

printstr = ""
function Game:draw()
	lg.setBackgroundColor(colors.bg)
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
	lg.printf(string.format("%d-%d", you.wins, me.wins), 25, 10, lg.getWidth() - 50, 'center')
	local min = math.floor(timeleft / 60)
	local sec = math.floor(timeleft) % 60
	lg.printf(string.format("%d:%d", min, sec), 25, 30, lg.getWidth() - 50, 'center')

	lg.setFont(hfnt)
	lg.printf(printstr, 25, lg.getHeight() / 2,lg.getWidth() - 50, 'center')
end

--XInputlua only overrides the love function
function love.joystickpressed(joy, btn)
	-- print(joy, btn)
	control.joystickdo(joy, btn, false)
end

alt = false
function Game:keypressed(key, uni)
	if key == 'f4' and love.keyboard.isDown('lalt') then
		print("YOU'RE HERE FOREVER")
		return
	end

	control.keyboarddo(key, uni)
end

function Game:mousepressed(x, y, btn)
	control.mousedo(btn)
end


return Game
