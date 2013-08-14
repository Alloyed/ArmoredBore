local moves = require "moves"
local Ring  = require "hump.ringbuffer"

local Dude = Class{
	name = "dude",
	function(self, x, y)
		self.x = x or 100
		self.y = y  or 100
		self.cx = 100
		self.cy = 100
		self.w = 50

		self.joyx = 0
		self.joyy = 0
		self.hp = balance.health
		self.ammo = 0
		self.buf = Ring(34)
		for k, v in pairs(Boolet.types) do
			self.buf:insert(v)
		end
		self.buf:remove()
		self.ammotype = self.buf:next()

		self.move = moves.cooldown(self, balance.initialcountdown)
		self.boolets = {}
		self.bnum = 0
	end
}

function Dude:setmove(newmove, ...)
	if self.move and self.move.dispose then self.move:dispose() end
	self.move = newmove(self, ...)

	return self.move
end

function Dude:pushmove(newmove, ...)
	local oldmove = self.move
	assert(newmove.priority)
	assert(oldmove.priority)
	if (not oldmove) or (newmove.priority > oldmove.priority) then
		return self:setmove(newmove, ...)
	else
		self.rq = {newmove, {...}}
	end
	return nil
end

function Dude:popmove()
	if self.rq then
		self:setmove(self.rq[1], unpack(self.rq[2]))
	else
		self:setmove(moves.idle)
	end
	self.rq = nil
	return self.move
end

function Dude:update(dt)
	self.ammo = math.min(self.ammo + 1, balance.maxammo)
	self.move:update(dt)
end

function Dude:draw()
	self.move:draw()
end

function Dude:hurt(pain)
	self.hp = self.hp - (pain or balance.bulletdmg)
	if self.hp <= 0 and not gamewon then
		gamewon = true
		printstr = string.format("%s WINS", self.other.name)
		self.other.wins = self.other.wins + 1
		self:setmove(moves.cooldown, 999)
		Timer.add(4, function()
			printstr = ""
			justlikemakegame()
		end)
	end
end

return Dude
