local Class      = require "hump.class"
local lvec       = require "hump.vector-light"
local Ringbuffer = require "hump.ringbuffer"

local MaxAmmo = Class { }

function MaxAmmo:init(game, x, y)
	self.game = game
	self.x, self.y = x, y
	self.w = balance.powerupsize
	Powerup.register(self)
end

function MaxAmmo:update(dt)
	local dudes = {self.game.me, self.game.you}
	for _, dude in ipairs(dudes) do
		if self:isTouching(dude) then
			dude.ammo = balance.maxammo
			--dude:hurt(dude.hp - balance.health - 1)
			Powerup.instance = nil
		end
	end
end

function MaxAmmo:isTouching(dude)
	return lvec.len2(self.x - dude.x, self.y - dude.y) <
	  (dude.w * dude.w + self.w * self.w)
end

MaxAmmo.img = lg.newImage("g3130.png")
function MaxAmmo:draw()
	local rc = colors.ui
	local w  = self.w
	local qw = w / 4
	lg.setColor(rc)
	lg.setColor(255, 255, 255, 255)
	lg.setBlendMode('additive')
	lg.draw(MaxAmmo.img, self.x, self.y, 0, .25, .25, 320/2, 320/2)
	lg.setBlendMode('alpha')
end

return MaxAmmo
