moves = require "moves"
Consts = require "balance"

Dude = Class{
	name = "dude",
	function(self, x, y)
		self.x = x or 100
		self.y = y  or 100
		self.w = 50
		
		self.joyx = 0
		self.joyy = 0
		self.hp = Consts.health
		
		self.move = moves.idle(self)
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

return Dude