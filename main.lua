Gamestate = require "hump.gamestate"
Class = require "hump.class"
love.joystick = require('XInputLUA')
--dump = require "dump"
Vec = require "hump.vector"
Boolet = require "Boolet"


--FIXME: properly inherit for movesets instead of whatever this is
Idle = Class{
	name = "idle",
	function(self, a)
		self.priority = 0
		assert(a)
		self.a = a
	end
}

function Idle:update(dt)
	local a = self.a
	a.x = a.x + a.joyx
	a.y = a.y + a.joyy
end

function Idle:draw(c)
	local a = self.a
	-- In case it's not immediately obvious (it isn't)
	-- we're are tinting the circles to show what side they're on (rc)
	-- and we're tinting them by what state the player is in (c)
	local rc = a.color
	c = c or {100, 125, 235}
	for i,v in ipairs(rc) do
		c[i] = v * c[i]
	end
	
	g.setColor(c)
	g.circle('fill', a.x, a.y, a.w)
	g.setColor(255, 255, 255, 255) 
	local sw = a.w / 5
	g.circle('fill', a.x + a.joyx * (a.w - sw), a.y + a.joyy * (a.w - sw), sw)
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
	Idle.draw(self, {100, 100, 100})
end

Firing = Class{
	name = "firing",
	function(self, a, t)
		assert(a)
		self.t = t or .15
		self.st = .05
		self.priority = 3
		self.a = a
	end	
}

function Firing:update(dt)
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
		self.a.move = Idle(self.a)
	end
end

function Firing:draw()
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

function Roll:point2(xx, yy)
	if xx ~= 0 or yy ~= 0 then
		local v = Vec(xx, yy)
		v:normalize_inplace()
		local vx, vy = v:unpack()
		self.vx = 20 * vx
		self.vy = 20 * vy
	end
end

function Roll:update(dt)
	local a = self.a
	a.x = a.x + self.vx
	a.y = a.y + self.vy
	self.vx = self.vx * .98
	self.vy = self.vy * .95
	self.t = self.t - dt
	if self.t < dt then
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
		self.w = 50
		self.joyx = 0
		self.joyy = 0
		self.move = Idle(self)
		self.boolets = {}
		self.bnum = 0
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

function love.load()
	g = love.graphics
end


function deadzone(xaxis, yaxis, dz) 
	local v = Vec(love.joystick.getAxis(1, xaxis), -love.joystick.getAxis(1, yaxis))
	if v:len() < dz then
		return 0, 0
	else
		return v:unpack()
	end
end

function love.update(dt)
	local j = love.joystick
	
	j.update() --TODO: make xinput/directinput triggerable
	you.joyx, you.joyy = deadzone(1, 2, .2)
	me.joyx, me.joyy = deadzone(3, 4, .2)
	
	you:update(dt)
	me:update(dt)
	
	for k, v in pairs(Boolet.boolets) do
		v:update(dt)
	end
end

function love.draw()
	you:draw()
	me:draw()
	
	for k, v in pairs(Boolet.boolets) do
		v:draw()
	end
end

function love.joystickpressed(joy, btn)
	if btn == 5 then --LT
		local f = Firing(you)
		you:setmove(f)
	elseif btn == 6 then --RT
		local f = Firing(me)
		me:setmove(f)
	elseif btn == 7 then --LB
		local r = Roll(you)
		r:point2(you.joyx, you.joyy)
		if r.vx then
			you:setmove(r)
		end
	elseif btn == 8 then --RB
		local r = Roll(me)
		r:point2(me.joyx, me.joyy)
		if r.vx then
			me:setmove(r)
		end
	end
end