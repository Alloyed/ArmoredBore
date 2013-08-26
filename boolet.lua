Class = require "hump.class"
lvec = require "hump.vector-light"
Ringbuffer = require "hump.ringbuffer"

local Boolets = {}
local bnum = 0

--copies table 1 into table 2, table 2 is given precedence in conflicts
local function combo(tab1, tab2)
	for k,v in pairs(tab1) do
		if not tab2[k] then
			tab2[k] = v
		end
	end
	return tab2
end

local Explosion = Class { name = "explosion" }

function Explosion:init(bul)
	self.hsh = bul.hsh
	self.x, self.y = bul.x, bul.y

	Timer.add(1, function() Boolets[self.hsh] = nil end)
	local p = lg.newParticleSystem(star, 10)
	p:setLifetime(-1)
	p:setParticleLife(.1, .2)
	p:setEmissionRate(60 * 10)
	p:setSpeed(1,100)
	p:setPosition(self.x, self.y)
	p:start()
	self.p = p
end

function Explosion:update(dt)
	self.p:update(dt)
end

function Explosion:draw()
	--lg.draw(self.p)
end

local Boolet = Class {
	name = "bullet"
}

function Boolet:init(owner)
	assert(owner)
	self.owner = owner
	self.x = owner.x + (owner.joyx * owner.w * .75)
	self.y = owner.y + (owner.joyy * owner.w * .75)
	bnum = bnum+1
	self.hsh = string.format("b%d", bnum)
	Boolets[self.hsh] = self
	self.t = balance.bullet.decay

	local p = love.graphics.newParticleSystem(star, 256)

	p:setEmissionRate (60)
	p:setLifetime (-1)
	p:setSizes (.1)
	p:setParticleLife (.1)
	local c = self.owner.colors.idle
	p:setColors(c[1], c[2], c[3], 255)
	p:setRadialAcceleration(.1, .5)

	self.trail = p
end


function Boolet.reset()
	Boolets = {}
	bnum = 0
end

function Boolet.updateall(dt, me, you)
	for k, v in pairs(Boolets) do
		v:update(dt, me, you)
	end
end

function Boolet.drawall()
	for k, v in pairs(Boolets) do
		v:draw()
	end
end

function Boolet:point(xx, yy)
	local v = Vec(xx, yy)
	v:normalize_inplace()
	local vx, vy = v:unpack()
	local s = balance.bullet.speed
	self.vx = vx*s
	self.vy = vy*s
	self.trail:setDirection(math.atan2(xx,yy))
	self.trail:setSpeed(s, s+.1)
	self.trail:setSpread(.01)
	self.trail:stop()
	self.trail:start()
end

function Boolet:update(dt, me, you)
	self.x = self.x + self.vx
	self.y = self.y + self.vy
	if self:isTouching(me) and me ~= self.owner then
		me:hurt(balance.bullet.dmg)
		Boolets[self.hsh] = Explosion(self)
	end

	if self:isTouching(you) and you ~= self.owner then
		you:hurt(balance.bullet.dmg)
		Boolets[self.hsh] = Explosion(self)
	end

	self.t = self.t - dt
	if self.t < dt then
		Boolets[self.hsh] = nil
	end

	self.trail:update(dt)
	self.trail:setPosition(self.x, self.y)
end

function Boolet:isTouching(dude)
	assert(dude.w)
	return lvec.len2(self.x - dude.x, self.y - dude.y) <
	  (dude.w * dude.w + balance.bullet.size * balance.bullet.size)
end

function Boolet:draw()
	local rc = self.owner.colors.idle
	--lg.draw(self.trail)
	lg.setColor(rc)
	lg.circle('fill', self.x, self.y, balance.bullet.size)
end

return Boolet
