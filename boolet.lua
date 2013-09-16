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
end

function Explosion:update(dt)
end

function Explosion:draw()
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
	self.timer = Timer.new()
	self.live = true
	Timer.add(balance.bullet.falloffTime, function()
		self.live = false
	end)

	Timer.add(balance.bullet.decay, function()
		Boolets[self.hsh] = nil
	end)
	self.t = balance.bullet.decay
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
end

function Boolet:reflectAcross(n)
	n= -n:normalized()
	self.x, self.y = self.x - (self.vx*1.3), self.y - (self.vy*1.3)
	local v = Vec(self.vx, self.vy)
	v = v - (2 * (v * n)) * n
	self.vx, self.vy = v:unpack()
end

function Boolet:update(dt, me, you)
	self.x = self.x + self.vx
	self.y = self.y + self.vy
	local players = {me, you}
	for _, player in ipairs(players) do
		if self:isTouching(player) and player ~= self.owner and not self.bumped then
			if not self.live then
				self:reflectAcross(Vec(math.abs(self.x - player.x),
				                       math.abs(self.y - player.y)))
				self.bumped = true
			else
				player:hurt(balance.bullet.dmg)
				Boolets[self.hsh] = Explosion(self)
				local rnd = function() return (math.random() - .5) * 16 end
				Timer.do_for(.032, function()
					me.game.camera:move(rnd(), rnd())
				end)
			end
		end
	end
	self.timer:update(dt)
end

function Boolet:isTouching(dude)
	return lvec.len2(self.x - dude.x, self.y - dude.y) <
	  (dude.w * dude.w + balance.bullet.size * balance.bullet.size)
end

function Boolet:draw()
	local rc
	if self.live then
		rc = self.owner.colors.move
	else
		rc = self.owner.colors.cooldown
	end
	lg.setColor(rc)
	lg.circle('fill', self.x, self.y, balance.bullet.size)
	lg.setLineWidth(2)
	lg.setColor(self.owner.colors.move)
	--lg.circle('line', self.x, self.y, balance.bullet.size)
end

return Boolet
