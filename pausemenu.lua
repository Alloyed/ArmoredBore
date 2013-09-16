
local Pause = Class {}

function Pause:enter(prev)
	self.prev = prev
	self.oldVol = bgm:getVolume()
	bgm:setVolume(0)
end

local pmsg = "GAME PAUSED\n  Press 'ESC' to unpause\n Enter to go back to Main Menu"
function Pause:draw()
	local prev = self.prev
	if prev.draw then prev:draw() end
	lg.setColor(0, 0, 0, 200)
	lg.rectangle('fill', 0, 0, lg.getWidth(), lg.getHeight())
	lg.setColor(255, 255, 255, 255)
	lg.printf(pmsg, 0, lg.getHeight()/2 - 50, lg.getWidth(), 'center')
end

function Pause:keypressed(key, uni)
	print(key)
	if key == 'f4' and love.keyboard.isDown('lalt') then
		print("YOU'RE HERE FOREVER")
		return
	elseif key == 'escape' then
		bgm:setVolume(self.oldVol)
		Gamestate.switch(self.prev)
	elseif key == 'return' then
		Gamestate.switch(menu)
	end

	control.keyboarddo(key, uni)
end

return Pause
