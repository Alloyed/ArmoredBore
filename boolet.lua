Class = require "hump.class"
Consts = require "balance"

Boolets = {}
bnum = 0
Boolet = Class{
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

Boolet.boolets = Boolets --FIXME: make this a proper read only iterable

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
	if self:isTouching(me) then
		me.hp = me.hp - Consts.bulletdmg
	end
	
	if self:isTouching(you) then
		you.hp = you.hp - Consts.bulletdmg
	end
	
	self.t = self.t - dt
	if self.t <= dt then
		Boolets[self.hsh] = nil
	end
end

function Boolet:isTouching(dude)
	
end

function Boolet:draw()
	local g = love.graphics
	local rc = self.owner.idlecolor
	g.setColor(rc)
	g.circle('fill', self.x, self.y, 5)
end

return Boolet