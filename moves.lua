-- shared defs
local tween = require "tween"
SIDES = 6 -- FIXME: balance.lua-ify

local function polygon(N)
	local t = {}
	local twopi = math.pi * 2
	for i=1,N do
		table.insert(t, math.cos(twopi * i / N))
		table.insert(t, math.sin(twopi * i / N))
	end
	return t
end

local function polydraw(self, c)
	local a = self.a
	c = c or a.colors.idle
	local hex = polygon(SIDES)

	lg.setColor(c)
	lg.push()
	lg.translate(a.x, a.y)
	lg.scale(a.w)
	lg.polygon('fill', unpack(hex))
	lg.pop()
end

local function cdraw(self, c, seg)
	local a = self.a
	c = c or a.colors.idle
	lg.setLineWidth(8)
	lg.setLineStyle('smooth')

	lg.setColor(c[1], c[2], c[3], 70)
	lg.circle('fill', a.x, a.y, a.w, seg)
	lg.setColor(c)
	lg.circle('line', a.x, a.y, a.w, seg)
end

function predraw(self)
	local a = self.a
	local c = a.colors.idle
	if a.cx then
		lg.setLineWidth(2)
		lg.setLineStyle('smooth')
		lg.setColor(c[1], c[2], c[3], 15)
		lg.circle('fill', a.cx, a.cy, balance.dashradius, a.segments * 1.5)
		lg.setColor(c)
		lg.circle('line', a.cx, a.cy, balance.dashradius, a.segments * 1.5)
	end
end

function shapedraw(self, color)
	lg.setLineWidth(5)
	local a = self.a

	local seg = a.segments
	cdraw(self, color, seg)

	if math.abs(a.joyx) < .01 and math.abs(a.joyy) < .01 then
		lg.setColor(a.colors.noncenter)
	else
		lg.setColor(a.colors.center)
	end

	local sw = (a.w / 4)
	local sx = a.x + (a.joyx * (a.w * .75))
	local sy = a.y + (a.joyy * (a.w * .75))
	lg.setStencil(function ()
		lg.setLineWidth(15)
		lg.circle('line', a.x, a.y, a.w, seg)
	end)
	lg.circle('fill', sx, sy, sw, seg)

	lg.setLineWidth(5)
	lg.setStencil(function () lg.circle('fill', a.x, a.y, a.w, seg) end)
	lg.circle('line', sx, sy, sw, seg)
	lg.setStencil()
end

local Idle = Class {
	name = "idle", priority = 0,
	function(self, a)
		assert(a)
		self.a = a
	end
}

function Idle:update(dt)
	local a = self.a
	local min, max = math.min, math.max
	-- FIXME: proper wall clamping
	local x0, y0, x1, y1 = unpack(balance.room)
	a.x = min(max(a.x + a.joyx, x0 + a.w), x1 - a.w)
	a.y = min(max(a.y + a.joyy, y0 + a.w), y1 - a.w)
	--a.x = a.x + a.joyx
	--a.y = a.y + a.joyy
	a.cx = a.x
	a.cy = a.y
end

Idle.predraw = predraw

function Idle:draw()
	shapedraw(self)
end

local CD = Class {name = "cooldown", priority = 10}

function CD:init(a, t)
	assert(a)
	self.t = t or .5
	self.a = a
	self.timer = Timer.add(self.t, function()
		-- This function will trigger even after 
		-- the cooldown move would have been GC'd in the old method soooo
		if not (a.move == self) then return end
		a:popmove()
	end)
end

function CD:update(dt)
	self.a.cx, self.a.cy = self.a.x, self.a.y
end

CD.predraw = predraw

function CD:draw()
	shapedraw(self, self.a.colors.cooldown)
end

function CD:dispose()
	Timer.cancel(self.timer)
end

local Firing = Class { name = "firing", priority = 3}

function Firing:init(a, t)
	assert(a)
	local atype = balance.bullet
	self.t  = atype.rate * atype.number
	self.st = atype.rate
	self.a = a
	self.beep = nil
end

function Firing:update(dt)

	self.t = self.t - dt
	self.st = self.st - dt

	local me = self.a
	local you = self.a.other
	local atype = balance.bullet

	if self.st < dt then
		if me.ammo > atype.cost then
			local snd = love.audio.newSource("snd/me.wav")
			snd:play()
			me.ammo = me.ammo - atype.cost
			local b = Boolet(self.a)
			-- TODO: proper targeting
			b:point(you.x - me.x, you.y - me.y)
		end
		self.st = atype.rate
	end

	if self.t < dt then
		self.a:setmove(CD, balance.fireCD)
	end
end

Firing.predraw = predraw

function Firing:draw()
	shapedraw(self, self.a.colors.move)
end

local Roll = Class { name = "roll", priority = 5 }

function point2(self, xx, yy)
	if xx ~= 0 or yy ~= 0 then
		local v = Vec(xx, yy):normalize_inplace()
		self.vx = (balance.dashradius / self.t) * v.x
		self.vy = (balance.dashradius / self.t) * v.y
	end
end

function Roll:init(a, joyx, joyy)
	assert(a)
	self.t = t or .4
	self.a = a
	if joyx == 0 and joyy == 0 then self.ded = true return end
	local d = Vec(joyx, joyy):normalized() * balance.dashradius
	self.vx, self.vy = (d * (1/self.t)):unpack()
	--self.getX = tween.tween_for(self.t, tween.pow(1), tween.range(a.x, a.x + d.x))
	--self.getY = tween.tween_for(self.t, tween.pow(1), tween.range(a.y, a.y + d.y))
	self.buzz = love.audio.newSource('snd/dash.wav')
	self.buzz:play()
end

local function atkroll(me, you)
	assert(me.w, you.w)
	local w = me.w + you.w
	return lvec.len2(you.x-me.x,you.y-me.y) < (w * w)
end

local function walls(self, dt)
	local x0, y0, x1, y1 = unpack(balance.room)
	local abs = math.abs
	local a = self.a
	local w = a.w
	local vx , vy = self.vx * dt, self.vy * dt

	if a.x < x0 + vx + w then
		a.x = x0 + vx + w
		self.vx = abs(self.vx)
	end

	if a.x >= x1 - vx - w then
		a.x = x1 - vx - w
		self.vx = -abs(self.vx)
	end

	if a.y < y0 + vy + w then
		a.y = y0 + vy + w
		self.vy = abs(self.vy)
	end

	if a.y >= (y1 - vy - w) then
		a.y = (y1 - vy - w)
		self.vy = -abs(self.vy)
	end
end

function Roll:update(dt)
	local a = self.a
	if self.ded then a:popmove() return end
	--FIXME: you can walk off the screen, properly TP to a safe spot.
	walls(self, dt)
	local o = a.other
	a.x = a.x + self.vx * dt
	a.y = a.y + self.vy * dt
	--a.x = self.getX()
	--a.y = self.getY()
	self.t = self.t - dt

	if self.t < dt then
		a:setmove(CD, .2)
	end
end

Roll.predraw = predraw

function Roll:draw()
	shapedraw(self, self.a.colors.move)
end

function Roll:dispose()
	self.buzz:stop()
	--print("dis")
end

return { idle = Idle, roll = Roll, cooldown = CD, fire = Firing }
