Gamestate = require "hump.gamestate"
Class = require "hump.class"
dump = require "dump"
Vec = require "hump.vector"

Idle = Class{
	name = "idle",
	function(self, a)
		self.priority = 0
		assert(a)
		self.a = a
	end
}

function Idle:update(dt) end

function Idle:draw(c)
	local a = self.a
	local rc = a.color
	c = c or {100, 125, 235}
	for i,v in ipairs(rc) do
		c[i] = v * c[i]
	end
	g.setColor(c)
	g.circle('fill', a.x, a.y, a.w)
	g.setColor(255, 255, 255, 255) --lol, i dunno
end

CD = Class{
	name = "cooldown",
	function(self, a, t)
		assert(a)
		self.t = t or .5
		self.priority = 10
		self.a = a
	end	
}

function CD:update(dt)
	self.t = self.t - dt
	if self.t <= dt then
		if self.a.rq then
			self.a.move = self.a.rq
			self.a.rq = nil
		else
			self.a.move = Idle(self.a)
		end
	end
end

function CD:draw()
	Idle.draw(self, {100, 100, 100})
end

Roll = Class{
	name = "roll",
	function(self, a, t)
		assert(a)
		self.t = t or .4
		self.priority = 5
		self.a = a
	end	
}

function Roll:point(ang)
	self.vx = 20 * math.cos(math.rad(ang))
	self.vy = 20 * math.sin(math.rad(ang))
end

function Roll:point2(xx, yy)
	if math.abs(xx) < .25 then
		xx = 0
	end
	if math.abs(yy) < .25 then
		yy = 0
	end
	if xx ~= 0 or yy ~= 0 then
		local v = Vec(xx, yy)
		v:normalize_inplace()
		local vx, vy = v:unpack()
		self.vx = 20 * vx
		self.vy = -20 * vy
	end
end

function Roll:update(dt)
	local a = self.a
	a.x = a.x + self.vx
	a.y = a.y - self.vy
	self.vx = self.vx * .98
	self.vy = self.vy * .95
	self.t = self.t - dt
	if self.t <= dt then
		a:setmove(CD(self.a, .3))
	end
end

function Roll:draw()
	Idle.draw(self, {200, 150, 180})
end

Dude = Class{
	name = "dude",
	function(self, x, y)
		self.x = x or 100
		self.y = y  or 100
		self.w = 100
		self.h = 100
		self.move = Idle(self)
	end
}

function Dude:setmove(move)
	if move.priority > self.move.priority then
		self.move = move
	else
		self.rq = move
	end
end

function Dude:update(dt)
	self.move:update(dt)
end

function Dude:draw()
	self.move:draw()
end

you = Dude()
you.name = "YOU"
you.color = {1, 1, 1}
me = Dude()
me.name = "ME "
me.color = {1, .2, .4}

function ang(u)
	local a  = {nil, 225, 270, 315, 180, nil, 0, 135, 90, 45}
	return a [u-47]
end

function you:pressed(u)
	if ang(u) then
		local r = Roll(self)
		r:point(ang(u))
		self:setmove(r)
	elseif u == uni(5) then
		self:setmove(CD(self, .1))
	elseif u == uni(0) then
	end
end

function love.load()
	g = love.graphics
end

function love.update(dt)
	you:update(dt)
	me:update(dt)
end

function love.draw()
	you:draw()
	me:draw()
end

function uni(num)
	return num+48
end

function love.keypressed(k, u)
	you:pressed(u)
end

function love.joystickpressed(joy, btn)
	local j = love.joystick
	if btn == 5 then
		local r = Roll(you)
		r:point2(j.getAxis(1, 1), j.getAxis(1, 2))
		if r.vx then
			you:setmove(r)
		end
	elseif btn == 6 then
		local r = Roll(me)
		r:point2(j.getAxis(1,5), j.getAxis(1,4))
		if r.vx then
			me:setmove(r)
		end
	end
end