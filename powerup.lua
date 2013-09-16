local Class      = require "hump.class"
local lvec       = require "hump.vector-light"
local Ringbuffer = require "hump.ringbuffer"

local Powerup = Class { }
Powerup.respawn    = 10
Powerup.instance   = nil

function Powerup:init(game, x, y)
	self.game = game
	self.x, self.y = x, y
	self.w = balance.Powerupsize
	Powerup.register(self)
end

function Powerup.reset(game, PowerupType)
	Powerup.instance = nil
	PowerupType = PowerupType or Powerup
	local w, h = balance.room[3], balance.room[4]
	Timer.addPeriodic(Powerup.respawn, function()
		PowerupType(game, w/2, h/2)
	end)
end

function Powerup.register(obj)
	Powerup.instance = obj
end

function Powerup.updateall(dt)
	if Powerup.instance then
		Powerup.instance:update(dt)
	end
end

function Powerup.drawall()
	if Powerup.instance then
		Powerup.instance:draw()
	end
end

function Powerup:update(dt)
	local dudes = {self.game.me, self.game.you}
	for _, dude in ipairs(dudes) do
		if self:isTouching(dude) then
			dude:hurt(dude.hp - balance.health - 1)
			Powerup.instance = nil
		end
	end
end

function Powerup:isTouching(dude)
	return lvec.len2(self.x - dude.x, self.y - dude.y) <
	  (dude.w * dude.w + self.w * self.w)
end

function Powerup:draw()
	local rc = colors.ui
	local w  = self.w
	local qw = w / 4
	lg.setColor(rc)
	lg.circle('fill', self.x, self.y, self.w)
	lg.setStencil(function()
		lg.circle('fill', self.x, self.y, self.w - 10)
	end)
	lg.setColor(colors.fg)
	lg.rectangle('fill', self.x-qw, self.y-w, qw*2, w*2)
	lg.rectangle('fill', self.x-w, self.y-qw, w*2, qw*2)
	lg.setStencil()
end

return Powerup
