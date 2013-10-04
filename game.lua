local tween  = require "tween"
local json   = require "misc/dkjson"
local ls, rs = nil, nil
local lube   = require "lube"

bgm          = love.audio.newSource("snd/bgm.mp3")
printstr     = ""
-- timeleft  = 0

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
		if config.phoneHome then
			lfs.write("buffa.json", ss)
			print("replay logged at buffa.json")
			local addr, port = "192.241.134.64", 64083
			local tcp, err = socket.connect(addr, port)
			assert(tcp, err)
			tcp:send(ss)
			tcp:close()
		end
		Gamestate.switch(Game(ls, rs, you.wins, me.wins))
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

	-- HPbar bg
	lg.setColor(self.colors.cooldown)
	lg.rectangle('fill', bx, 0, hpbar_w * dw, hpbar_h)

	-- Actual HPbar
	lg.setColor(self.colors.idle)
	lg.rectangle('fill', bx, 0, hpbar_w * dw, hpleft)

	-- notches in HPbar
	lg.setLineWidth(1)
	lg.setColor(self.colors.move)
	local y = 0
	while y < hpbar_h do
		lg.line(bx, y, bx + (hpbar_w*dw), y)
		y = y + hpbar_w
	end

	-- ammo bar
	if self.ammo > balance.bullet.cost * balance.bullet.number then
		lg.setColor(colors.ui)
	end
	lg.rectangle('fill', bx + (hpbar_w * dw), hpbar_h,
	                     hpbar_w * .5 * dw, self.ammo * -30 / balance.bullet.cost)
	-- HPbar outline
	lg.setLineWidth(3)
	lg.setColor(self.colors.cooldown)
	lg.rectangle('line', bx, 0, hpbar_w * dw, hpbar_h)
end

local Game = Class {}

function Game:init(leftscheme, rightscheme, ywin, mwin)
	local ywin, mwin = ywin or 0, mwin or 0

	-- don't do anything if we've already been constructed
	if self.camera then return end

	bgm:stop()
	bgm:setPitch(1)
	bgm:setVolume(.25)
	bgm:play()

	Timer.clear()
	-- Debug hotloader.
	Timer.addPeriodic(.5, function()
		local fine, cl, bl = pcall(function()
			lfs.load("scratch.lua") ()
			return lfs.load("colors.lua") (),
			       lfs.load("balance.lua")()
		end)
		if fine then colors, balance = cl, bl end
	end)

	Powerup.instance = nil
	Boolet.reset()
	control.reset()
	self.camera = Camera()
	if config.bloom then
		require "bloom"
		local xx, yy = .5 * lg.getWidth(), .5 * lg.getHeight()
		self.bloom = CreateBloomEffect(xx, yy)
	end

	-- Players {{{
	local w, h = balance.room[3]*.5, balance.room[4]*.5
	--LEF
	local you = Shotgonner(self)
	you.name      = "YELLOW"
	you.x, you.y  = w - 400, h - 400
	you.colors    = colors.you
	you.wins      = ywin
	you.shoot     = youshoot

	--RIGH
	local me = Shotgonner(self)
	me.x, me.y   = w + 400, h + 400
	me.name      = "BLUE"
	me.colors    = colors.me -- lel
	me.wins      = mwin
	me.shoot     = meshoot

	me.other  = you
	you.other = me
	ls, rs = leftscheme, rightscheme
	leftscheme(you)
	rightscheme(me)
	self.me, self.you = me, you
	self.timeleft = balance.roundtime
	-- }}}

	-- Countdown {{{
	do
		local count = balance.initialcountdown
		printstr = string.format("%d", count)
		local cdsnd, gosnd =
			love.audio.newSource "snd/cd.wav", love.audio.newSource "snd/go.wav"
		cdsnd:play()
		for i = 1, count - 1 do
			Timer.add(i, function()
				printstr = string.format("%d", count-i)
				cdsnd:stop()
				cdsnd:play()
			end)
		end

		Timer.add(count-1, function()
				Powerup.reset(self, MaxAmmo)
		end)

		Timer.add(count, function()
			printstr = "GO"
			self.started = true
			gosnd:play()
		end)

		Timer.add(count + 1, function()
			printstr = ""
		end)
	end
	-- }}}

	self.isGameOver = false

	Signals.clear("gamelost")
	Signals.register("gamelost", gamelost)

	Signals.clear("gamedraw")
	Signals.register("gamedraw", gamedraw)

	Signals.clear("gameover")
	Signals.register("gameover", gameover)
