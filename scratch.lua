--Powerup.respawn = 2
--bgm:setVolume(0)
--[[

function Powerup:draw()
	local rc = colors.ui
	local w  = self.w
	local qw = w / 4
	lg.setColor(rc)
	lg.setColor(255, 255, 255, 255)
	lg.setBlendMode('additive')
	lg.draw(Powerup.img, self.x, self.y, 0, .25, .25, 320/2, 320/2)
	lg.setBlendMode('alpha')
end
--]]

--lg.setBlendMode('alpha')
