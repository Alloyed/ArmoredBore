Class = require "hump.class"
lvec = require "hump.vector-light"
Ringbuffer = require "hump.ringbuffer"
Consts = require "balance"

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

local types = {
	default = {
		name = "rapidfire",
		speed = Consts.bullet.speed,
		cost = Consts.bullet.cost,
		dmg = Consts.bullet.dmg,
		size = 5,
		decay = 2,
		rate = Consts.bullet.rate,
		number = 3
	},

	bomb = {
		name = "bomb",
		number = 1,
		cost = Consts.bullet.cost * 3,
		dmg = Consts.bullet.dmg * 3,
		size = 100,
		speed = 0,
		decay = 10,
		draw = function(self)
			local rc = self.owner.CDcolor
			lg.setColor(rc)
			lg.circle('fill', self.x, self.y, self.btype.size)
		end
	}
}
--NOTE: you have to do this for every type, deal /w it nerd
combo(types.default, types.bomb)

local Boolet = Class {
	name = "bullet",
	function(self, owner, btype)
		assert(owner)
		self.owner = owner
		self.btype = btype or owner.ammotype
		self.x = owner.x
		self.y = owner.y
		bnum = bnum+1
		self.hsh = string.format("b%d", bnum)
		Boolets[self.hsh] = self
		self.t = self.btype.decay

		local p = love.graphics.newParticleSystem(star, 256)

		p:setEmissionRate (60)
		p:setLifetime (-1)
		p:setSizes (.1)
		p:setParticleLife (.1)
		local c = self.owner.idlecolor
		p:setColors(c[1], c[2], c[3], 255)
		--p:setRadialAcceleration(.1, .5)

		self.trail = p

	end
}

Boolet.types = types

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
	local s = self.btype.speed
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
		me:hurt(self.btype.dmg)
		Boolets[self.hsh] = nil
	end

	if self:isTouching(you) and you ~= self.owner then
		you:hurt(self.btype.dmg)
		Boolets[self.hsh] = nil
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
	return lvec.len2(self.x - dude.x, self.y - dude.y) < (dude.w * dude.w + self.btype.size * self.btype.size)
end

function Boolet:draw()
	if self.btype.draw then self.btype.draw(self) return end
	local rc = self.owner.idlecolor
	--lg.draw(self.trail)
	lg.setColor(rc)
	lg.circle('fill', self.x, self.y, self.btype.size)
end

return Boolet
