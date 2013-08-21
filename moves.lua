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
	c = c or a.idlecolor
	local hex = polygon(SIDES)

	lg.setColor(c)
	lg.push()
	lg.translate(a.x, a.y)
	lg.scale(a.w)
	lg.polygon('fill', unpack(hex))
	lg.pop()
end

local function cdraw(self, c)
	local a = self.a
	c = c or a.idlecolor
	lg.setColor(c)

	lg.circle('fill', a.x, a.y, a.w)
end

function shapedraw(self, shape, color)
	if shape == 'poly' then
		polydraw(self, color)
	else
		cdraw(self, color)
	end
	local a = self.a

	lg.setColor(255, 255, 255, 255)
	local sw = a.w / 5
	lg.circle('fill', a.x + a.joyx * (a.w - sw), a.y + a.joyy * (a.w - sw), sw)

	lg.setColor(a.idlecolor)
	if a.cx then
		lg.setLineWidth(5)
		lg.circle('line', a.cx, a.cy, balance.dashradius)
	end
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
	-- a.x = min(max(a.x + a.joyx, 0), lg.getWidth())
	-- a.y = min(max(a.y + a.joyy, 0), lg.getHeight())
	a.x = a.x + a.joyx
	a.y = a.y + a.joyy
	a.cx = a.x
	a.cy = a.y
end

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

function CD:draw()
	shapedraw(self, 'circle', self.a.CDcolor)
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

function Firing:draw()
	shapedraw(self, 'circle', self.a.movecolor)
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
	self.getX = tween.tween_for(self.t, tween.exp(), tween.range(a.x, a.x + d.x))
	self.getY = tween.tween_for(self.t, tween.exp(), tween.range(a.y, a.y + d.y))
end

local function atkroll(me, you)
	assert(me.w, you.w)
	local w = me.w + you.w
	return lvec.len2(you.x-me.x,you.y-me.y) < (w * w)
end

local function walls(self)
	local abs = math.abs
	local a = self.a
	if a.x < self.vx then
		a.x = self.vx
		self.vx = abs(self.vx)
	end

	if a.x >= (lg.getWidth() - self.vx) then
		a.x = (lg.getWidth() - self.vx)
		self.vx = -self.vx
	end

	if a.y < self.vy then
		a.y = self.vy
		self.vy = abs(self.vy)
	end

	if a.y >= (lg.getHeight() - self.vy) then
		a.y = (lg.getHeight() - self.vy)
		self.vy = -self.vy
	end
end

function Roll:update(dt)
	local a = self.a
	if self.ded then a:popmove() return end
	--FIXME: you can walk off the screen, properly TP to a safe spot.
	-- walls(self)
	local o = a.other
	a.x = self.getX()
	a.y = self.getY()
	self.t = self.t - dt

	if self.t < dt then
		a:setmove(CD, .3)
	end
end

function Roll:draw()
	shapedraw(self, 'circle', self.a.movecolor)
end

return { idle = Idle, roll = Roll, cooldown = CD, fire = Firing }