end

function Game:enter(last)
end

function Game:update(dt)
	control.poll(dt)

	control.apply(self.me)
	control.apply(self.you)

	self:tick(dt)
end

function Game:tick(dt)
	--ProFi:start()
	local me, you, camera = self.me, self.you, self.camera
	-- Round timer
	if self.started then
		if self.timeleft <= 0 and not self.isGameOver then
			Signals.emit("gamedraw", self)
		end
		self.timeleft = math.max(0, self.timeleft - dt)
	end
	-- Camera
	local x = .5 * (me.x + you.x)
	local y = .5 * (me.y + you.y)
	camera:lookAt(x, y)

	local pad = balance.margin * 2
	local zx  = lg.getWidth()  / (pad + math.abs(me.x - you.x))
	local zy  = lg.getHeight() / (pad + math.abs(me.y - you.y))
	local zum = math.min(math.min(zx, zy), 1)
	camera:zoomTo(zum)

	you:startupdate(dt)
	me:startupdate(dt)

	Timer.update(dt)

	you:update(dt)
	me:update(dt)

	Boolet.updateall(dt, me, you)
	Powerup.updateall(dt)
	--ProFi:stop()
end

local bgimg = lg.newImage("check.png")
bgimg:setWrap("repeat", "repeat")
bgimg:setFilter('nearest', 'nearest')
--[[
local stripe = lg.newImage("strip.png")
stripe:setWrap("repeat", "repeat")
stripe:setFilter('nearest', 'nearest')
-]]
function bg(camera, back, fore, tl)
	local sq = 256
	local bx, by = camera:worldCoords(0, 0)
	local ex, ey = camera:worldCoords(lg.getMode())
	local dx, dy = ex - bx, ey - by
	local q  = lg.newQuad(bx, by, dx, dy, 256, 256)
	local pq = lg.newQuad((tl * 256), 0, dx, dy, 512, 512)
	lg.setColor(fore)

	lg.setColorMode('modulate')
	local x0, y0, x1, y1 = unpack(balance.room)
	lg.setStencil(function()
		lg.rectangle('fill', x0, y0, x1 - x0, y1 - y0)
	end)

	lg.setColor(fore)
	lg.drawq(bgimg, q, bx, by)
	lg.setStencil()
	lg.setColor(colors.ui)
	lg.rectangle('line', x0, y0, x1-x0, y1-y0)
end

printstr = ""
function Game:draw()
	local me, you, camera, bloom = self.me, self.you, self.camera, self.bloom
	if config.bloom then
		bloom:predraw()
	end

	lg.setBackgroundColor(colors.bg)
	local function draw()
		camera:attach()
		bg(camera, colors.bg, colors.bg2, self.timeleft)
		you:predraw()
		me:predraw()
		Boolet.drawall()
		Powerup.drawall()
		you:draw()
		me:draw()
		camera:detach()
	end

	draw()
	if config.bloom then
		bloom:enabledrawtobloom()
		draw()
		bloom:postdraw()
	end

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
	lg.printf(string.format("%02d:%02d", min, sec), 25, 30, lg.getWidth() - 50, 'center')

	lg.setFont(hfnt)
	lg.printf(printstr, 25, lg.getHeight() / 2,lg.getWidth() - 50, 'center')
end

sc = 1
function Game:keypressed(key, uni)
	if key == 'f4' and love.keyboard.isDown('lalt') then
		print("YOU'RE HERE FOREVER")
		return
	elseif key == 'escape' then
		bgm:stop()
		Gamestate.switch(Pause())
	end

	control.keyboarddo(key, uni)
end

function Game:mousepressed(x, y, btn)
	control.mousedo(btn)
end


return Game
