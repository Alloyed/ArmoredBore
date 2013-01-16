--FIXME: properly inherit for movesets instead of whatever this is

local Idle = Class{
	name = "idle",
	function(self, a)
		self.priority = 0
		assert(a)
		self.a = a
	end
}

function Idle:update(dt)
	local a = self.a
	local min, max = math.min, math.max
	a.x = min(max(a.x + a.joyx, 0), g.getWidth())
	a.y = min(max(a.y + a.joyy, 0), g.getHeight())
	
end

function Idle:draw(c)
	local a = self.a
	c = c or a.idlecolor
	
	g.setColor(c)
	g.circle('fill', a.x, a.y, a.w)
	g.setColor(255, 255, 255, 255) 
	local sw = a.w / 5
	g.circle('fill', a.x + a.joyx * (a.w - sw), a.y + a.joyy * (a.w - sw), sw)
end

local CD = Class{
	name = "cooldown",
	function(self, a, t)
		assert(a)
		self.t = t or .5
		self.priority = 10
		self.a = a
		if (self.t == 0) then
			self = Idle(a)
		end
	end	
}

function CD:update(dt)
	self.t = self.t - dt
	if self.t < dt then
		if self.a.rq then
			self.a.move = self.a.rq
			self.a.rq = nil
		else
			self.a.move = Idle(self.a)
		end
	end
end

function CD:draw()
	Idle.draw(self, self.a.CDcolor)
end

local Firing = Class{
	name = "firing",
	function(self, a, t)
		assert(a)
		self.t = t or .15
		self.st = .05
		self.priority = 3
		self.a = a
		self.beep = nil
	end	
}

function Firing:update(dt)
	if not self.beep then
		self.beep = true
		love.audio.stop(self.a.shoot)
		love.audio.play(self.a.shoot)
	end
	self.t = self.t - dt
	self.st = self.st - dt
	if self.st < dt then
		local b = Boolet(self.a)
		--TODO: proper targeting
		if me == self.a then
			b:point(you.x - me.x, you.y - me.y)
		else
			b:point(me.x - you.x, me.y - you.y)
		end
		self.st = .05
	end
	
	if self.t < dt then
		self.a.move = CD(self.a, Consts.fireCD)
	end
end

function Firing:draw()
	Idle.draw(self, self.a.movecolor)
end

local Roll = Class{
	name = "roll",
	function(self, a, t)
		assert(a)
		self.t = t or .4
		self.priority = 5
		self.a = a
	end	
}

function Roll:point2(xx, yy)
	if xx ~= 0 or yy ~= 0 then
		local v = Vec(xx, yy)
		v:normalize_inplace()
		local vx, vy = v:unpack()
		self.vx = Consts.dashspeed * vx
		self.vy = Consts.dashspeed * vy
	end
end

local function atkroll(me, you)
	assert(me.w, you.w)
	local w = me.w + you.w
	return lvec.len2(you.x-me.x,you.y-me.y) < (w * w) 
end
	
function Roll:update(dt)
	local a = self.a
	--FIXME: you can walk off the screen, properly TP to a safe spot.
	if a.x <= self.vx or a.x >= (g.getWidth() - self.vx) then
		self.vx = -self.vx
		a.x = a.x + self.vx + self.vx
	end
	
	if a.y <= self.vy or a.y >= (g.getHeight() - self.vy) then
		self.vy = -self.vy
		a.y = a.y + self.vy + self.vy
	end
	
	if atkroll(a, a.other) and not ataked then
		a.other:hurt(rolldmg)
		self.ataked = true
	end
	
	a.x = a.x + self.vx
	a.y = a.y + self.vy
	--self.vx = self.vx * .98
	--self.vy = self.vy * .95
	self.t = self.t - dt
	
	if self.t < dt then
		a:setmove(CD(self.a, .3))
	end
end

function Roll:draw()
	Idle.draw(self, self.a.movecolor)
end

return { idle = Idle, roll = Roll, cooldown = CD, fire = Firing }