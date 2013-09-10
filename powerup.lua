local Class = require "hump.class"
local lvec = require "hump.vector-light"
local Ringbuffer = require "hump.ringbuffer"

local pwrups = {}
local pnum = 0

local Powerup = Class { }

function Powerup:init(game, x, y)
	self.game = game
	self.x, self.y = x, y
	self.w = balance.powerupsize
	pnum = pnum+1
	self.hsh = string.format("p%d", pnum)
	pwrups[self.hsh] = self
	self.t = 999
end

function Powerup.reset(game)
	pwrups = {}
	pnum = 0
	local w, h = balance.room[3], balance.room[4]
	Timer.addPeriodic(10, function()
		Powerup(game, w/2, h/2)
	end)
end

function Powerup.updateall(dt)
	for k, v in pairs(pwrups) do
		v:update(dt)
	end
end

function Powerup.drawall()
	for k, v in pairs(pwrups) do
		v:draw()
	end
end

function Powerup:update(dt)
	local dudes = {self.game.me, self.game.you}
	for _, dude in ipairs(dudes) do
		if self:isTouching(dude) then
			dude:hurt(dude.hp - balance.health - 1)
			pwrups[self.hsh] = nil
		end
	end
	--[[
	self.t = self.t - dt
	if self.t < dt then
		pwrups[self.hsh] = nil
	end
	-]]
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
