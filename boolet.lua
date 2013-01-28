Class = require "hump.class"
lvec = require "hump.vector-light"
Consts = require "balance"

local Boolets = {}
local bnum = 0
local Boolet = Class{
	name = "bullet",
	function(self, owner)
		self.owner = owner
		self.x = owner.x
		self.y = owner.y
		bnum = bnum+1
		self.hsh = string.format("b%d", bnum)
		Boolets[self.hsh] = self
		self.t = 2
	end
}

function Boolet.getlen()
	return .15
end

function Boolet.getRate()
	return .05
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
	local s = Consts.bulletspeed
	self.vx = vx*s
	self.vy = vy*s
end

function Boolet:update(dt, me, you)
	self.x = self.x + self.vx
	self.y = self.y + self.vy
	if self:isTouching(me) and me ~= self.owner then
		me:hurt(Consts.bulletdmg)
		Boolets[self.hsh] = nil
	end
	
	if self:isTouching(you) and you ~= self.owner then
		you:hurt(Consts.bulletdmg)
		Boolets[self.hsh] = nil
	end
	
	self.t = self.t - dt
	if self.t <= dt then
		Boolets[self.hsh] = nil
	end
end

function Boolet:isTouching(dude)
	assert(dude.w)
	return lvec.len2(self.x-dude.x,self.y-dude.y) < dude.w * dude.w
end

function Boolet:draw()
	local g = love.graphics
	local rc = self.owner.idlecolor
	g.setColor(rc)
	g.circle('fill', self.x, self.y, 5)
end

return Boolet