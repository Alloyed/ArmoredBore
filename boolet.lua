Class = require "hump.class"

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
	self.vx = vx*10
	self.vy = vy*10
end

function Boolet:update(dt)
	self.x = self.x + self.vx
	self.y = self.y + self.vy
	self.t = self.t - dt
	if self.t <= dt then
		Boolets[self.hsh] = nil
	end
end

function Boolet:draw()
	local g = love.graphics
	local rc = self.owner.color
	c = c or {100, 125, 235}
	for i,v in ipairs(rc) do
		c[i] = v * c[i]
	end
	g.setColor(c)
	g.circle('fill', self.x, self.y, 5)
end

return Boolet