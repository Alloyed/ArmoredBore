local tween = require "tween"
local json = require "misc/dkjson"
local ls, rs = nil, nil
local socket = require "socket"

bgm = love.audio.newSource("snd/01 Airglow fires.mp3")
printstr = ""
timeleft = 0

function gameover(game)
	local you = game.you
	local me  = game.me
	me:setmove(moves.cooldown, 5)
	you:setmove(moves.cooldown, 5)

	game.isGameOver = true
	tween.tween_for(4, tween.range(1, .5), function(t) bgm:setPitch(t) end )
	Timer.add(4, function()
		printstr = ""
		local ss = json.encode({you = you.movebuf, me = me.movebuf})
		lfs.write("buffa.json", ss)
		print("replay logged at buffa.json")
		local addr, port = "192.241.134.64", 64083
		--local tcp, err = socket.connect(addr, port)
		--assert(tcp, err)
		--tcp:send(ss)
		--tcp:close()
		Gamestate.switch(Game(), ls, rs, you.wins, me.wins)
	end)
end

function gamelost(self)
	printstr = string.format("%s WINS", self.other.name)
	self.other.wins = self.other.wins + 1
	Signals.emit("gameover", self.game)
end

function gamedraw(game)
	printstr = "DRAW! YOU'RE ALL LOSERS"
	Signals.emit("gameover", game)
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
	if self.ammo > balance.bullet.cost * balance.bullet.number then
		lg.setColor(colors.ui)
	end
	lg.rectangle('fill', bx + (hpbar_w * dw), hpbar_h,
	                     hpbar_w * .5 * dw, self.ammo * -30 / balance.bullet.cost)
	-- HPbar outline
	lg.setLineWidth(3)
	lg.setColor(self.CDcolor)
	lg.rectangle('line', bx, 0, hpbar_w * dw, hpbar_h)
end

local Game = Class {}

function Game:enter(last, leftscheme, rightscheme, ywin, mwin)
	bgm:stop()
	bgm:setPitch(1)
	bgm:setVolume(.2)
	bgm:play()
	local ywin, mwin = ywin or 0, mwin or 0
	Boolet.reset()
	control.reset()
	Timer.clear()
	Timer.addPeriodic(.5, function()
		local fine, cl, bl = pcall(function()
			return lfs.load("colors.lua")(),
			       lfs.load("balance.lua")()
		end)
		if fine then colors, balance = cl, bl end
	end)
	self.isGameOver = false
	self.camera = Camera()

	--LEF
	local you = Dude(self)
	you.name      = "YELLOW"
	you.idlecolor = colors.you.idle
	you.movecolor = colors.you.move
	you.CDcolor   = colors.you.cooldown
	you.wins      = ywin
	you.shoot     = youshoot

	--RIGH
	local me = Dude(self)
	me.x, me.y = 900, 700
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
	self.me, self.you = me, you
	self.timeleft = 60

	do
		local count = balance.initialcountdown
		printstr = string.format("%d", count)

		for i = 1, count do
			Timer.add(i, function() printstr = string.format("%d", count-i) end)
		end
		Timer.add(count+.01, function() printstr = "GO" self.started = true end)
		Timer.add(count+  1, function() printstr = "" end)
	end

	Signals.clear("gamelost")
	Signals.register("gamelost", gamelost)

	Signals.clear("gamedraw")
	Signals.register("gamedraw", gamedraw)

	Signals.clear("gameover")
	Signals.register("gameover", gameover)
end

function Game:update(dt)
	local me, you, camera = self.me, self.you, self.camera
	if self.started then
		if self.timeleft <= 0 and not self.isGameOver then
			Signals.emit("gamedraw", self)
		end
		self.timeleft = math.max(0, self.timeleft - dt)
	end
	-- XInput.update()
	you:startupdate(dt)
	me:startupdate(dt)

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
	local me, you, camera = self.me, self.you, self.camera
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
	local timeleft = self.timeleft
	local min = math.floor(timeleft / 60)
	local sec = math.floor(timeleft) % 60
	lg.printf(string.format("%d:%d", min, sec), 25, 30, lg.getWidth() - 50, 'center')

	lg.setFont(hfnt)
	lg.printf(printstr, 25, lg.getHeight() / 2,lg.getWidth() - 50, 'center')
end

function Game:keypressed(key, uni)
	print(key)
	if key == 'f4' and love.keyboard.isDown('lalt') then
		print("YOU'RE HERE FOREVER")
		return
	elseif key == 'escape' then
		bgm:stop()
		Gamestate.switch(menu)
	end

	control.keyboarddo(key, uni)
end

function Game:mousepressed(x, y, btn)
	control.mousedo(btn)
end


return Game
